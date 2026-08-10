default:
    just --list

# everything CI runs
check: check-manifests build

# validate that the manifest and every language config parse
check-manifests:
    python3 -c "import tomllib,glob; [tomllib.load(open(p,'rb')) for p in ['extension.toml']+glob.glob('languages/*/config.toml')]; print('manifests ok')"

# compile the language-server half of the extension
build:
    cargo build --target wasm32-wasip2

# run every query file against real markup, using a sibling tree-sitter-native checkout
check-queries grammar="../tree-sitter-native":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ grammar }}"
    python3 scripts/extract-corpus.py
    for q in {{ justfile_directory() }}/languages/native/*.scm; do
      echo "== $(basename "$q")"
      ./node_modules/.bin/tree-sitter query "$q" test/fixtures/*.native >/dev/null
    done

# point the manifest at a local grammar checkout while iterating on the grammar
use-local-grammar grammar="../tree-sitter-native":
    #!/usr/bin/env bash
    set -euo pipefail
    dir="$(cd "{{ grammar }}" && pwd)"
    rev="$(git -C "$dir" rev-parse HEAD)"
    python3 - "$dir" "$rev" <<'PY'
    import pathlib, re, sys
    d, rev = sys.argv[1], sys.argv[2]
    p = pathlib.Path("extension.toml")
    t = p.read_text()
    t = re.sub(r'(?m)^repository = "https://github\.com/alvgaona/tree-sitter-native"$', f'repository = "file://{d}"', t)
    t = re.sub(r'(?m)^rev = ".*"$', f'rev = "{rev}"', t)
    p.write_text(t)
    print(f"grammar -> file://{d} @ {rev[:8]}")
    PY
