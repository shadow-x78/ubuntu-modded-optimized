#!/bin/sh

[ -z "${_UMO_MOD_VNC_LOADED:-}" ] || return 0
_UMO_MOD_VNC_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_VNC_DISPLAY="${UMO_VNC_DISPLAY:-:1}"

_umo_apt_repair_body() {
    cat << 'REPAIR'
export DEBIAN_FRONTEND=noninteractive
_um_apt_repair() {
    dpkg --configure -a || true
    timeout 900 apt-get -f install -y || true
    dpkg --configure -a || true
    _broken=$(dpkg -l 2>/dev/null | awk '/^iU|^iF|^hF/{print $2}')
    if [ -n "$_broken" ]; then
        for _pkg in $_broken; do
            dpkg --remove --force-depends "$_pkg" || true
        done
        timeout 900 apt-get -f install -y || true
        dpkg --configure -a || true
    fi
}
REPAIR
}

umo_vnc_install() {
    umo_log_step "Install VNC Server"
    {
        printf '%s\n' '#!/bin/sh'
        _umo_log_container_prelude
        cat << 'HDR'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null
_LOG=/root/install-vnc.log

HDR
        _tz_area="${UMO_TZ%%/*}"
        _tz_zone="${UMO_TZ#*/}"
        [ -n "$_tz_area" ] || _tz_area="Etc"
        [ -n "$_tz_zone" ] || _tz_zone="UTC"
        printf 'echo "tzdata tzdata/Areas select %s" | debconf-set-selections 2>/dev/null || true\n' "$_tz_area"
        printf 'echo "tzdata tzdata/Zones/%s select %s" | debconf-set-selections 2>/dev/null || true\n' "$_tz_area" "$_tz_zone"
        printf '\n'
        _umo_apt_repair_body
        cat << 'BODY'

_step "Preparing TigerVNC Package Database..."
_um_apt_repair >> "$_LOG" 2>&1

_step "Updating Package Lists..."
timeout 600 apt-get update -qq >> "$_LOG" 2>&1 || true

_step "Installing TigerVNC Packages (This May Take A While)..."
timeout 600 apt-get install -y --no-install-recommends \
    fontconfig fontconfig-config libfontconfig1 libfreetype6 libexpat1 \
    libpng16-16 libbrotli1 fonts-dejavu-core ucf \
    x11-common x11-xkb-utils x11-xserver-utils xauth xkb-data \
    libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 \
    libbsd0 libmd0 libxfont2 libfontenc1 libxcursor1 libxext6 \
    libxfixes3 libxft2 libxinerama1 libxrender1 libxi6 libxrandr2 \
    libxt6 libxaw7 libxkbfile1 libxmuu1 libpixman-1-0 libjpeg8 libgl1 \
    libfile-readbackwards-perl libfltk1.3 libfltk-images1.3 \
    apt-utils dialog tzdata \
    xfonts-base xfonts-encodings xfonts-utils \
    dbus-x11 \
    tigervnc-standalone-server tigervnc-viewer tigervnc-common tigervnc-tools \
    >> "$_LOG" 2>&1 || true

_step "Finalizing TigerVNC Package Database..."
_um_apt_repair >> "$_LOG" 2>&1

if command -v tigervncserver >/dev/null 2>&1 || command -v vncserver >/dev/null 2>&1; then
    exit 0
fi

_fail "TigerVNC Install Failed"
_warn "dpkg Audit:"
dpkg --audit 2>&1 | head -20 | sed 's/^/      /' || true
_warn "dpkg Status:"
dpkg -l 'tigervnc*' 2>&1 | tail -10 | sed 's/^/      /' || true
_warn "Status File Permissions:"
ls -la /var/lib/dpkg/status* 2>&1 | sed 's/^/      /' || true
exit 1
BODY
    } > "${UMO_INSTALL_DIR:?}/root/install-vnc.sh"
    chmod +x "${UMO_INSTALL_DIR}/root/install-vnc.sh"
    if sh -n "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null; then
        umo_log_debug "install-vnc.sh syntax verified"
    else
        umo_log_warn "install-vnc.sh Has Syntax Issues"
    fi
    umo_log_run "Installing TigerVNC..."
    if [ ! -x "$UMO_LOGIN_SH" ]; then
        umo_log_warn "umo-login.sh Not Found/Executable - VNC Install Skipped"
        rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null || true
        return 0
    fi
    _rc=0
    if [ "${UMO_DEV_MODE:-0}" != "1" ]; then
        timeout 3600 "$UMO_LOGIN_SH" -c "bash /root/install-vnc.sh" </dev/null || _rc=$?
    fi
    if [ "$_rc" -eq 0 ]; then
        umo_log_ok "TigerVNC Installed"
    else
        umo_log_warn "TigerVNC Installation Encountered Errors (Code $_rc)"
    fi
    rm -f "${UMO_INSTALL_DIR}/root/install-vnc.sh" 2>/dev/null || true
    return 0
}

