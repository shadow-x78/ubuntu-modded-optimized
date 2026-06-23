#!/bin/sh
# UMO — Quick-start Wrapper (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

set -e
printf '\033[2J\033[H'
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/bin/umo-install" ]; then
    chmod +x "$SCRIPT_DIR/bin/umo-install"
    if command -v setsid >/dev/null 2>&1; then
        exec setsid "$SCRIPT_DIR/bin/umo-install" "$@"
    else
        exec "$SCRIPT_DIR/bin/umo-install" "$@"
    fi
else
    echo "[ERR] UMO installer not found."
    echo "      Expected: $SCRIPT_DIR/bin/umo-install"
    exit 1
fi
