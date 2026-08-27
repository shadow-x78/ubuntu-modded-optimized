#!/bin/sh

set -e
[ -t 1 ] && printf '\033[2J\033[3J\033[H\033c'
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/bin/umo-install" ]; then
    chmod +x "$SCRIPT_DIR/bin/umo-install"
    exec "$SCRIPT_DIR/bin/umo-install" "$@"
else
    _UMO_G='ERR'; _UMO_C=''; _UMO_N=''; _UMO_UTF8=0
    if [ -t 1 ]; then
        case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
        if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
            case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
        fi
        if [ "$_UMO_UTF8" -eq 1 ]; then _UMO_G='✖'; fi
        if [ -z "${NO_COLOR:-}" ]; then _UMO_C='\033[38;5;196m'; _UMO_N='\033[0m'; fi
    fi
    printf "  %b%s%b  UMO installer not found\n" "$_UMO_C" "$_UMO_G" "$_UMO_N" >&2
    echo "      Expected: ${SCRIPT_DIR#"/data/data/com.termux/files"}/bin/umo-install"
    exit 1
fi
