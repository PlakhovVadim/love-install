# love update — refresh installed modules from love-css.
# Only touches files that already exist in the project's css/ directory.
# Never adds new modules and never pulls anything the user did not install.

cmd_update() {
    if [ ! -d "$PWD/css" ]; then
        echo "love: no css/ directory in this project" >&2
        exit 1
    fi

    local _local_css _curl _repo _updated _m _file _files
    local _base _dest _src _url _tmp _attempt _max_attempts

    _local_css=""
    if _local_css=$(resolve_love_css); then
        :
    fi

    _curl=""
    _repo=""
    if [ -z "$_local_css" ]; then
        _curl=$(require_curl)
        _repo=$(registry_repository)
    fi

    _updated=0

    for _m in $(installed_modules); do
        _files=$(module_files "$_m" 2>/dev/null) || continue
        if [ -z "$_files" ]; then
            continue
        fi

        for _file in $_files; do
            _base=$(basename "$_file")

            case "$_file" in
                assets/*)
                    _dest="$PWD/$_file"
                    ;;
                *)
                    _dest="$PWD/css/$_base"
                    ;;
            esac

            if [ -n "$_local_css" ]; then
                _src="$_local_css/$_file"
                if [ ! -f "$_src" ]; then
                    continue
                fi
                if [ ! -f "$_dest" ]; then
                    mkdir -p "$(dirname "$_dest")"
                    cp "$_src" "$_dest"
                    echo "love: added $_file"
                    _updated=$((_updated + 1))
                elif ! cmp -s "$_src" "$_dest"; then
                    cp "$_src" "$_dest"
                    echo "love: updated $_file"
                    _updated=$((_updated + 1))
                fi
            else
                _url="$_repo/$_file"
                _tmp=$(mktemp)
                _max_attempts=3
                _attempt=1

                while [ "$_attempt" -le "$_max_attempts" ]; do
                    if "$_curl" -fsSL "$_url" -o "$_tmp"; then
                        break
                    fi
                    rm -f "$_tmp"
                    _tmp=$(mktemp)
                    if [ "$_attempt" -lt "$_max_attempts" ]; then
                        sleep 2
                    fi
                    _attempt=$((_attempt + 1))
                done

                if [ "$_attempt" -gt "$_max_attempts" ]; then
                    rm -f "$_tmp"
                    echo "love: failed to fetch $_file" >&2
                    continue
                fi

                if [ ! -f "$_dest" ]; then
                    mkdir -p "$(dirname "$_dest")"
                    cp "$_tmp" "$_dest"
                    echo "love: added $_file"
                    _updated=$((_updated + 1))
                elif ! cmp -s "$_tmp" "$_dest"; then
                    cp "$_tmp" "$_dest"
                    echo "love: updated $_file"
                    _updated=$((_updated + 1))
                fi
                rm -f "$_tmp"
            fi
        done
    done

    if [ "$_updated" -eq 0 ]; then
        echo "love: all modules are up to date"
    else
        echo "love: $_updated file(s) updated"
    fi
}
