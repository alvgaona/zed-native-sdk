/// <reference types="tree-sitter-cli/dsl" />

// The vocabulary of elements and attributes is deliberately NOT encoded here. It is a closed set
// today but it grows with every SDK release, and a grammar that lists it goes stale silently.
// Only the shapes the language treats differently get their own rules: structure tags, `on-*`
// handlers, and `args` lists. Everything else parses generically and is coloured by queries.

const STRUCTURE_TAGS = ["import", "template", "use", "slot", "for", "if", "else"];

// Loosest to tightest.
const PREC = {
  or: 1,
  and: 2,
  compare: 3,
  concat: 4,
  add: 5,
  multiply: 6,
  unary: 7,
};

module.exports = grammar({
  name: "native",

  extras: ($) => [/\s+/, $.comment],

  rules: {
    document: ($) => repeat($.element),

    comment: (_) => token(seq("<!--", /[^-]*(-[^-]+)*-*/, "-->")),

    element: ($) =>
      choice(
        $.self_closing_tag,
        seq($.start_tag, repeat(choice($.element, $.text)), $.end_tag),
      ),

    start_tag: ($) => seq("<", $._tag_name, repeat($.attribute), ">"),
    self_closing_tag: ($) => seq("<", $._tag_name, repeat($.attribute), "/>"),
    end_tag: ($) => seq("</", $._tag_name, ">"),

    _tag_name: ($) => choice($.structure_tag, $.element_name),
    structure_tag: (_) => choice(...STRUCTURE_TAGS),
    element_name: (_) => /[a-zA-Z_][a-zA-Z0-9_-]*/,

    // Text runs carry prose and interpolations side by side: `{percent(done / total)} complete`.
    // prec.right, not prec.left: left association reduces at the first boundary and splits
    // `{a} prose {b}` into three sibling text nodes instead of one run.
    text: ($) => prec.right(repeat1(choice($.interpolation, $._text_chunk))),
    _text_chunk: (_) => token(prec(-1, /[^<{]+/)),

    attribute: ($) =>
      choice($.event_attribute, $.args_attribute, $.plain_attribute),

    // `on-press="copy_code_block:{b.code_index}"` — a Msg variant, optionally with a payload.
    event_attribute: ($) =>
      seq(
        field("name", $.event_name),
        "=",
        '"',
        optional(seq($.message_tag, optional(seq(":", $._attribute_content)))),
        '"',
      ),
    event_name: (_) => token(prec(1, /on-[a-zA-Z][a-zA-Z0-9-]*/)),
    message_tag: (_) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // `args="title trend=flat"`, and `args="gap=0 grow=0 label="` — defaults may be empty.
    args_attribute: ($) =>
      seq(field("name", $.args_name), "=", '"', repeat($.argument), '"'),
    args_name: (_) => token(prec(1, "args")),
    argument: ($) =>
      seq(
        field("name", $.argument_name),
        optional(seq("=", optional(field("default", $.argument_default)))),
      ),
    argument_name: (_) => /[a-zA-Z_][a-zA-Z0-9_]*/,
    // Wins over `argument_name` so `trend=flat` is one argument with a default, not two arguments.
    argument_default: (_) => token(prec(1, /[^\s"=]+/)),

    // Bare attributes are real: `disabled`, `autofocus`, `line-numbers`.
    plain_attribute: ($) =>
      seq(
        field("name", $.attribute_name),
        optional(seq("=", '"', optional($._attribute_content), '"')),
      ),
    // Underscores are real: `<use>` passes template arguments as attributes, and those names come
    // from the app, not the SDK — `image_map="{markdownImages}"` in noto.
    attribute_name: (_) => /[a-zA-Z_][a-zA-Z0-9_-]*/,

    _attribute_content: ($) =>
      repeat1(choice($.interpolation, $.number, $.boolean, $.attribute_text)),
    attribute_text: (_) => token(prec(-1, /[^"{}]+/)),

    interpolation: ($) => seq("{", $._expression, "}"),

    _expression: ($) =>
      choice(
        $.unary_expression,
        $.binary_expression,
        $.parenthesized_expression,
        $.call,
        $.path,
        $.string,
        $.number,
        $.boolean,
      ),

    parenthesized_expression: ($) => seq("(", $._expression, ")"),

    unary_expression: ($) =>
      prec.right(PREC.unary, seq(choice("not", "-"), $._expression)),

    binary_expression: ($) => {
      const table = [
        [PREC.or, "or"],
        [PREC.and, "and"],
        [PREC.compare, choice("==", "!=", "<=", ">=", "<", ">")],
        [PREC.concat, "++"],
        [PREC.add, choice("+", "-")],
        [PREC.multiply, choice("*", "/")],
      ];
      return choice(
        ...table.map(([precedence, operator]) =>
          prec.left(
            precedence,
            seq(
              field("left", $._expression),
              field("operator", operator),
              field("right", $._expression),
            ),
          ),
        ),
      );
    },

    // The 17 builtins are not enumerated for the same reason the element list is not: queries can
    // check the name with #any-of? and stay wrong-but-harmless if the set grows.
    call: ($) =>
      seq(
        field("function", $.identifier),
        "(",
        optional(seq($._expression, repeat(seq(",", $._expression)))),
        ")",
      ),

    path: ($) => seq($.identifier, repeat(seq(".", $.identifier))),
    identifier: (_) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    string: (_) => seq("'", /[^']*/, "'"),
    number: (_) => /-?\d+(\.\d+)?/,
    boolean: (_) => choice("true", "false"),
  },
});
