# Native SDK for Zed

Language support for [Native SDK](https://native-sdk.dev/) `.native` markup in
[Zed](https://zed.dev): a Tree-sitter grammar for highlighting, and the SDK's own language server
for diagnostics, hover and completion.

## What it does

- **Syntax highlighting** over the whole language, including the layer a generic XML grammar
  flattens into one string: `{binding}` expressions, `on-press="msg:{payload}"` handlers,
  `args="title trend=flat"` template arguments, and literal attribute values.
- **Outline** of the templates in a view, plus bracket matching, auto-indent, `<!--` comment
  toggling and tag wrapping.
- **Language server**, by running the SDK's own `native markup lsp`. Nothing is downloaded — the
  same `native` your project builds with is the one that checks the markup, so the two can never
  drift apart.

## Install (development)

Not published yet. Clone the repo, then from Zed's **Extensions** page choose **Install Dev
Extension** (action: `zed::InstallDevExtension`) and select the directory. Zed builds the grammar
and the extension itself; it installs the `wasm32-wasip2` Rust target through `rustup` if needed.

For the language server, the `native` CLI must be on your `PATH` (`bun add -g @native-sdk/cli`),
or installed in the project as `node_modules/.bin/native`, which takes precedence.

### What the server does and does not do

Measured against `native markup lsp` 0.1.0, by driving it over stdio:

| | |
| --- | --- |
| Diagnostics, live on every keystroke | yes — grammar, vocabulary, structure, colour tokens |
| More than one error at a time | **no** — one diagnostic per document, fail-fast |
| Element completion (77) and attribute completion (62), element-aware | yes |
| Attribute *value* completion | **no**, even where a wrong value's diagnostic lists the valid ones |
| Hover documentation | yes, real prose per element and attribute |
| Bindings and message tags checked against the app's `Model`/`Msg` | **no** — see below |

That last row is the notable one. `native markup check` catches `binding does not name a model
field` when run in an app directory with a fresh `zig-out/model-contract.zon`; the language server,
given the same file in the same directory, reports nothing. The contract-aware phase does not
appear to be wired into the LSP path, so those errors still only surface from the CLI.

## Layout

| Path | What |
| --- | --- |
| `languages/native/` | language config and the `.scm` queries |
| `src/native_sdk.rs` | the extension binary, which resolves the language server |
| `test/samples/` | markup exercising every shape the queries capture |

The grammar lives in [tree-sitter-native](https://github.com/alvgaona/tree-sitter-native) and is
pinned here by commit.

## Development

`just check` validates the manifests and builds the extension. `just check-queries` runs every
`.scm` file against a sibling `tree-sitter-native` checkout, which is what CI does at the pinned
revision.

To iterate on the grammar and the queries together, `just use-local-grammar` rewrites the manifest
to point at your local checkout by `file://` URL and current HEAD; rebuild the dev extension to
pick it up. Revert that line before committing.

## Why a grammar at all

Zed's highlighting is driven entirely by Tree-sitter — it does not consume LSP semantic tokens —
so colour requires a grammar even though the SDK already ships a language server.

The element and attribute vocabulary is deliberately **not** encoded in the grammar. It is a
closed set at any moment but it grows with every SDK release, and a grammar that enumerates it
goes stale silently. Only the shapes the language actually parses differently get rules; deciding
whether `<colunm>` is a real element belongs to `native markup check`, which knows.

## License

MIT
