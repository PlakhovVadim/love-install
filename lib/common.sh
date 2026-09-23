# Love.css CLI — shared utilities.

resolve_love_css() {
    local _sibling _cache
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
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" repository "$(registry_file)"
}

registry_modules() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" modules "$(registry_file)"
}

module_css_file() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-file "$(registry_file)" "$1"
}

module_files() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-files "$(registry_file)" "$1"
}

module_deps() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-deps "$(registry_file)" "$1"
}

preset_modules() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-modules "$(preset_file "$1")"
}

preset_meta() {
    local _py
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-meta "$(preset_file "$1")" "$2"
}

project_css_dir() {
    local _dir
    _dir="$PWD/css"
    mkdir -p "$_dir"
    echo "$_dir"
}

module_installed() {
    local _file
    _file=$(module_css_file "$1" 2>/dev/null) || return 1
    [ -n "$_file" ] && [ -f "$PWD/css/$(basename "$_file")" ]
}

installed_modules() {
    local f _base _name
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

install_module_files() {
    local _module _css_dir _file _base _dest _love_css _src
    local _curl _repo _url _attempt _max_attempts
    _module="$1"
    _css_dir="$2"

    # Get all files for this module
    _files=$(module_files "$_module") || {
        echo "love: unknown module '$_module'" >&2
        return 1
    }

    if [ -z "$_files" ]; then
        echo "love: registry has no files for module '$_module'" >&2
        return 1
    fi

    _curl=$(require_curl)
    _repo=$(registry_repository)

    # If local love-css is available, prefer it
    if _love_css=$(resolve_love_css); then
        for _file in $_files; do
            _base=$(basename "$_file")
            _dest="$_css_dir/$_base"
            _src="$_love_css/$_file"

            # For assets, preserve directory structure
            case "$_file" in
                assets/*)
                    _dest="$PWD/$_file"
                    mkdir -p "$(dirname "$_dest")"
                    ;;
                *)
                    _dest="$_css_dir/$_base"
                    ;;
            esac

            if [ -f "$_dest" ]; then
                continue
            fi

            if [ ! -f "$_src" ]; then
                echo "love: local file not found: $_src" >&2
                return 1
            fi
            cp "$_src" "$_dest"
            echo "  + $_file (local)"
        done
        return 0
    fi

    # Remote download
    for _file in $_files; do
        _base=$(basename "$_file")

        case "$_file" in
            assets/*)
                _dest="$PWD/$_file"
                mkdir -p "$(dirname "$_dest")"
                ;;
            *)
                _dest="$_css_dir/$_base"
                ;;
        esac

        if [ -f "$_dest" ]; then
            continue
        fi

        _url="$_repo/$_file"
        _max_attempts=3
        _attempt=1

        while [ "$_attempt" -le "$_max_attempts" ]; do
            if "$_curl" -fsSL "$_url" -o "$_dest"; then
                echo "  + $_file (remote)"
                break
            fi
            rm -f "$_dest"
            if [ "$_attempt" -lt "$_max_attempts" ]; then
                echo "love: download attempt $_attempt of $_max_attempts failed for $_file, retrying in 2s" >&2
                sleep 2
            fi
            _attempt=$((_attempt + 1))
        done

        if [ "$_attempt" -gt "$_max_attempts" ]; then
            echo "love: failed to download $_url after $_max_attempts attempts" >&2
            return 1
        fi
    done
}

install_module_with_deps() {
    local _module _css_dir _visited _dep
    _module="$1"
    _css_dir="$2"
    _visited="$3"

    case " $_visited " in
        *" $_module "*) return 0 ;;
    esac

    for _dep in $(module_deps "$_module"); do
        install_module_with_deps "$_dep" "$_css_dir" "$_visited $_module" || return 1
    done

    install_module_files "$_module" "$_css_dir" || return 1
}

write_love_json() {
    local _preset _modules _py
    _preset="$1"
    _modules="$2"
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" write-love-json \
        "$PWD/love.json" "$_preset" "$_modules" "$(registry_file)"
}
