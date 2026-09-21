# love doctor — validate registry integrity.

cmd_doctor() {
    echo "Love.css doctor"
    echo "==============="
    echo ""

    _reg=$(registry_file)
    if [ ! -f "$_reg" ]; then
        echo "FAIL: registry not found: $_reg" >&2
        exit 1
    fi
    echo "OK:   registry found"

    _py=$(require_python)
    _dup=$("$_py" "$LOVE_ROOT/cli/registry_query.py" check-duplicate-tags "$_reg" 2>/dev/null || true)
    if [ -n "$_dup" ]; then
        echo "FAIL: duplicate tags found:" >&2
        echo "$_dup" >&2
        exit 1
    fi
    echo "OK:   no duplicate tags"

    _css=$(resolve_love_css) || {
        echo "WARN: love-css not found — module file check skipped"
        echo ""
        echo "Registry structure is valid."
        return 0
    }
    echo "OK:   love-css found at $_css"

    _missing=0
    for _m in $(registry_modules); do
        _file=$(module_css_file "$_m")
        if [ ! -f "$_css/$_file" ]; then
            echo "FAIL: missing file for module '$_m': $_file" >&2
            _missing=1
        fi
    done
    if [ "$_missing" -eq 1 ]; then
        exit 1
    fi
    echo "OK:   all module files present in love-css"

    echo ""
    echo "Registry is valid."
}
