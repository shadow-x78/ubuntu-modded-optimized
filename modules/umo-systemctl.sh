#!/bin/sh
# UMO — Systemctl Emulator (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_SYSCTL_LOADED:-}" ] || return 0
_UMO_MOD_SYSCTL_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

umo_systemctl_install() {
    umo_log_step "Installing systemctl emulator"

    _bin="${UMO_INSTALL_DIR:?}/usr/local/bin/systemctl"
    cat > "$_bin" << 'EOF'
#!/bin/sh
# UMO Generic Systemctl — POSIX-compatible systemd emulator

ACTION="$1"
UNIT="$2"
UNIT_FILE="/etc/init.d/$UNIT"

usage() {
    echo "Usage: systemctl {start|stop|restart|status|enable|disable} <service>"
    echo "       Works with any /etc/init.d/<service> script, service(8), or /usr/sbin/<service>"
    exit 1
}

[ -n "$ACTION" ] || usage
[ -n "$UNIT" ] || usage

case "$ACTION" in
    start)
        if [ -x "$UNIT_FILE" ]; then
            "$UNIT_FILE" start
        else
            start-stop-daemon --start --background --exec "/usr/sbin/$UNIT" 2>/dev/null || service "$UNIT" start 2>/dev/null || echo "[WARN] Could not start $UNIT"
        fi
        ;;
    stop)
        if [ -x "$UNIT_FILE" ]; then
            "$UNIT_FILE" stop
        else
            start-stop-daemon --stop --name "$UNIT" 2>/dev/null || killall "$UNIT" 2>/dev/null || echo "[WARN] Could not stop $UNIT"
        fi
        ;;
    restart)
        "$0" stop "$UNIT"
        sleep 1
        "$0" start "$UNIT"
        ;;
    status)
        if pgrep -x "$UNIT" >/dev/null 2>&1; then
            echo "* $UNIT - active (running)"
            exit 0
        elif [ -x "$UNIT_FILE" ] && "$UNIT_FILE" status >/dev/null 2>&1; then
            echo "* $UNIT - active (running)"
            exit 0
        else
            echo "* $UNIT - inactive (dead)"
            exit 3
        fi
        ;;
    enable)
        mkdir -p /etc/rc.d
        ln -sf "$UNIT_FILE" /etc/rc.d/ 2>/dev/null || true
        echo "Enabled $UNIT"
        ;;
    disable)
        rm -f "/etc/rc.d/$UNIT" 2>/dev/null || true
        echo "Disabled $UNIT"
        ;;
    *) usage ;;
esac
EOF
    chmod +x "$_bin"
    ln -sf /usr/local/bin/systemctl "${UMO_INSTALL_DIR}/usr/local/bin/systemctl3" 2>/dev/null || true

    if [ -f "${UMO_INSTALL_DIR}/usr/bin/systemctl" ] && [ ! -L "${UMO_INSTALL_DIR}/usr/bin/systemctl" ]; then
        mv "${UMO_INSTALL_DIR}/usr/bin/systemctl" "${UMO_INSTALL_DIR}/usr/bin/systemctl.real" 2>/dev/null || true
        ln -sf /usr/local/bin/systemctl "${UMO_INSTALL_DIR}/usr/bin/systemctl" 2>/dev/null || true
    fi
    if [ -f "${UMO_INSTALL_DIR}/bin/systemctl" ] && [ ! -L "${UMO_INSTALL_DIR}/bin/systemctl" ]; then
        mv "${UMO_INSTALL_DIR}/bin/systemctl" "${UMO_INSTALL_DIR}/bin/systemctl.real" 2>/dev/null || true
        ln -sf /usr/local/bin/systemctl "${UMO_INSTALL_DIR}/bin/systemctl" 2>/dev/null || true
    fi

    umo_log_ok "Systemctl emulator installed."
}

umo_systemctl_ssh_helper() {
    _template="$SCRIPT_DIR/config/templates/umo-start-ssh.sh"
    _output="${UMO_INSTALL_DIR}/usr/local/bin/umo-start-ssh"
    if [ -f "$_template" ]; then
        umo_fs_render "$_template" "$_output"
    else
        cat > "$_output" << 'EOF'
#!/bin/sh
echo "[==>] Starting SSH server..."
[ -d /run/sshd ] || mkdir -p /run/sshd
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -A 2>/dev/null || true
/usr/sbin/sshd -D "$@"
EOF
    fi
    chmod +x "$_output"
}

umo_systemctl_setup() {
    umo_systemctl_install
    umo_systemctl_ssh_helper
}
