#!/bin/sh
# UMO — Ubuntu Login Wrapper (template)
INSTALL_DIR="{{INSTALL_DIR}}"
PREFIX="{{TERMUX_PREFIX}}"

[ -d "$INSTALL_DIR" ] || { echo "[ERR] UMO not installed."; exit 1; }

export PROOT_NO_SECCOMP=1
export PROOT_LOAD_EXT_LIBS=0

AUDIO_SOCK=""
[ -S "$PREFIX/tmp/pulse-$(id -u)/native" ] && AUDIO_SOCK="-b $PREFIX/tmp/pulse-$(id -u)/native:/tmp/pulse-native"
[ -S "$PREFIX/tmp/pulse-native" ] && AUDIO_SOCK="-b $PREFIX/tmp/pulse-native:/tmp/pulse-native"

exec proot --link2symlink -0 -r "$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "$HOME:/sdcard" -b "$HOME:/termux" -b /data \
    -b "$PREFIX/tmp:/tmp" $AUDIO_SOCK \
    -w /root \
    /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/bash --login "$@"
