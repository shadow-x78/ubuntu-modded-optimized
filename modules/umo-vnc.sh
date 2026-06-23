#!/bin/sh
# UMO — VNC Server Manager (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_VNC_LOADED:-}" ] || return 0
_UMO_MOD_VNC_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_VNC_PORT="${UMO_VNC_PORT:-5901}"
UMO_VNC_GEOMETRY="${UMO_VNC_GEOMETRY:-1280x720}"
UMO_VNC_DEPTH="${UMO_VNC_DEPTH:-24}"
UMO_VNC_DISPLAY="${UMO_VNC_DISPLAY:-:1}"

umo_vnc_install() {
    umo_log_step "Installing VNC server..."
    cat > "${UMO_INSTALL_DIR:?}/root/install-vnc.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
apt-get update -y
apt-get install -y ubuntu-keyring || true
apt-get update -y
apt-get install -y apt-utils || true
dpkg --configure -a || true
apt-get install -y dialog tzdata || true
dpkg --configure -a || true
apt-get install -y tigervnc-standalone-server tigervnc-viewer tigervnc-common || true
apt-get install -y dbus-x11 xfonts-base xfonts-75dpi xfonts-100dpi || true
dpkg --configure -a || true
INNER
    chmod +x "${UMO_INSTALL_DIR}/root/install-vnc.sh"
    umo_run_quiet "Installing TigerVNC..." "$HOME/umo-login.sh" -c "bash /root/install-vnc.sh"
    rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh"

    umo_log_ok "TigerVNC installed."
}

umo_vnc_configure() {
    umo_log_step "Configuring VNC..."

    _vnc_dir="${UMO_INSTALL_DIR}/root/.vnc"
    umo_fs_mkdir "$_vnc_dir"

    _template="$SCRIPT_DIR/config/xstartup"
    if [ -f "$_template" ]; then
        umo_fs_render "$_template" "$_vnc_dir/xstartup" \
            "UMO_VERSION" "${UMO_VERSION:-3.3.3}" \
            "UMO_DE" "${UMO_DE:-xfce4}" \
            "DISPLAY" "${UMO_VNC_DISPLAY:-:1}"
    fi
    chmod +x "$_vnc_dir/xstartup"

    if [ -d "${UMO_INSTALL_DIR}/home/umo" ]; then
        _user_vnc="${UMO_INSTALL_DIR}/home/umo/.vnc"
        umo_fs_mkdir "$_user_vnc"
        cp "$_vnc_dir/xstartup" "$_user_vnc/xstartup"
        chmod +x "$_user_vnc/xstartup"
        chown -R 1000:1000 "$_user_vnc" 2>/dev/null || true
    fi

    _passwd="${UMO_INSTALL_DIR}/root/.vnc/passwd"
    if [ ! -f "$_passwd" ]; then
        printf 'umo\numo\n' | "$HOME/umo-login.sh" -c "vncpasswd >/dev/null 2>&1" || \
        printf 'umo\numo\n' | "$HOME/umo-login.sh" -c "tigervncpasswd >/dev/null 2>&1" || true
    fi

    umo_log_ok "VNC configured."
}

umo_vnc_create_scripts() {
    umo_log_step "Creating VNC scripts..."

    cat > "${UMO_INSTALL_DIR}/usr/local/bin/umo-startvnc" << 'EOF'
#!/bin/sh
VNC_DISPLAY="${VNC_DISPLAY:-:1}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x720}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PORT="${VNC_PORT:-5901}"

for _pid in $(pgrep -f Xvnc 2>/dev/null); do kill "$_pid" 2>/dev/null || true; done
sleep 1

pulseaudio --start 2>/dev/null || true

_vnc_cmd=""
if command -v tigervncserver >/dev/null 2>&1; then
    _vnc_cmd="tigervncserver"
elif command -v vncserver >/dev/null 2>&1; then
    _vnc_cmd="vncserver"
else
    echo "  [!] VNC server not found. Install with: apt install tigervnc-standalone-server"
    exit 1
fi

$_vnc_cmd "$VNC_DISPLAY" \
    -geometry "$VNC_GEOMETRY" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -name "UMO Desktop" \
    -deferUpdate 1 \
    -alwaysshared \
    -Log "*:stderr:100" &

sleep 2

_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$_IP" ] && _IP="127.0.0.1"

_NC='\033[0m'
_PRI='\033[38;5;208m'
_GRN='\033[38;5;34m'
_CYN='\033[38;5;39m'
_BOLD='\033[1m'
_DIM='\033[2m'

printf "\n"
printf "  ${_PRI}────────────────────────────────────────${_NC}\n"
printf "  ${_BOLD}${_GRN}▸ UMO VNC Server${_NC}\n"
printf "  ${_PRI}────────────────────────────────────────${_NC}\n"
printf "\n"
printf "  ${_BOLD}Display:${_NC}    ${_CYN}%s${_NC}\n" "$VNC_DISPLAY"
printf "  ${_BOLD}Address:${_NC}    ${_CYN}%s:%s${_NC}\n" "$_IP" "$VNC_PORT"
printf "  ${_BOLD}Resolution:${_NC} ${_DIM}%s${_NC}\n" "$VNC_GEOMETRY"
printf "\n"
printf "  ${_PRI}────────────────────────────────────────${_NC}\n"
printf "\n"
EOF
    chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/umo-startvnc"

    cat > "${UMO_INSTALL_DIR}/usr/local/bin/umo-stopvnc" << 'EOF'
#!/bin/sh
_vnc_cmd=""
if command -v tigervncserver >/dev/null 2>&1; then
    _vnc_cmd="tigervncserver"
elif command -v vncserver >/dev/null 2>&1; then
    _vnc_cmd="vncserver"
fi

if [ -n "$_vnc_cmd" ]; then
    $_vnc_cmd -kill :1 2>/dev/null || true
    $_vnc_cmd -kill :2 2>/dev/null || true
fi
for _pid in $(pgrep -f Xvnc 2>/dev/null); do kill -9 "$_pid" 2>/dev/null || true; done
printf "  \033[38;5;34m✔\033[0m  VNC stopped.\n"
EOF
    chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/umo-stopvnc"

    cat > "$HOME/umo-vnc-start.sh" << 'EOF'
#!/bin/sh
pulseaudio --start 2>/dev/null || true
sleep 1
exec "$HOME/umo-login.sh" -c "umo-startvnc"
EOF
    chmod +x "$HOME/umo-vnc-start.sh"

    cat > "$HOME/umo-vnc-stop.sh" << 'EOF'
#!/bin/sh
exec "$HOME/umo-login.sh" -c "umo-stopvnc"
EOF
    chmod +x "$HOME/umo-vnc-stop.sh"

    umo_log_ok "VNC scripts created."
}

umo_vnc_setup() {
    umo_vnc_install
    umo_vnc_configure
    umo_vnc_create_scripts
}
