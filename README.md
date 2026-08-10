# Native SDK for Zed

Language support for [Native SDK](https://native-sdk.dev/) `.native` markup in
[Zed](https://zed.dev): syntax highlighting, and the SDK's own language server.

## Status

Early. What works today, and what is still coming:

| | |
| --- | --- |
| File association, language picker entry, `<!--` comment toggling, autoclose | working |
| Syntax highlighting | needs [`tree-sitter-native`](https://github.com/alvgaona/tree-sitter-native) |
| Diagnostics, hover, completion via `native markup lsp` | planned |

## Install (development)

The extension is not published yet. Clone it, then from Zed's **Extensions** page choose
**Install Dev Extension** (action: `zed::InstallDevExtension`) and select this directory.

## Why a grammar

Zed's syntax highlighting is driven entirely by Tree-sitter — it does not consume LSP semantic
tokens — so colour requires a grammar even though the SDK already ships a language server.

A generic XML or HTML grammar gets the tags right but flattens everything `.native` adds on top
into one opaque string: `{binding}` expressions, `on-press="msg:{payload}"` handlers,
`args="title trend=flat"` template arguments, and literal-only attributes like `language="zig"`.
That layer is most of what is worth highlighting, which is why this ships its own grammar.

## License

MIT
