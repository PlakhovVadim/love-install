# love check — scan HTML files and report required modules.

cmd_check() {
    _dir="${1:-$PWD}"
    _scanner="$LOVE_ROOT/cli/scan.py"

    if [ ! -f "$_scanner" ]; then
        echo "love: scanner not found at $_scanner" >&2
        exit 1
    fi

    "$(require_python)" "$_scanner" \
        --dir "$_dir" \
        --registry "$(registry_file)" \
        --css-dir "$_dir/css"
}
