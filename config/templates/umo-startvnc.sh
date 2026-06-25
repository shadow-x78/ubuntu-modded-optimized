#!/bin/sh
# UMO — Start VNC (template)
VNC_DISPLAY="${VNC_DISPLAY:-{{DISPLAY}}}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x720}"
VNC_DEPTH="${VNC_DEPTH:-{{VNC_DEPTH}}}"
VNC_PORT="${VNC_PORT:-{{VNC_PORT}}}"

for _pid in $(pgrep -f Xvnc) $(pgrep -f Xtigervnc); do kill "$_pid" 2>/dev/null || true; done
sleep 1

pulseaudio --start 2>/dev/null || true

export MESA_NO_SHM=1
export GALLIUM_DRIVER=llvmpipe
export LIBGL_ALWAYS_SOFTWARE=1

if ! vncserver "$VNC_DISPLAY" \
    -geometry "$VNC_GEOMETRY" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -name "UMO Desktop" \
    -alwaysshared \
    -Log "*:stderr:100"; then
    echo ""
    echo "  [!] Failed to start VNC server"
    exit 1
fi

sleep 2

_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$_IP" ] && _IP="127.0.0.1"

echo ""
echo "============================================"
echo "  UMO VNC Server Started"
echo "  Display: $VNC_DISPLAY"
echo "  Address: $_IP:$VNC_PORT"
echo "============================================"
echo ""
