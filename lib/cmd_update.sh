# love update — update installed modules to the latest version from love-css.

cmd_update() {
    if [ ! -d "$PWD/css" ]; then
        echo "love: no css/ directory in this project" >&2
        exit 1
    fi

    _css_dir=$(resolve_love_css) || {
        echo "love: love-css not found. Run 'love install love-css' or set LOVE_CSS_HOME." >&2
        exit 1
    }

    _updated=0
    for _m in $(installed_modules); do
        _file=$(module_css_file "$_m" 2>/dev/null) || continue
        _src="$_css_dir/$_file"
        _dst="$PWD/css/$(basename "$_file")"
        if [ -f "$_src" ] && [ -f "$_dst" ]; then
            if ! cmp -s "$_src" "$_dst"; then
                cp "$_src" "$_dst"
                echo "love: updated love.$_m.css"
                _updated=$((_updated + 1))
            fi
        fi
    done

    if [ "$_updated" -eq 0 ]; then
        echo "love: all modules are up to date"
    else
        echo "love: $_updated module(s) updated"
    fi
}
