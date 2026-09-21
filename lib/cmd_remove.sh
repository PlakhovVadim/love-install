# love remove <module>

cmd_remove() {
    if [ $# -eq 0 ]; then
        echo "love remove: missing module name" >&2
        exit 1
    fi

    _module="$1"
    _file=$(module_css_file "$_module") || {
        echo "love: unknown module '$_module'" >&2
        exit 1
    }
    _base=$(basename "$_file")

    if [ ! -f "$PWD/css/$_base" ]; then
        echo "love: module '$_module' is not installed" >&2
        exit 1
    fi

    for _installed in $(installed_modules); do
        for _dep in $(module_deps "$_installed"); do
            if [ "$_dep" = "$_module" ]; then
                echo "love: cannot remove '$_module': '$_installed' depends on it" >&2
                echo "love: remove '$_installed' first or use --force" >&2
                exit 1
            fi
        done
    done

    rm -f "$PWD/css/$_base"
    echo "love: module '$_module' removed"

    _current=$(installed_modules | tr '\n' ' ')
    _preset=""
    if [ -f "$PWD/love.json" ]; then
        _preset=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" preset-name 2>/dev/null || echo "")
    fi
    write_love_json "$_preset" "$_current"
}
