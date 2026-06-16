#!/bin/sh
# UMO — Quick-start Wrapper (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if running inside project or from extracted archive
if [ -f "$SCRIPT_DIR/bin/umo-install" ]; then
    exec "$SCRIPT_DIR/bin/umo-install" "$@"
else
    echo "[ERR] UMO installer not found."
    echo "      Expected: $SCRIPT_DIR/bin/umo-install"
    exit 1
fi
