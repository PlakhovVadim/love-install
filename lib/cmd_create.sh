# love create <file.json> — create an empty love.json recipe.

cmd_create() {
    _target="${1:-$PWD/love.json}"

    if [ -f "$_target" ]; then
        echo "love: $_target already exists" >&2
        exit 1
    fi

    cat > "$_target" <<'EOF'
{
  "preset-name": null,
  "info": "",
  "modules": [],
  "elements": [],
  "animations": []
}
EOF

    echo "love: created $_target"
}
