#!/bin/sh
_UMO_NC=''; _UMO_GRN=''; _UMO_PRI=''; _UMO_YEL=''
_UMO_G_OK='OK'; _UMO_G_WARN='!'; _UMO_G_RUN='|'
if [ -t 1 ]; then
    _UMO_UTF8=0
    case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
    if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
        case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
    fi
    if [ "$_UMO_UTF8" -eq 1 ]; then _UMO_G_OK='✔'; _UMO_G_WARN='⚠'; _UMO_G_RUN='▌'; fi
    if [ -z "${NO_COLOR:-}" ]; then _UMO_NC='\033[0m'; _UMO_GRN='\033[38;5;34m'; _UMO_PRI='\033[38;5;208m'; _UMO_YEL='\033[38;5;220m'; fi
fi

printf "  %b%s%b  Stopping VNC...\n" "$_UMO_PRI" "$_UMO_G_RUN" "$_UMO_NC"
_vnc_cmd=""
command -v tigervncserver >/dev/null 2>&1 && _vnc_cmd="tigervncserver"
command -v vncserver      >/dev/null 2>&1 && [ -z "$_vnc_cmd" ] && _vnc_cmd="vncserver"

if [ -n "$_vnc_cmd" ]; then
    "$_vnc_cmd" -kill :1 2>/dev/null || true
    "$_vnc_cmd" -kill :2 2>/dev/null || true
fi
pkill -TERM -x Xvnc 2>/dev/null || true
pkill -TERM -x Xtigervnc 2>/dev/null || true
_wait=0
while [ "$_wait" -lt 5 ] && { pgrep -x Xvnc >/dev/null 2>&1 || pgrep -x Xtigervnc >/dev/null 2>&1; }; do
    sleep 1
    _wait=$((_wait + 1))
done
pkill -KILL -x Xvnc 2>/dev/null || true
pkill -KILL -x Xtigervnc 2>/dev/null || true
_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
rm -f "$_prefix/tmp/.X1-lock" "$_prefix/tmp/.X11-unix/X1" "$_prefix/tmp/.X2-lock" "$_prefix/tmp/.X11-unix/X2" 2>/dev/null || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
if pgrep -x Xvnc >/dev/null 2>&1 || pgrep -x Xtigervnc >/dev/null 2>&1; then
    printf "  %b%s%b  VNC Stop Incomplete (A Server Process Survived)\n" "$_UMO_YEL" "$_UMO_G_WARN" "$_UMO_NC"
else
    printf "  %b%s%b  VNC stopped\n" "$_UMO_GRN" "$_UMO_G_OK" "$_UMO_NC"
fi
