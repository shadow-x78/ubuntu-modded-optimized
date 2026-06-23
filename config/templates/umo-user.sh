#!/bin/sh
# UMO — Ubuntu User Login (template)
INSTALL_DIR="{{INSTALL_DIR}}"
PREFIX="{{TERMUX_PREFIX}}"

export PROOT_NO_SECCOMP=1
export PROOT_LOAD_EXT_LIBS=0

exec proot --link2symlink -0 -r "$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "$HOME:/sdcard" -b "$HOME:/termux" -b /data \
    -b "$PREFIX/tmp:/tmp" \
    -w /home/ubuntu \
    /usr/bin/env -i HOME=/home/ubuntu PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/su - ubuntu "$@"
