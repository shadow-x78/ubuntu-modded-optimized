#!/bin/sh
INSTALL_DIR="{{INSTALL_DIR}}"
PREFIX="{{TERMUX_PREFIX}}"

if [ ! -d "$INSTALL_DIR" ]; then
    _UMO_G='ERR'; _UMO_C=''; _UMO_N=''; _UMO_UTF8=0
    if [ -t 1 ]; then
        case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
        if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
            case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
        fi
        if [ "$_UMO_UTF8" -eq 1 ]; then _UMO_G='✖'; fi
        if [ -z "${NO_COLOR:-}" ]; then _UMO_C='\033[38;5;196m'; _UMO_N='\033[0m'; fi
    fi
    printf "  %b%s%b  UMO not installed.\n" "$_UMO_C" "$_UMO_G" "$_UMO_N" >&2
    exit 1
fi

unset LD_PRELOAD
unset LD_LIBRARY_PATH

AUDIO_SOCK=""
[ -S "$PREFIX/tmp/pulse-$(id -u)/native" ] && AUDIO_SOCK="-b $PREFIX/tmp/pulse-$(id -u)/native:/tmp/pulse-native"
[ -S "$PREFIX/root/pulse-$(id -u)/native" ] && AUDIO_SOCK="-b $PREFIX/root/pulse-$(id -u)/native:/tmp/pulse-native"
[ -S "$PREFIX/tmp/pulse-native" ] && AUDIO_SOCK="-b $PREFIX/tmp/pulse-native:/tmp/pulse-native"

for _g in $(id -G 2>/dev/null); do
    grep -q ":x:$_g:" "$INSTALL_DIR/etc/group" 2>/dev/null || echo "android_$_g:x:$_g:" >> "$INSTALL_DIR/etc/group" 2>/dev/null || true
done

cd "$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "$HOME:/sdcard" -b "$HOME:/termux" \
    -b "$PREFIX/tmp:/tmp" -b "$PREFIX/tmp:/dev/shm" \
    $AUDIO_SOCK \
    -w / \
    /usr/bin/env -i PWD=/ HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/bash --login "$@"
