# love status — show installed modules, active preset, love-css version.

cmd_status() {
    echo "Love.css status"
    echo "==============="

    _css_dir="$PWD/css"
    if [ ! -d "$_css_dir" ]; then
        echo "css/:            not found"
        echo "modules:         none"
        echo ""
        echo "Run 'love install <preset>' or 'love install custom' to begin."
        return 0
    fi

    _count=$(installed_modules | wc -l | tr -d ' ')
    echo "css/:            $_css_dir"
    echo "modules:         $_count installed"

    if [ "$_count" -gt 0 ]; then
        echo ""
        echo "Installed modules:"
        for _m in $(installed_modules); do
            _file=$(module_css_file "$_m" 2>/dev/null)
            _ver=""
            if [ -n "$_file" ] && [ -f "$_css_dir/$(basename "$_file")" ]; then
                _ver=$(head -1 "$_css_dir/$(basename "$_file")" | sed -n 's/.*Love\.css v\([0-9.]*\).*/\1/p')
            fi
            if [ -n "$_ver" ]; then
                echo "  + love.$_m.css  (v$_ver)"
            else
                echo "  + love.$_m.css"
            fi
        done
    fi

    echo ""
    if [ -f "$PWD/love.json" ]; then
        _preset=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" preset-name)
        echo "preset:          $_preset"
        _info=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" info)
        [ -n "$_info" ] && echo "info:            $_info"
    else
        echo "preset:          none (love.json not found)"
    fi
}

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

    _dup=$("$(require_python)" "$LOVE_ROOT/cli/registry_query.py" check-duplicate-tags "$_reg")
    if [ -n "$_dup" ]; then
        echo "FAIL: duplicate tags found:" >&2
        echo "$_dup" >&2
        exit 1
    fi
    echo "OK:   no duplicate tags"

    _css=$(resolve_love_css) || {
        echo "WARN: love-css not found — cannot verify module files"
        return 0
    }
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
