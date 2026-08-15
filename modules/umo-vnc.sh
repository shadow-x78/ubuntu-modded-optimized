#!/bin/sh
# UMO - VNC Server Manager (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_MOD_VNC_LOADED:-}" ] || return 0
_UMO_MOD_VNC_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_VNC_PORT="${UMO_VNC_PORT:-5901}"
UMO_VNC_GEOMETRY="${UMO_VNC_GEOMETRY:-1280x720}"
UMO_VNC_DEPTH="${UMO_VNC_DEPTH:-24}"
UMO_VNC_DISPLAY="${UMO_VNC_DISPLAY:-:1}"

_umo_apt_repair_body() {
    cat << 'REPAIR'
export DEBIAN_FRONTEND=noninteractive
_apt_filter() { grep -v "^Ign\|^Get:\|^Preparing\|^Unpacking\|^Selecting\|^Setting up\|^Processing\|^Reading\|^Building\|^Creating\|^debconf:" || true; }
_um_apt_repair() {
    dpkg --configure -a 2>&1 | _apt_filter || true
    _broken=$(dpkg -l 2>/dev/null | awk '/^iU|^iF|^hF/{print $2}')
    if [ -n "$_broken" ]; then
        for _pkg in $_broken; do
            dpkg --remove --force-depends "$_pkg" 2>&1 | _apt_filter || true
        done
        timeout 600 apt-get -f install -y 2>&1 | _apt_filter || true
        dpkg --configure -a 2>&1 | _apt_filter || true
    fi
}
REPAIR
}

umo_vnc_install() {
    umo_log_step "Install VNC server"
    {
        cat << 'HDR'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null

echo "tzdata tzdata/Areas select Etc" | debconf-set-selections 2>/dev/null || true
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections 2>/dev/null || true

HDR
        _umo_apt_repair_body
        cat << 'BODY'

_um_apt_repair

timeout 600 apt-get install -y --no-install-recommends \
    fontconfig fontconfig-config libfontconfig1 libfreetype6 libexpat1 \
    libpng16-16 libbrotli1 fonts-dejavu-core ucf \
    x11-common x11-xkb-utils xauth xkb-data \
    libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 \
    libbsd0 libmd0 libxfont2 libfontenc1 libxcursor1 libxext6 \
    libxfixes3 libxft2 libxinerama1 libxrender1 libxi6 libxrandr2 \
    libxt6 libxaw7 libxkbfile1 libxmuu1 libpixman-1-0 libjpeg8 libgl1 \
    libfile-readbackwards-perl libfltk1.3 libfltk-images1.3 \
    apt-utils dialog tzdata \
    xfonts-base xfonts-encodings xfonts-utils \
    dbus-x11 \
    tigervnc-standalone-server tigervnc-viewer tigervnc-common tigervnc-tools \
    2>&1 | _apt_filter || true

_um_apt_repair

if command -v tigervncserver >/dev/null 2>&1 || command -v vncserver >/dev/null 2>&1; then
    exit 0
fi

echo "=== ERROR: TigerVNC installation failed ==="
echo "--- dpkg audit ---"
dpkg --audit 2>&1 | head -20
echo "--- dpkg status ---"
dpkg -l 'tigervnc*' 2>&1 | tail -10
echo "--- status file perms ---"
ls -la /var/lib/dpkg/status* 2>&1
exit 1
BODY
    } > "${UMO_INSTALL_DIR:?}/root/install-vnc.sh"
    chmod +x "${UMO_INSTALL_DIR}/root/install-vnc.sh"
    if sh -n "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null; then
        umo_log_debug "install-vnc.sh syntax verified"
    else
        umo_log_warn "install-vnc.sh has syntax issues"
    fi
    printf "  %b>%b  Installing TigerVNC...\n" "$UMO_B_CYAN" "$UMO_NC"
    if [ ! -x "$HOME/umo-login.sh" ]; then
        umo_log_err "umo-login.sh not executable - VNC install skipped"
        rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh"
        return 1
    fi
    _rc=0
    if [ "${UMO_DEV_MODE:-0}" != "1" ]; then
        "$HOME/umo-login.sh" -c "bash /root/install-vnc.sh" || _rc=$?
    fi
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  TigerVNC installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC"
    else
        printf "  %b%s%b  TigerVNC installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_rc"
    fi
    rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh"
}

umo_vnc_configure() {
    umo_log_step "Configure VNC"

    _vnc_dir="${UMO_INSTALL_DIR}/root/.vnc"
    umo_fs_mkdir "$_vnc_dir"

    _template="$SCRIPT_DIR/config/xstartup"
    if [ -f "$_template" ]; then
        umo_fs_render "$_template" "$_vnc_dir/xstartup" \
            "UMO_VERSION" "${UMO_VERSION:-4.4.0}" \
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

    _vnc_pass="${UMO_VNC_PASSWORD:-ubuntu}"
    _passwd="${UMO_INSTALL_DIR}/root/.vnc/passwd"
    if [ ! -f "$_passwd" ]; then
        "$HOME/umo-login.sh" -c "mkdir -p ~/.vnc && echo '$_vnc_pass' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd" 2>/dev/null || true
    fi

    umo_log_ok "VNC configured"
}

umo_vnc_create_scripts() {
    umo_log_step "Create VNC scripts"

    cat > "${UMO_INSTALL_DIR}/usr/local/bin/umo-startvnc" << 'EOF'
#!/bin/sh
VNC_DISPLAY="${VNC_DISPLAY:-:1}"
VNC_GEOMETRY="${VNC_GEOMETRY:-1280x720}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PORT="${VNC_PORT:-5901}"

for _pid in $(pgrep -f Xvnc 2>/dev/null) $(pgrep -f Xtigervnc 2>/dev/null); do kill "$_pid" 2>/dev/null || true; done
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

export MESA_NO_SHM=1
export GALLIUM_DRIVER=llvmpipe
export LIBGL_ALWAYS_SOFTWARE=1

if ! $_vnc_cmd "$VNC_DISPLAY" \
    -geometry "$VNC_GEOMETRY" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -name "UMO Desktop" \
    -alwaysshared \
    -Log "*:stderr:100"; then
    echo "  [!] Failed to start VNC server"
    exit 1
fi

sleep 2

_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$_IP" ] && _IP="127.0.0.1"

_NC='\033[0m'
_PRI='\033[38;5;208m'
_GRN='\033[38;5;34m'
_CYN='\033[38;5;39m'
_BOLD='\033[1m'
_DIM='\033[2m'

printf "\n${_PRI}"
printf "  ██╗   ██╗███╗   ███╗ ██████╗  \n"
printf "  ██║   ██║████╗ ████║██╔═══██╗ \n"
printf "  ██║   ██║██╔████╔██║██║   ██║ \n"
printf "  ██║   ██║██║╚██╔╝██║██║   ██║ \n"
printf "  ╚██████╔╝██║ ╚═╝ ██║╚██████╔╝ \n"
printf "   ╚═════╝ ╚═╝     ╚═╝ ╚═════╝  \n"
printf "${_NC}\n"

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

while pgrep -f "Xvnc" >/dev/null 2>&1 || pgrep -f "Xtigervnc" >/dev/null 2>&1; do
    sleep 3
done
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
for _pid in $(pgrep -f Xvnc 2>/dev/null) $(pgrep -f Xtigervnc 2>/dev/null); do kill -9 "$_pid" 2>/dev/null || true; done
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

    umo_log_ok "VNC scripts created"
}

umo_vnc_setup() {
    umo_vnc_install
    umo_vnc_configure
    umo_vnc_create_scripts
}
