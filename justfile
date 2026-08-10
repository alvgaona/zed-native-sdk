default:
    just --list

# everything CI runs
check: check-manifests check-grammar build

# validate that the manifest and every language config parse
check-manifests:
    python3 -c "import tomllib,glob; [tomllib.load(open(p,'rb')) for p in ['extension.toml']+glob.glob('languages/*/config.toml')]; print('manifests ok')"

# regenerate the parser, fail on a stale commit, run the corpus tests
check-grammar:
    cd grammar && bun install --frozen-lockfile
    cd grammar && ./node_modules/.bin/tree-sitter generate
    git diff --exit-code grammar/src
    cd grammar && ./node_modules/.bin/tree-sitter test

# compile the language-server half of the extension
build:
    cargo build --target wasm32-wasip2

# regenerate test/fixtures from the SDK's own markup tests (gitignored, per-SDK-version)
fixtures:
    python3 grammar/scripts/extract-corpus.py

# parse every fixture and report anything the grammar cannot handle
parse-fixtures: fixtures
    cd grammar && ./node_modules/.bin/tree-sitter parse -q test/fixtures/*.native

# run every query file against a real view (validates the .scm files)
check-queries:
    #!/usr/bin/env bash
    set -euo pipefail
    for q in languages/native/*.scm; do
      echo "== $q"
      (cd grammar && ./node_modules/.bin/tree-sitter query "../$q" test/fixtures/*.native >/dev/null)
    done
