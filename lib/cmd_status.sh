# love status — show installed modules, active preset, love-css version.

cmd_status() {
    echo "Love.css status"
    echo "==============="
    echo ""

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
            _file=$(module_css_file "$_m" 2>/dev/null || echo "")
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
        _py=$(require_python)
        _preset=$("$_py" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" preset-name 2>/dev/null || echo "")
        if [ -n "$_preset" ]; then
            echo "preset:          $_preset"
        else
            echo "preset:          (not set)"
        fi
        _info=$("$_py" "$LOVE_ROOT/cli/registry_query.py" love-json-field "$PWD/love.json" info 2>/dev/null || echo "")
        if [ -n "$_info" ]; then
            echo "info:            $_info"
        fi
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

    _py=$(require_python)
    _dup=$("$_py" "$LOVE_ROOT/cli/registry_query.py" check-duplicate-tags "$_reg" 2>/dev/null || true)
    if [ -n "$_dup" ]; then
        echo "FAIL: duplicate tags found:" >&2
        echo "$_dup" >&2
        exit 1
    fi
    echo "OK:   no duplicate tags"

    if _css=$(resolve_love_css); then
        echo "OK:   love-css found at $_css"
        _missing=0
        for _m in $(registry_modules); do
            _file=$(module_css_file "$_m")
            if [ ! -f "$_css/$_file" ]; then
                echo "WARN: missing file for module '$_m': $_file" >&2
                _missing=1
            fi
        done
        if [ "$_missing" -eq 0 ]; then
            echo "OK:   all module files present in love-css"
        fi
    else
        echo "WARN: love-css not found — module file check skipped"
    fi

    echo ""
    echo "Registry is valid."
}
