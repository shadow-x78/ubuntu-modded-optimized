#!/bin/sh
# UMO — Performance Optimizer (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_PERF_LOADED:-}" ] || return 0
_UMO_MOD_PERF_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_PERF_MODE="${UMO_PERF_MODE:-balanced}"

umo_perf_apt() {
    umo_log_step "Optimizing APT configuration..."

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

    umo_log_ok "APT configured (mode: $UMO_PERF_MODE)."
}

umo_perf_swap() {
    _size="${1:-512M}"
    [ "$UMO_PERF_MODE" = "aggressive" ] && _size="1G"
    _swapfile="${UMO_INSTALL_DIR:?}/swapfile"

    umo_log_step "Setting up swap ($_size)..."

    if [ -f "$_swapfile" ]; then
        umo_log_info "Swap file already exists, skipping."
        return 0
    fi

    _swap_count="${_size%[MG]}"
    case "$_size" in *[Gg]) _swap_count=$((_swap_count * 1024)) ;; esac
    fallocate -l "$_size" "$_swapfile" 2>/dev/null || \
        dd if=/dev/zero of="$_swapfile" bs=1M count="$_swap_count" 2>/dev/null || {
        umo_log_warn "Cannot create swapfile (proot limitation — skipping)."
        return 0
    }

    chmod 600 "$_swapfile"
    mkswap "$_swapfile" >/dev/null 2>&1

    if swapon "$_swapfile" 2>/dev/null; then
        umo_log_ok "Swap enabled: $_size"
    else
        umo_log_warn "swapon failed (best-effort inside proot)."
    fi

    grep -q "$_swapfile" "$UMO_INSTALL_DIR/etc/fstab" 2>/dev/null || \
        echo "$_swapfile none swap sw 0 0" >> "$UMO_INSTALL_DIR/etc/fstab"

    _conf="$UMO_INSTALL_DIR/etc/sysctl.conf"
    grep -q "vm.swappiness" "$_conf" 2>/dev/null || \
        printf 'vm.swappiness=10\nvm.vfs_cache_pressure=50\n' >> "$_conf" 2>/dev/null || true
}

umo_perf_debloat() {
    umo_log_step "Removing unnecessary services..."

    _bloat="snapd unattended-upgrades apport ModemManager modemmanager cups cups-browsed avahi-daemon"

    cat > "$UMO_INSTALL_DIR/tmp/debloat.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get purge -y --auto-remove $_bloat 2>/dev/null || true
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -qq
INNER
    chmod +x "$UMO_INSTALL_DIR/tmp/debloat.sh"
    "$HOME/umo-login.sh" -c "bash /tmp/debloat.sh" 2>/dev/null || true
    rm -f "$UMO_INSTALL_DIR/tmp/debloat.sh"

    umo_log_ok "Debloating completed."
}

umo_perf_dns() {
    umo_log_step "Hardening DNS configuration..."

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
    umo_log_step "Cleaning up..."

    cat > "$UMO_INSTALL_DIR/tmp/cleanup.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -qq
INNER
    chmod +x "$UMO_INSTALL_DIR/tmp/cleanup.sh"
    "$HOME/umo-login.sh" -c "bash /tmp/cleanup.sh" 2>/dev/null || true
    rm -f "$UMO_INSTALL_DIR/tmp/cleanup.sh"

    if [ "${UMO_LEAN:-0}" = "1" ]; then
        umo_log_step "Removing documentation and locale data (--lean)..."
        rm -rf "$UMO_INSTALL_DIR/usr/share/doc" 2>/dev/null || true
        rm -rf "$UMO_INSTALL_DIR/usr/share/man" 2>/dev/null || true
        rm -rf "$UMO_INSTALL_DIR/usr/share/locale" 2>/dev/null || true
    fi

    umo_log_ok "Cleanup complete."
}

umo_perf_gpu() {
    umo_log_step "Configuring GPU rendering..."

    umo_fs_patch "$UMO_INSTALL_DIR/root/.bashrc" "# ===== UMO GPU =====" '
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.0
export MESA_GLES_VERSION_OVERRIDE=3.2
export LIBGL_ALWAYS_SOFTWARE=0
'

    if [ -f "$UMO_INSTALL_DIR/home/ubuntu/.bashrc" ]; then
        umo_fs_patch "$UMO_INSTALL_DIR/home/ubuntu/.bashrc" "# ===== UMO GPU =====" '
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.0
export MESA_GLES_VERSION_OVERRIDE=3.2
export LIBGL_ALWAYS_SOFTWARE=0
'
    fi

    umo_log_ok "GPU rendering configured."
}

umo_perf_vnc() {
    umo_log_step "Tuning VNC performance..."

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
    umo_log_step "Optimizing desktop environment..."

    cat > "$UMO_INSTALL_DIR/tmp/perf-desktop.sh" << 'INNER'
#!/bin/sh
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false 2>/dev/null || true
xfconf-query -c thunar-volman -p /automount-drives/enabled -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/theme_animation -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
INNER
    chmod +x "$UMO_INSTALL_DIR/tmp/perf-desktop.sh"
    "$HOME/umo-login.sh" -c "bash /tmp/perf-desktop.sh" 2>/dev/null || true
    rm -f "$UMO_INSTALL_DIR/tmp/perf-desktop.sh"

    umo_log_ok "Desktop optimizations applied."
}

umo_perf_setup() {
    umo_log_step "Applying performance tuning (mode: $UMO_PERF_MODE)..."

    umo_perf_apt
    umo_perf_dns
    umo_perf_swap
    umo_perf_debloat
    umo_perf_cleanup

    if [ "$UMO_DE" != "minimal" ]; then
        umo_perf_gpu
        umo_perf_vnc
        umo_perf_desktop
    fi

    umo_log_ok "Performance optimizations complete."
}