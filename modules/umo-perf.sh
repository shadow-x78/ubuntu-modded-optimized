#!/bin/sh
# UMO — Performance Optimizer (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_PERF_LOADED:-}" ] || return 0
_UMO_MOD_PERF_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_PERF_MODE="${UMO_PERF_MODE:-balanced}"

umo_perf_apt() {
    umo_log_step "Optimize APT configuration"

    _apt_conf="/etc/apt/apt.conf.d/99umo-speed"
    _template="$SCRIPT_DIR/config/templates/apt-umo-speed.conf"
    if [ -f "$_template" ]; then
        cp -f "$_template" "${UMO_INSTALL_DIR:?}$_apt_conf" 2>/dev/null || true
    else
        cat > "${UMO_INSTALL_DIR:?}$_apt_conf" << 'EOC'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::Retries "3";
Acquire::http::Timeout "60";
Acquire::https::Timeout "60";
Acquire::Languages "none";
Acquire::Queue-Mode "host";
EOC
    fi

    if command -v eatmydata >/dev/null 2>&1; then
        _apt_cmd="eatmydata apt-get"
    else
        _apt_cmd="apt-get"
    fi

    if [ "$UMO_PERF_MODE" = "aggressive" ]; then
        printf '%s\n' 'APT::Get::Assume-Yes "true";' >> "${UMO_INSTALL_DIR:?}$_apt_conf"
    fi

    cat > "$UMO_INSTALL_DIR/root/divert-triggers.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

if command -v debconf-set-selections >/dev/null 2>&1; then
    echo "man-db man-db/auto-update boolean false" | debconf-set-selections 2>/dev/null || true
fi

for _bin in gtk-update-icon-cache update-initramfs systemd-hwdb update-command-not-found update-mime-database update-desktop-database; do
    if [ -e "/usr/bin/$_bin" ] && [ ! -L "/usr/bin/$_bin" ]; then
        dpkg-divert --local --rename --add "/usr/bin/$_bin" 2>/dev/null || true
        ln -sf /bin/true "/usr/bin/$_bin"
    elif [ -e "/usr/sbin/$_bin" ] && [ ! -L "/usr/sbin/$_bin" ]; then
        dpkg-divert --local --rename --add "/usr/sbin/$_bin" 2>/dev/null || true
        ln -sf /bin/true "/usr/sbin/$_bin"
    fi
done
INNER
    chmod +x "$UMO_INSTALL_DIR/root/divert-triggers.sh"
    "$HOME/umo-login.sh" -c "bash /root/divert-triggers.sh" >/dev/null 2>&1
    rm -f "$UMO_INSTALL_DIR/root/divert-triggers.sh"

    umo_log_ok "APT configured (mode: $UMO_PERF_MODE)."
}

umo_perf_debloat() {
    umo_log_step "Remove unnecessary services"

    _bloat="snapd unattended-upgrades apport ModemManager modemmanager cups cups-browsed avahi-daemon"

    cat > "$UMO_INSTALL_DIR/root/debloat.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get purge -y --auto-remove $_bloat 2>/dev/null || true
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -y
apt-get install -y ubuntu-keyring 2>/dev/null || true
dpkg --configure -a || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/debloat.sh"
    umo_run_quiet "Purging bloat packages..." "$HOME/umo-login.sh" -c "bash /root/debloat.sh"
    rm -f "$UMO_INSTALL_DIR/root/debloat.sh"

    umo_log_ok "Debloating completed."
}

umo_perf_dns() {
    umo_log_step "Harden DNS configuration"

    _resolv="$UMO_INSTALL_DIR/etc/resolv.conf"
    cat > "$_resolv" << 'EOR'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
options timeout:2 attempts:3
EOR

    chattr +i "$_resolv" 2>/dev/null || true

    umo_log_ok "DNS configured (Cloudflare + Google + Quad9)."
}

umo_perf_cleanup() {
    umo_log_step "Clean up"

    cat > "$UMO_INSTALL_DIR/root/cleanup.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -qq || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/cleanup.sh"
    umo_run_quiet "Running APT cleanup..." "$HOME/umo-login.sh" -c "bash /root/cleanup.sh"
    rm -f "$UMO_INSTALL_DIR/root/cleanup.sh"

    if [ "${UMO_LEAN:-0}" = "1" ]; then
        umo_log_step "Remove documentation and locale data (--lean)"
        rm -rf "$UMO_INSTALL_DIR/usr/share/doc" 2>/dev/null || true
        rm -rf "$UMO_INSTALL_DIR/usr/share/man" 2>/dev/null || true
        rm -rf "$UMO_INSTALL_DIR/usr/share/locale" 2>/dev/null || true
    fi

    umo_log_ok "Cleanup complete."
}

umo_perf_gpu() {
    umo_log_step "Configure GPU rendering"

    umo_fs_patch "$UMO_INSTALL_DIR/root/.bashrc" "# ===== UMO GPU =====" '
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.0
export MESA_GLES_VERSION_OVERRIDE=3.2
export LIBGL_ALWAYS_SOFTWARE=0
'

    if [ -f "$UMO_INSTALL_DIR/home/umo/.bashrc" ]; then
        umo_fs_patch "$UMO_INSTALL_DIR/home/umo/.bashrc" "# ===== UMO GPU =====" '
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.0
export MESA_GLES_VERSION_OVERRIDE=3.2
export LIBGL_ALWAYS_SOFTWARE=0
'
    fi

    umo_log_ok "GPU rendering configured."
}

umo_perf_vnc() {
    umo_log_step "Tune VNC performance"

    if [ "$UMO_PERF_MODE" = "aggressive" ]; then
        export UMO_VNC_DEPTH=16
    fi

    _xfce_settings="$UMO_INSTALL_DIR/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
    if [ -f "$_xfce_settings" ]; then
        sed -i 's|use_compositing" type="bool" value="true"|use_compositing" type="bool" value="false"|g' "$_xfce_settings" 2>/dev/null || true
    fi

    umo_log_ok "VNC tuned."
}

umo_perf_desktop() {
    umo_log_step "Optimize desktop environment"

    cat > "$UMO_INSTALL_DIR/root/perf-desktop.sh" << 'INNER'
#!/bin/sh
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false 2>/dev/null || true
xfconf-query -c thunar-volman -p /automount-drives/enabled -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/theme_animation -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/perf-desktop.sh"
    umo_run_quiet "Applying desktop tweaks..." "$HOME/umo-login.sh" -c "bash /root/perf-desktop.sh"
    rm -f "$UMO_INSTALL_DIR/root/perf-desktop.sh"

    umo_log_ok "Desktop optimizations applied."
}

umo_perf_setup() {
    umo_log_step "Apply performance tuning (mode: $UMO_PERF_MODE)"

    umo_perf_apt
    umo_perf_dns
    umo_perf_debloat
    umo_perf_cleanup

    if [ "$UMO_DE" != "minimal" ]; then
        umo_perf_gpu
        umo_perf_vnc
        umo_perf_desktop
    fi

    umo_log_ok "Performance optimizations complete."
}
