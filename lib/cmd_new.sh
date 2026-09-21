# love new <preset> <dir> — create a new project from a template.

cmd_new() {
    if [ $# -lt 2 ]; then
        echo "Usage: love new <preset> <dir>" >&2
        exit 1
    fi

    _preset="$1"
    _dir="$2"
    _template="$LOVE_ROOT/templates/$_preset"

    if [ ! -d "$_template" ]; then
        echo "love: template '$_preset' not found" >&2
        echo "Available templates: $(ls "$LOVE_ROOT/templates" | tr '\n' ' ')" >&2
        exit 1
    fi

    if [ -d "$_dir" ]; then
        echo "love: directory '$_dir' already exists" >&2
        exit 1
    fi

    mkdir -p "$_dir"
    cp "$_template"/* "$_dir/" 2>/dev/null || true
    (cd "$_dir" && "$LOVE_ROOT/bin/love" install "$_preset")

    echo "love: project created in $_dir"
}
