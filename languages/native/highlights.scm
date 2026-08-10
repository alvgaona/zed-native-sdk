; Markup

(structure_tag) @keyword
(element_name) @tag

[
  "<"
  "</"
  "/>"
  ">"
] @punctuation.bracket

"=" @punctuation.delimiter

(comment) @comment

; Attributes

(attribute_name) @attribute
(args_name) @keyword
(event_name) @function
(message_tag) @constructor

(argument_name) @variable.parameter
(argument_default) @constant

(attribute_text) @string

; Bindings

(interpolation
  [
    "{"
    "}"
  ] @punctuation.special)

; The 17 builtins get a distinct colour where the theme has one, and fall back to plain @function
; where it does not. Unknown names stay @function rather than becoming an error the grammar cannot
; actually prove — the SDK's checker owns that judgement.
((call
  function: (identifier) @function @function.builtin)
  (#any-of? @function.builtin
    "fixed" "thousands" "percent" "date" "time" "datetime" "upper" "lower" "trim"
    "min" "max" "abs" "round" "floor" "ceil" "plural" "pad"))

(call
  function: (identifier) @function)

(path
  (identifier) @variable)

(binary_expression
  operator: _ @operator)

[
  "not"
  "and"
  "or"
] @operator

(string) @string
(number) @number
(boolean) @boolean
