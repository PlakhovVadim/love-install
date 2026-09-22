# Love.css CLI — shared utilities.

resolve_love_css() {
    if [ -n "${LOVE_CSS_HOME:-}" ] && [ -d "$LOVE_CSS_HOME/css" ]; then
        echo "$LOVE_CSS_HOME"
        return 0
    fi
    _sibling="$LOVE_ROOT/../love-css"
    if [ -d "$_sibling/css" ]; then
        (cd "$_sibling" && pwd)
        return 0
    fi
    _cache="${XDG_CACHE_HOME:-$HOME/.cache}/love-css"
    if [ -d "$_cache/css" ]; then
        echo "$_cache"
        return 0
    fi
    return 1
}

registry_file() {
    echo "$LOVE_ROOT/registry/modules.json"
}

preset_file() {
    echo "$LOVE_ROOT/registry/presets/$1.json"
}

require_python() {
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    else
        echo "love: Python 3 is required. Install it and try again." >&2
        exit 1
    fi
}

require_curl() {
    if command -v curl >/dev/null 2>&1; then
        echo "curl"
        return 0
    fi
    echo "love: curl is required to download modules from GitHub." >&2
    echo "love: install curl, or clone love-css locally and set LOVE_CSS_HOME." >&2
    exit 1
}

registry_repository() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" repository "$(registry_file)"
}

registry_modules() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" modules "$(registry_file)"
}

module_css_file() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-file "$(registry_file)" "$1"
}

module_deps() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-deps "$(registry_file)" "$1"
}

preset_modules() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-modules "$(preset_file "$1")"
}

preset_meta() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-meta "$(preset_file "$1")" "$2"
}

project_css_dir() {
    _dir="$PWD/css"
    mkdir -p "$_dir"
    echo "$_dir"
}

module_installed() {
    _file=$(module_css_file "$1" 2>/dev/null) || return 1
    [ -n "$_file" ] && [ -f "$PWD/css/$(basename "$_file")" ]
}

installed_modules() {
    if [ ! -d "$PWD/css" ]; then
        return 0
    fi
    for f in "$PWD"/css/love.*.css; do
        [ -f "$f" ] || continue
        _base=$(basename "$f")
        _name=${_base#love.}
        _name=${_name%.css}
        case "$_name" in
            overrides) continue ;;
        esac
        echo "$_name"
    done
}

install_module_file() {
    _module="$1"
    _css_dir="$2"
    _file=$(module_css_file "$_module") || {
        echo "love: unknown module '$_module'" >&2
        return 1
    }
    if [ -z "$_file" ]; then
        echo "love: registry has no file for module '$_module'" >&2
        return 1
    fi
    _base=$(basename "$_file")
    _dest="$_css_dir/$_base"

    if [ -f "$_dest" ]; then
        return 0
    fi

    if _love_css=$(resolve_love_css); then
        _src="$_love_css/$_file"
        if [ ! -f "$_src" ]; then
            echo "love: local file not found: $_src" >&2
            return 1
        fi
        cp "$_src" "$_dest"
        echo "  + $_base (local)"
        return 0
    fi

    _curl=$(require_curl)
    _repo=$(registry_repository)
    _url="$_repo/$_file"
    if ! "$_curl" -fsSL "$_url" -o "$_dest"; then
        echo "love: failed to download $_url" >&2
        rm -f "$_dest"
        return 1
    fi
    echo "  + $_base (remote)"
}

install_module_with_deps() {
    _module="$1"
    _css_dir="$2"
    _visited="$3"

    case " $_visited " in
        *" $_module "*) return 0 ;;
    esac

    for _dep in $(module_deps "$_module"); do
        install_module_with_deps "$_dep" "$_css_dir" "$_visited $_module" || return 1
    done

    install_module_file "$_module" "$_css_dir" || return 1
}

write_love_json() {
    _preset="$1"
    _modules="$2"
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" write-love-json \
        "$PWD/love.json" "$_preset" "$_modules" "$(registry_file)"
}
