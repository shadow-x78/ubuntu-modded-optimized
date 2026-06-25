#!/bin/sh
# UMO — Stop VNC (template)
echo "[==>] Stopping VNC..."
vncserver -kill :1 2>/dev/null || true
vncserver -kill :2 2>/dev/null || true
for _pid in $(pgrep -f Xvnc) $(pgrep -f Xtigervnc); do kill -9 "$_pid" 2>/dev/null || true; done
echo "[OK] VNC stopped."
