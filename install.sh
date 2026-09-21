#!/bin/sh
# Love.css installer for Linux, macOS, and Git Bash on Windows.
# Installs the love command into PATH and optionally clones love-css.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LOVE_BIN="$SCRIPT_DIR/bin/love"

if [ ! -f "$LOVE_BIN" ]; then
    echo "install.sh: bin/love not found. Run from the repository root." >&2
    exit 1
fi

chmod +x "$LOVE_BIN" "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/uninstall.sh" 2>/dev/null || true

# Determine the installation target directory.
if [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="${HOME}/.local/bin"
    mkdir -p "$TARGET_DIR"
fi

TARGET_LINK="$TARGET_DIR/love"

if [ -e "$TARGET_LINK" ] || [ -L "$TARGET_LINK" ]; then
    echo "install.sh: $TARGET_LINK already exists"
    echo "install.sh: removing old symlink"
    rm -f "$TARGET_LINK"
fi

ln -s "$LOVE_BIN" "$TARGET_LINK"
echo "install.sh: symlink created: $TARGET_LINK -> $LOVE_BIN"

# Check whether TARGET_DIR is in PATH.
case ":${PATH}:" in
    *:"$TARGET_DIR":*) ;;
    *)
        echo ""
        echo "install.sh: $TARGET_DIR is not in your PATH."
        echo "Add the following line to your shell profile:"
        echo ""
        echo "    export PATH=\"$TARGET_DIR:\$PATH\""
        echo ""
        echo "For bash: ~/.bashrc"
        echo "For zsh:  ~/.zshrc"
        echo ""
        ;;
esac

# Optional: clone love-css.
echo ""
printf "Clone love-css into the current directory? [y/N] "
read -r _answer
case "$_answer" in
    [yY]|[yY][eE][sS])
        if command -v git >/dev/null 2>&1; then
            _dest="$PWD/love-css"
            if [ -d "$_dest" ]; then
                echo "install.sh: $ _dest already exists, skipping"
            else
                git clone --depth=1 https://github.com/PlakhovVadim/love-css.git "$_dest"
                echo "install.sh: love-css cloned into $_dest"
            fi
        else
            echo "install.sh: git not found, skipping clone" >&2
        fi
        ;;
    *)
        echo "install.sh: skipping love-css clone"
        ;;
esac

echo ""
echo "install.sh: done. Restart your terminal and run: love status"
