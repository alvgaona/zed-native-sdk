default:
    just --list

# validate that the manifest and every language config parse
check:
    python3 -c "import tomllib,glob,sys; [tomllib.load(open(p,'rb')) for p in ['extension.toml']+glob.glob('languages/*/config.toml')]; print('manifests ok')"

# parse every .native file in a project with the SDK's own checker (sanity for the corpus)
check-markup dir:
    native markup check {{ dir }}/src/*.native
