# love add <module>

cmd_add() {
    if [ $# -eq 0 ]; then
        echo "love add: missing module name" >&2
        exit 1
    fi

    _module="$1"
    _css_dir=$(project_css_dir)

    if module_installed "$_module"; then
        echo "love: module '$_module' is already installed"
        return 0
    fi

    install_module_with_deps "$_module" "$_css_dir" "" || exit 1

    _current=$(installed_modules | tr '\n' ' ')
    _preset=""
    if [ -f "$PWD/love.json" ]; then
        _preset=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" preset-name 2>/dev/null || echo "")
    fi
    write_love_json "$_preset" "$_current"

    echo "love: module '$_module' installed"
}