umo_vnc_configure() {
    umo_log_step "Configure VNC"

    _vnc_dir="${UMO_INSTALL_DIR}/root/.vnc"
    if ! mkdir -p "$_vnc_dir" 2>/dev/null; then
        umo_log_warn "Cannot Create $(umo_fs_display_path "$_vnc_dir") - VNC Configuration Skipped"
        return 0
    fi

    _template="$SCRIPT_DIR/config/xstartup"
    if [ -f "$_template" ]; then
        umo_fs_render "$_template" "$_vnc_dir/xstartup" \
            "UMO_DE" "${UMO_DE:-xfce4}" \
            "DISPLAY" "${UMO_VNC_DISPLAY:-:1}"
    else
        umo_log_warn "config/xstartup Template Missing - Writing Fallback Session"
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

    if [ -x "$UMO_LOGIN_SH" ]; then
        _pw_rc=0
        if command -v timeout >/dev/null 2>&1; then
            printf '%s\n' "$_vnc_pass" | timeout 120 "$UMO_LOGIN_SH" -c \
                'mkdir -p ~/.vnc && vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd' 2>/dev/null || _pw_rc=1
        else
            printf '%s\n' "$_vnc_pass" | "$UMO_LOGIN_SH" -c \
                'mkdir -p ~/.vnc && vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd' 2>/dev/null || _pw_rc=1
        fi
        if [ "$_pw_rc" -eq 0 ]; then
            cp -f "${UMO_INSTALL_DIR}/root/.vnc/passwd" "${UMO_INSTALL_DIR}/home/umo/.vnc/passwd" 2>/dev/null || true
            chmod 600 "${UMO_INSTALL_DIR}/home/umo/.vnc/passwd" 2>/dev/null || true
            chown -R 1000:1000 "${UMO_INSTALL_DIR}/home/umo/.vnc" 2>/dev/null || true
        else
            umo_log_warn "Could Not Set VNC Password (vncpasswd Not Available Yet)"
        fi
    fi

    umo_log_ok "VNC Configured"
    return 0
}

umo_vnc_create_scripts() {
    umo_log_step "Create VNC Scripts"

    if ! mkdir -p "${UMO_INSTALL_DIR}/usr/local/bin" 2>/dev/null; then
        umo_log_warn "Cannot Create /usr/local/bin - VNC Helper Scripts Skipped"
        return 0
    fi

    for _cscript in umo-startvnc umo-stopvnc umo-browser; do
        _src="$SCRIPT_DIR/config/container/$_cscript"
        if [ -f "$_src" ]; then
            cp -f "$_src" "${UMO_INSTALL_DIR}/usr/local/bin/$_cscript" 2>/dev/null || true
            chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/$_cscript" 2>/dev/null || true
        else
            umo_log_warn "Container Script Missing: $(umo_fs_display_path "$_src")"
        fi
    done

    _vnc_home="${UMO_SCRIPT_DIR:-$HOME/.umo}"
    mkdir -p "$_vnc_home" 2>/dev/null || _vnc_home="$HOME"
    _umo_login="${UMO_LOGIN_SH:-$_vnc_home/umo-login.sh}"

    cat > "$_vnc_home/umo-vnc-start.sh" << EOF
#!/bin/sh
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
sleep 1
exec "$_umo_login" -c "umo-startvnc"
EOF
    chmod +x "$_vnc_home/umo-vnc-start.sh"

    cat > "$_vnc_home/umo-vnc-stop.sh" << EOF
#!/bin/sh
exec "$_umo_login" -c "umo-stopvnc"
EOF
    chmod +x "$_vnc_home/umo-vnc-stop.sh"

    umo_log_ok "VNC Scripts Created ($(umo_fs_display_path "$_vnc_home"))"
}

umo_vnc_setup() {
    umo_vnc_install
    umo_vnc_configure
    umo_vnc_create_scripts
}
