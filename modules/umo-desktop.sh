#!/bin/sh
# UMO - Module: Desktop Environment Installs (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_MOD_DE_LOADED:-}" ] || return 0
_UMO_MOD_DE_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_DE="${UMO_DE:-xfce4}"

_umo_de_header() {
    cat << 'HDR'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null

echo "tzdata tzdata/Areas select Etc" | debconf-set-selections 2>/dev/null || true
echo "tzdata tzdata/Zones/Etc select UTC" | debconf-set-selections 2>/dev/null || true

HDR
    cat << 'REPAIR'
_um_apt_repair() {
    dpkg --configure -a || true
    timeout 900 apt-get -f install -y || true
    dpkg --configure -a || true
    _broken=$(dpkg -l 2>/dev/null | awk '/^iU|^iF|^hF/{print $2}')
    if [ -n "$_broken" ]; then
        timeout 900 apt-get install -y --reinstall $_broken || true
        dpkg --configure -a || true
    fi
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

_umo_de_build() {
    _pkgs_block="$1"
    _probe="$2"
    {
        _umo_de_header
        cat << EOF

_um_apt_repair

apt-get update || true

_attempt=0
until command -v $_probe >/dev/null 2>&1 || [ "\$_attempt" -ge 3 ]; do
    _attempt=\$((_attempt + 1))
$_pkgs_block
    dpkg --configure -a || true
done

if ! command -v $_probe >/dev/null 2>&1; then
    echo "=== DESKTOP INSTALL FAILED - real apt errors: ==="
    tail -n 30 /var/log/apt/term.log 2>/dev/null || true
fi

_um_apt_repair
EOF
    } > "${UMO_INSTALL_DIR:?}/root/install-de.sh"
}

umo_de_lxde() {
    umo_log_step "Install LXDE (ultra-lightweight)"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf || true' startlxde
    _run_de_installer "LXDE" startlxde \
        "apt-get update && apt-get install -y --no-install-recommends lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf"
}

umo_de_xfce4() {
    umo_log_step "Install XFCE4 (professional set)"
    _pkgs='timeout 1800 apt-get install -y --no-install-recommends \
    xfce4-panel xfce4-session xfce4-settings xfwm4 xfdesktop4 \
    xfce4-terminal thunar xfce4-screenshooter xfce4-taskmanager \
    mousepad dbus-x11 x11-xserver-utils gnome-icon-theme \
    xfce4-whiskermenu-plugin || true'
    _umo_de_build "$_pkgs" startxfce4
    _run_de_installer "XFCE4" startxfce4 \
        "apt-get update && apt-get install -y --no-install-recommends xfce4-panel xfce4-session xfce4-settings xfwm4 xfdesktop4 xfce4-terminal thunar dbus-x11 x11-xserver-utils"
}

umo_de_openbox() {
    umo_log_step "Install Openbox (minimal)"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    openbox obconf lxterminal pcmanfm tint2 feh exo-utils || true' openbox-session
    _run_de_installer "Openbox" openbox-session \
        "apt-get update && apt-get install -y --no-install-recommends openbox obconf lxterminal pcmanfm tint2 feh exo-utils"
}

umo_de_minimal() {
    umo_log_step "Install minimal X11"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    xterm xfonts-base || true' xterm
    _run_de_installer "minimal X11" xterm \
        "apt-get update && apt-get install -y --no-install-recommends xterm xfonts-base"
}

_run_de_installer() {
    _label="$1"
    _probe="$2"
    _repair="$3"
    chmod +x "${UMO_INSTALL_DIR}/root/install-de.sh"
    printf "  %b>%b  Installing %s...\n" "$UMO_B_CYAN" "$UMO_NC" "$_label"
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-de.sh 2>&1 | tee /root/install-de.log; exit \${PIPESTATUS[0]}" || _rc=$?
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  %s installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_label"
    else
        printf "  %b%s%b  %s installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_label" "$_rc"
    fi
    if [ -n "$_probe" ] && ! "$UMO_LOGIN_SH" -c "command -v $_probe >/dev/null 2>&1"; then
        printf "\n"
        printf "  %b%s%b  CRITICAL: %s core component '%s' is MISSING - desktop would be EMPTY.\n" \
            "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_label" "$_probe"
        printf "         Evidence kept in-container:\n"
        printf "           /root/install-de.log  /root/install-de.last.sh\n"
        printf "         Real apt errors:\n"
        printf "           umo login -c \"tail -n 30 /var/log/apt/term.log\"\n"
        printf "         Repair inside the container:\n"
        printf "           umo login\n"
        printf "           %s\n" "$_repair"
        printf "         Then: umo stop && umo start\n\n"
    fi
    mv -f "${UMO_INSTALL_DIR}/root/install-de.sh" "${UMO_INSTALL_DIR}/root/install-de.last.sh" 2>/dev/null || true
}

umo_de_install() {
    case "$UMO_DE" in
        lxde)      umo_de_lxde ;;
        xfce4|xfce) umo_de_xfce4 ;;
        openbox)   umo_de_openbox ;;
        minimal)   umo_de_minimal ;;
        *)
            umo_log_warn "Unknown DE '$UMO_DE', using XFCE4"
            umo_de_xfce4
            ;;
    esac
}
