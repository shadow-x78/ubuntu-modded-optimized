#!/bin/sh
INSTALL_DIR="{{INSTALL_DIR}}"
PREFIX="{{TERMUX_PREFIX}}"
UMO_USER="{{UMO_USER}}"

unset LD_PRELOAD
unset LD_LIBRARY_PATH

cd "$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "$HOME:/sdcard" -b "$HOME:/termux" \
    -b "$PREFIX/tmp:/tmp" -b "$PREFIX/tmp:/dev/shm" \
    -w / \
    /usr/bin/env -i PWD=/ HOME=/home/$UMO_USER PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/su - $UMO_USER "$@"
