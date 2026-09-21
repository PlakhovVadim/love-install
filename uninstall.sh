#!/bin/sh
# Love.css uninstaller. Removes the love symlink from PATH.

set -eu

if [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="${HOME}/.local/bin"
fi

TARGET_LINK="$TARGET_DIR/love"

if [ -L "$TARGET_LINK" ] || [ -e "$TARGET_LINK" ]; then
    rm -f "$TARGET_LINK"
    echo "uninstall.sh: removed $TARGET_LINK"
else
    echo "uninstall.sh: $TARGET_LINK not found"
fi
