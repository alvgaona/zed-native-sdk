default:
    just --list

# what CI runs
check: check-manifests build

# check the manifests parse
check-manifests:
    python3 -c "import tomllib,glob; [tomllib.load(open(p,'rb')) for p in ['extension.toml']+glob.glob('languages/*/config.toml')]; print('manifests ok')"

# build the extension wasm
build:
    cargo build --target wasm32-wasip2

# run the queries against a sibling tree-sitter-native checkout
check-queries grammar="../tree-sitter-native":
    #!/usr/bin/env bash
    set -euo pipefail
    here="{{ justfile_directory() }}"
    cd "{{ grammar }}"
    ./node_modules/.bin/tree-sitter parse -q "$here"/test/samples/*.native
    for q in "$here"/languages/native/*.scm; do
      echo "== $(basename "$q")"
      ./node_modules/.bin/tree-sitter query "$q" "$here"/test/samples/*.native >/dev/null
    done

# repoint the manifest at a local grammar checkout
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
