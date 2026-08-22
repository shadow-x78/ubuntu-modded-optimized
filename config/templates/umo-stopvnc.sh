#!/bin/sh
echo "[==>] Stopping VNC..."
_vnc_cmd=""
command -v tigervncserver >/dev/null 2>&1 && _vnc_cmd="tigervncserver"
command -v vncserver      >/dev/null 2>&1 && [ -z "$_vnc_cmd" ] && _vnc_cmd="vncserver"

if [ -n "$_vnc_cmd" ]; then
    "$_vnc_cmd" -kill :1 2>/dev/null || true
    "$_vnc_cmd" -kill :2 2>/dev/null || true
fi
for _pid in $(pgrep -f Xvnc) $(pgrep -f Xtigervnc); do kill -9 "$_pid" 2>/dev/null || true; done
echo "[OK] VNC stopped."
