# love install <preset> | custom | love-css

cmd_install() {
    if [ $# -eq 0 ]; then
        echo "love install: missing argument" >&2
        echo "Usage: love install <preset> | custom | love-css" >&2
        exit 1
    fi

    _target="$1"

    case "$_target" in
        love-css)
            _clone_love_css "$@"
            ;;
        custom)
            _install_custom
            ;;
        *)
            _install_preset "$_target"
            ;;
    esac
}

_install_preset() {
    _preset="$1"
    _pf=$(preset_file "$_preset")
    if [ ! -f "$_pf" ]; then
        echo "love: preset '$_preset' not found" >&2
        echo "Available presets: $(ls "$LOVE_ROOT/registry/presets" | sed 's/\.json$//' | tr '\n' ' ')" >&2
        exit 1
    fi

    _css_dir=$(project_css_dir)
    _modules=""

    _source="remote"
    if resolve_love_css >/dev/null 2>&1; then
        _source="local"
    fi

    echo "love: installing preset '$_preset' ($_source source)"
    echo ""

    for _m in $(preset_modules "$_preset"); do
        install_module_with_deps "$_m" "$_css_dir" ""
        _modules="$_modules $_m"
    done

    write_love_json "$_preset" "$_modules"
    echo ""
    echo "love: preset '$_preset' installed into $_css_dir"
    echo "love: add <link rel=\"stylesheet\" href=\"css/love.*.css\"> to your HTML"
}

_install_custom() {
    _css_dir=$(project_css_dir)
    write_love_json "custom" ""
    echo "love: custom preset created"
    echo "love: run 'love add <module>' to add modules"
}

_clone_love_css() {
    shift
    _all=0
    for _arg in "$@"; do
        case "$_arg" in
            --all) _all=1 ;;
            -*) echo "love install love-css: unknown option $_arg" >&2; exit 1 ;;
        esac
    done

    if ! command -v git >/dev/null 2>&1; then
        echo "love: git is required to clone love-css" >&2
        exit 1
    fi

    _cache="${XDG_CACHE_HOME:-$HOME/.cache}/love-css"
    mkdir -p "$(dirname "$_cache")"

    if [ -d "$_cache/.git" ]; then
        echo "love: updating local love-css in $_cache"
        (cd "$_cache" && git pull --ff-only) || {
            echo "love: failed to update $_cache" >&2
            exit 1
        }
    else
        echo "love: cloning love-css into $_cache"
        git clone --depth=1 https://github.com/PlakhovVadim/love-css.git "$_cache"
    fi

    echo "love: love-css is available at $_cache"
    echo "love: the CLI will use it automatically for future installs"

    if [ "$_all" -eq 1 ]; then
        _css_dir=$(project_css_dir)
        for _f in "$_cache"/css/love.*.css; do
            [ -f "$_f" ] || continue
            cp "$_f" "$_css_dir/"
        done
        echo "love: all modules copied into $_css_dir"
    fi
}
