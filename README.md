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

For the language server, the `native` CLI must be on your `PATH`
(`bun add -g @native-sdk/cli`). The contract-aware half of its checking — bindings and message
tags verified against your app's real `Model` and `Msg` — additionally needs a fresh
`zig-out/model-contract.zon`, which `native test` writes.

## Layout

| Path | What |
| --- | --- |
| `grammar/` | the Tree-sitter grammar; will be split into its own repo |
| `languages/native/` | language config and the `.scm` queries |
| `src/native_sdk.rs` | the extension binary, which resolves the language server |

## Development

`just check` runs everything CI does: manifest validation, a parser regeneration that fails on a
stale commit, the corpus tests, and the extension build.

The grammar's fixtures are mined from the SDK's own markup tests — its Zig source ships inside the
npm package, and `ui_markup*tests.zig` carries several hundred snippets. `just fixtures` extracts
them and keeps only what `native markup check` accepts, so the corpus tracks whichever SDK version
is installed rather than being frozen at authoring time.

Two things worth knowing before changing the grammar:

- Zed compiles `grammar/src/parser.c` **directly** and never runs `tree-sitter generate`, so the
  generated parser is committed and CI fails if it goes stale.
- The manifest pins the grammar by commit, so a grammar change is always two commits: the change,
  then the `rev` bump that points at it.

## Why a grammar at all

Zed's highlighting is driven entirely by Tree-sitter — it does not consume LSP semantic tokens —
so colour requires a grammar even though the SDK already ships a language server.

The element and attribute vocabulary is deliberately **not** encoded in the grammar. It is a
closed set at any moment but it grows with every SDK release, and a grammar that enumerates it
goes stale silently. Only the shapes the language actually parses differently get rules; deciding
whether `<colunm>` is a real element belongs to `native markup check`, which knows.

## License

MIT
