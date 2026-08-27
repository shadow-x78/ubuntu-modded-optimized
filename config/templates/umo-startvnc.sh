#!/bin/sh
_umo_login="${HOME:-/data/data/com.termux/files/home}/.umo/umo-login.sh"
[ -x "$_umo_login" ] || _umo_login="${HOME:-/data/data/com.termux/files/home}/umo-login.sh"

pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
sleep 1

if [ -x "$_umo_login" ]; then
    exec "$_umo_login" -c "umo-startvnc"
fi

_UMO_G='ERR'; _UMO_C=''; _UMO_N=''; _UMO_UTF8=0
if [ -t 1 ]; then
    case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
    if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
        case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
    fi
    if [ "$_UMO_UTF8" -eq 1 ]; then _UMO_G='✖'; fi
    if [ -z "${NO_COLOR:-}" ]; then _UMO_C='\033[38;5;196m'; _UMO_N='\033[0m'; fi
fi
_umo_login_d="${_umo_login#"${HOME%/*}"}"
printf "  %b%s%b  UMO not installed (%s missing). Run the UMO installer first.\n" "$_UMO_C" "$_UMO_G" "$_UMO_N" "$_umo_login_d" >&2
exit 1
