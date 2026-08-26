#!/bin/sh
# UMO - Host VNC Stop Template (rendered per install) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized
_UMO_NC=''; _UMO_GRN=''; _UMO_PRI=''
_UMO_G_OK='OK'; _UMO_G_RUN='|'
if [ -t 1 ]; then
    _UMO_UTF8=0
    case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
    if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
        case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
    fi
    if [ "$_UMO_UTF8" -eq 1 ]; then _UMO_G_OK='✔'; _UMO_G_RUN='▌'; fi
    if [ -z "${NO_COLOR:-}" ]; then _UMO_NC='\033[0m'; _UMO_GRN='\033[38;5;34m'; _UMO_PRI='\033[38;5;208m'; fi
fi

printf "  %b%s%b  Stopping VNC...\n" "$_UMO_PRI" "$_UMO_G_RUN" "$_UMO_NC"
_vnc_cmd=""
command -v tigervncserver >/dev/null 2>&1 && _vnc_cmd="tigervncserver"
command -v vncserver      >/dev/null 2>&1 && [ -z "$_vnc_cmd" ] && _vnc_cmd="vncserver"

if [ -n "$_vnc_cmd" ]; then
    "$_vnc_cmd" -kill :1 2>/dev/null || true
    "$_vnc_cmd" -kill :2 2>/dev/null || true
fi
for _pid in $(pgrep -f Xvnc) $(pgrep -f Xtigervnc); do kill -9 "$_pid" 2>/dev/null || true; done
printf "  %b%s%b  VNC stopped\n" "$_UMO_GRN" "$_UMO_G_OK" "$_UMO_NC"
