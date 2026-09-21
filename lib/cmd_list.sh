# love list — list all available modules and presets.

cmd_list() {
    echo "Available modules:"
    echo "=================="
    for _m in $(registry_modules); do
        _desc=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" module-desc "$(registry_file)" "$_m")
        printf "  %-16s %s\n" "$_m" "$_desc"
    done

    echo ""
    echo "Available presets:"
    echo "=================="
    for _f in "$LOVE_ROOT"/registry/presets/*.json; do
        _p=$(basename "$_f" .json)
        _desc=$(preset_meta "$_p" "description")
        printf "  %-16s %s\n" "$_p" "$_desc"
    done
}

# love module list — show modules with + (installed) / - (not installed).

cmd_module_list() {
    echo "Module status for: $PWD"
    echo "============================="
    for _m in $(registry_modules); do
        if module_installed "$_m"; then
            echo "+ love.$_m"
        else
            echo "- love.$_m"
        fi
    done
}
