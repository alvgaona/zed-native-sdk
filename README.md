# Native SDK for Zed

<p align="center">
  <a href="https://github.com/alvgaona/zed-native-sdk/actions/workflows/check.yml"><img alt="CI status" src="https://img.shields.io/github/actions/workflow/status/alvgaona/zed-native-sdk/check.yml?branch=main&logo=githubactions&label=check&style=for-the-badge&logoColor=white&labelColor=000000&color=1c1c1c"></a>
  <a href="https://zed.dev"><img alt="Zed extension" src="https://img.shields.io/badge/zed-extension-1c1c1c?style=for-the-badge&logo=zedindustries&logoColor=white&labelColor=000000"></a>
  <a href="https://github.com/alvgaona/zed-native-sdk/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/tag/alvgaona/zed-native-sdk?logo=github&label=release&style=for-the-badge&logoColor=white&labelColor=000000&color=1c1c1c"></a>
  <a href="https://github.com/alvgaona/zed-native-sdk/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/alvgaona/zed-native-sdk?logo=opensourceinitiative&label=license&style=for-the-badge&logoColor=white&labelColor=000000&color=1c1c1c"></a>
</p>

Language support for [Native SDK](https://native-sdk.dev/) `.native` markup in
[Zed](https://zed.dev). Highlighting comes from a Tree-sitter grammar; diagnostics, hover and
completion come from the SDK's own language server.

## What you get

Highlighting covers the parts a generic XML grammar would leave flat: `{binding}` expressions,
`on-press="msg:{payload}"` handlers, `args="title trend=flat"` template arguments and literal
values. Templates show up in the outline, and bracket matching, auto-indent, `<!--` comment
toggling and tag wrapping all work.

The language server is the SDK's `native markup lsp`. Nothing gets downloaded, so the binary that
checks your markup is the one your project builds with.

## Install

Not published yet. Clone the repo, open Zed's Extensions page, choose **Install Dev Extension**
and pick the directory. Zed clones the grammar and builds both halves itself, installing the
`wasm32-wasip2` Rust target through `rustup` if you don't have it.

The language server needs `native` on your `PATH` (`bun add -g @native-sdk/cli`). A project-local
`node_modules/.bin/native` is used first if there is one. Without either, you still get
highlighting.

## What the language server actually does

From driving `native markup lsp` 0.1.0 over stdio:

- Diagnostics update on every keystroke and clear when you fix them.
- Only one diagnostic per file. Two unrelated errors give you the first one, then the next after
  you fix it.
- Completion offers 77 elements after `<` and 62 attributes inside a tag, scoped to the element.
- Attribute values get no completions, even though a wrong value produces a diagnostic listing the
  valid ones.
- Hover returns real documentation for elements and attributes.
- Bindings and message tags are **not** checked against your `Model` and `Msg`. Run
  `native markup check` in the app directory for that, with `zig-out/model-contract.zon` fresh
  from `native test`. Given the same file in the same directory, the CLI reports
  `binding does not name a model field` and the server reports nothing.

## Layout

- `languages/native/` — language config and the `.scm` queries
- `src/native_sdk.rs` — the extension binary, which resolves the language server
- `test/samples/` — markup covering every shape the queries capture

The grammar is in [tree-sitter-native](https://github.com/alvgaona/tree-sitter-native), pinned here
by commit.

## Development

`just check` validates the manifests and builds the extension. `just check-queries` runs the `.scm`
files against a sibling `tree-sitter-native` checkout, which is what CI does at the pinned revision.

When changing grammar and queries together, `just use-local-grammar` repoints the manifest at your
local checkout and its current HEAD. Rebuild the dev extension to pick it up, and put the line back
before committing.

Highlighting needs the grammar even though the server exists, because Zed builds it from
Tree-sitter queries and ignores LSP semantic tokens.

## Releasing

Two repos, and this one pins the other, so the order matters.

1. Tag the grammar first. In `tree-sitter-native`, bump `version` in `package.json` and
   `tree-sitter.json`, commit, `git tag -a vX.Y.Z`, push the tag.
2. Point `rev` in `extension.toml` at that commit's SHA. Zed clones by revision, so a tag name
   would resolve but the SHA is what belongs in the manifest.
3. Bump `version` in `extension.toml` and `Cargo.toml` together. `just check-versions` enforces
   that they match, and the tag names both.
4. Tag and push here. `release.yml` runs
   [zed-extension-action](https://github.com/huacnlee/zed-extension-action), which pushes a branch
   to the `alvgaona/zed-extensions` fork and opens the PR against `zed-industries/extensions`.

The action needs a `COMMITTER_TOKEN` repository secret with `public_repo` scope. Without it the
run fails at the first API call with `401 Bad credentials`, and the tag is still published, so
re-tagging is not needed — just add the secret and re-run the workflow.

## License

MIT
