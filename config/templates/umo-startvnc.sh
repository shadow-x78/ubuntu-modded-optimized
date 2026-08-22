#!/bin/sh
_umo_login="${HOME:-/data/data/com.termux/files/home}/.umo/umo-login.sh"
[ -x "$_umo_login" ] || _umo_login="${HOME:-/data/data/com.termux/files/home}/umo-login.sh"

pulseaudio --start 2>/dev/null || true
sleep 1

if [ -x "$_umo_login" ]; then
    exec "$_umo_login" -c "UMO_VNC_PUBLIC=${UMO_VNC_PUBLIC:-0} umo-startvnc"
fi

echo "  [!] UMO not installed ($_umo_login missing). Run the UMO installer first."
exit 1
