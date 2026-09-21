# Love.css CLI — shared utilities.
# Sourced by bin/love and all lib/cmd_*.sh modules.

# Resolve the love-css repository location.
# Priority: LOVE_CSS_HOME env var, sibling directory, user cache.
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

# Fail with a clear message when love-css cannot be found.
require_love_css() {
    if ! _css_dir=$(resolve_love_css); then
        cat >&2 <<'EOF'
love: love-css repository not found.

Provide it in one of these ways:
  1. export LOVE_CSS_HOME=/path/to/love-css
  2. Place love-css as a sibling of love-install
  3. Run: love install love-css

EOF
        exit 1
    fi
    echo "$_css_dir"
}

registry_file() {
    echo "$LOVE_ROOT/registry/modules.json"
}

preset_file() {
    echo "$LOVE_ROOT/registry/presets/$1.json"
}

# Check whether Python 3 is available for JSON parsing and HTML scanning.
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

# Print a list of module names from the registry.
registry_modules() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" modules "$(registry_file)"
}

# Print the CSS file path for a module, relative to love-css.
module_css_file() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-file "$(registry_file)" "$1"
}

# Print the dependency list for a module, one per line.
module_deps() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" module-deps "$(registry_file)" "$1"
}

# Print preset module list, one per line.
preset_modules() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-modules "$(preset_file "$1")"
}

# Print preset metadata field.
preset_meta() {
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" preset-meta "$(preset_file "$1")" "$2"
}

# Resolve the project CSS directory. Creates it if missing.
project_css_dir() {
    _dir="$PWD/css"
    mkdir -p "$_dir"
    echo "$_dir"
}

# Check whether a module is already installed in the current project.
module_installed() {
    _file=$(module_css_file "$1" 2>/dev/null) || return 1
    [ -n "$_file" ] && [ -f "$PWD/css/$(basename "$_file")" ]
}

# Print installed module names by scanning the project css directory.
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

# Copy a module CSS file from love-css into the project.
install_module_file() {
    _module="$1"
    _css_dir="$2"
    _src=$(module_css_file "$_module") || {
        echo "love: unknown module '$_module'" >&2
        return 1
    }
    _love_css=$(require_love_css)
    _src_path="$_love_css/$_src"
    if [ ! -f "$_src_path" ]; then
        echo "love: source file not found: $_src_path" >&2
        return 1
    fi
    cp "$_src_path" "$_css_dir/$(basename "$_src")"
}

# Recursively install a module and its dependencies.
install_module_with_deps() {
    _module="$1"
    _css_dir="$2"
    _visited="$3"

    case " $_visited " in
        *" $_module "*) return 0 ;;
    esac
    _visited="$_visited $_module"

    for _dep in $(module_deps "$_module"); do
        install_module_with_deps "$_dep" "$_css_dir" "$_visited"
    done

    install_module_file "$_module" "$_css_dir"
}

# Write or update love.json in the project root.
write_love_json() {
    _preset="$1"
    _modules="$2"
    _py=$(require_python)
    "$_py" "$LOVE_ROOT/cli/registry_query.py" write-love-json \
        "$PWD/love.json" "$_preset" "$_modules" "$(registry_file)"
}
