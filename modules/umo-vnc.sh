#!/bin/sh

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
    if [ ! -x "$UMO_LOGIN_SH" ]; then
        umo_log_warn "umo-login.sh not found/executable - VNC install skipped"
        rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null || true
        return 0
    fi
    _rc=0
    if [ "${UMO_DEV_MODE:-0}" != "1" ]; then
        "$UMO_LOGIN_SH" -c "bash /root/install-vnc.sh" || _rc=$?
    fi
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  TigerVNC installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC"
    else
        printf "  %b%s%b  TigerVNC installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_rc"
    fi
    rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null || true
    return 0
}

umo_vnc_configure() {
    umo_log_step "Configure VNC"

    _vnc_dir="${UMO_INSTALL_DIR}/root/.vnc"
    if ! mkdir -p "$_vnc_dir" 2>/dev/null; then
        umo_log_warn "Cannot create $_vnc_dir - VNC configuration skipped"
        return 0
    fi

    _template="$SCRIPT_DIR/config/xstartup"
    if [ -f "$_template" ]; then
        umo_fs_render "$_template" "$_vnc_dir/xstartup" \
            "UMO_VERSION" "${UMO_VERSION:-4.9.8}" \
            "UMO_DE" "${UMO_DE:-xfce4}" \
            "DISPLAY" "${UMO_VNC_DISPLAY:-:1}"
    else
        umo_log_warn "config/xstartup template missing - writing fallback session"
        cat > "$_vnc_dir/xstartup" << 'XFALL'
#!/bin/sh
export PULSE_SERVER=127.0.0.1
export DISPLAY=:1
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true
_start_session() {
    if command -v dbus-launch >/dev/null 2>&1; then
        exec dbus-launch --exit-with-session "$@"
    fi
    exec "$@"
}
command -v startxfce4 >/dev/null 2>&1 && _start_session startxfce4
command -v startlxde  >/dev/null 2>&1 && _start_session startlxde
command -v openbox-session >/dev/null 2>&1 && _start_session openbox-session
command -v xterm >/dev/null 2>&1 && exec xterm
exec /bin/sh -c "while :; do sleep 3600; done"
XFALL
    fi
    if [ -f "$_vnc_dir/xstartup" ]; then
        chmod +x "$_vnc_dir/xstartup" 2>/dev/null || true
    fi

    if [ -d "${UMO_INSTALL_DIR}/home/umo" ]; then
        _user_vnc="${UMO_INSTALL_DIR}/home/umo/.vnc"
        if mkdir -p "$_user_vnc" 2>/dev/null && [ -f "$_vnc_dir/xstartup" ]; then
            cp -f "$_vnc_dir/xstartup" "$_user_vnc/xstartup" 2>/dev/null || true
            chmod +x "$_user_vnc/xstartup" 2>/dev/null || true
            chown -R 1000:1000 "$_user_vnc" 2>/dev/null || true
        fi
    fi

    _vnc_pass_file="${UMO_RUNTIME_DIR:-$HOME/.umo}/vnc-pass"
    _vnc_pass=""
    if [ -s "$_vnc_pass_file" ]; then
        _vnc_pass="$(tr -d '\r\n' < "$_vnc_pass_file" 2>/dev/null || true)"
    fi
    if [ -z "$_vnc_pass" ]; then
        _vnc_pass="${UMO_VNC_PASSWORD:-}"
    fi
    if [ -z "$_vnc_pass" ]; then
        _vnc_pass="$(tr -dc A-Za-z0-9 < /dev/urandom 2>/dev/null | head -c 8 || true)"
    fi
    if [ -z "$_vnc_pass" ]; then
        _vnc_pass="umo$(date +%s | tr -dc '0-9' | tail -c 5)"
    fi
    mkdir -p "$(dirname "$_vnc_pass_file")" 2>/dev/null || true
    printf '%s\n' "$_vnc_pass" > "$_vnc_pass_file" 2>/dev/null || true
    chmod 600 "$_vnc_pass_file" 2>/dev/null || true

    _passwd="${UMO_INSTALL_DIR}/root/.vnc/passwd"
    if [ ! -f "$_passwd" ]; then
        if [ -x "$UMO_LOGIN_SH" ]; then
            _pw_cmd="mkdir -p ~/.vnc && echo '$_vnc_pass' | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"
            if command -v timeout >/dev/null 2>&1; then
                timeout 120 "$UMO_LOGIN_SH" -c "$_pw_cmd" </dev/null 2>/dev/null || \
                    umo_log_warn "Could not set VNC password (vncpasswd not available yet)"
            else
                "$UMO_LOGIN_SH" -c "$_pw_cmd" </dev/null 2>/dev/null || \
                    umo_log_warn "Could not set VNC password (vncpasswd not available yet)"
            fi
        fi
    fi

    umo_log_ok "VNC configured"
    return 0
}

umo_vnc_create_scripts() {
    umo_log_step "Create VNC scripts"

    if ! mkdir -p "${UMO_INSTALL_DIR}/usr/local/bin" 2>/dev/null; then
        umo_log_warn "Cannot create /usr/local/bin - VNC helper scripts skipped"
        return 0
    fi

    for _cscript in umo-startvnc umo-stopvnc; do
        _src="$SCRIPT_DIR/config/container/$_cscript"
        if [ -f "$_src" ]; then
            cp -f "$_src" "${UMO_INSTALL_DIR}/usr/local/bin/$_cscript" 2>/dev/null || true
            chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/$_cscript" 2>/dev/null || true
        else
            umo_log_warn "container script missing: $_src"
        fi
    done

    _vnc_home="${UMO_SCRIPT_DIR:-$HOME/.umo}"
    mkdir -p "$_vnc_home" 2>/dev/null || _vnc_home="$HOME"
    _umo_login="${UMO_LOGIN_SH:-$_vnc_home/umo-login.sh}"

    cat > "$_vnc_home/umo-vnc-start.sh" << EOF
#!/bin/sh
pulseaudio --start 2>/dev/null || true
sleep 1
exec "$_umo_login" -c "umo-startvnc"
EOF
    chmod +x "$_vnc_home/umo-vnc-start.sh"

    cat > "$_vnc_home/umo-vnc-stop.sh" << EOF
#!/bin/sh
exec "$_umo_login" -c "umo-stopvnc"
EOF
    chmod +x "$_vnc_home/umo-vnc-stop.sh"

    umo_log_ok "VNC scripts created ($_vnc_home)"
}

umo_vnc_setup() {
    umo_vnc_install
    umo_vnc_configure
    umo_vnc_create_scripts
}
