# love info -m <module> | -p <preset>

cmd_info() {
    _type=""
    _name=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -m) _type="module"; _name="$2"; shift 2 ;;
            -p) _type="preset"; _name="$2"; shift 2 ;;
            *) echo "love info: unknown option $1" >&2; exit 1 ;;
        esac
    done

    if [ -z "$_type" ]; then
        echo "Usage: love info -m <module> | -p <preset>" >&2
        exit 1
    fi

    case "$_type" in
        module)
            _reg=$(registry_file)
            "$(require_python)" "$LOVE_ROOT/cli/registry_query.py" module-info "$_reg" "$_name"
            ;;
        preset)
            _pf=$(preset_file "$_name")
            if [ ! -f "$_pf" ]; then
                echo "love: preset '$_name' not found" >&2
                exit 1
            fi
            "$(require_python)" "$LOVE_ROOT/cli/registry_query.py" preset-info "$_pf"
            ;;
    esac
}
