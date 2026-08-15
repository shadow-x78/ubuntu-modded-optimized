#!/bin/sh
# UMO - Desktop Environment Installer (GPL-3.0-or-later)
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

_umo_de_footer() {
    cat << 'FTR'
_um_apt_repair
FTR
}

_umo_de_build() {
    _pkgs_block="$1"
    {
        _umo_de_header
        printf '\n_um_apt_repair\n\n'
        printf '%s\n' "$_pkgs_block"
        printf '\n'
        _umo_de_footer
    } > "${UMO_INSTALL_DIR:?}/root/install-de.sh"
}

umo_de_lxde() {
    umo_log_step "Install LXDE (ultra-lightweight)"
    _umo_de_build 'timeout 600 apt-get install -y --no-install-recommends \
    lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf 2>&1 | _apt_filter || true'
    _run_de_installer "LXDE"
}

umo_de_xfce4() {
    umo_log_step "Install XFCE4 (professional set)"
    _pkgs='timeout 600 apt-get install -y --no-install-recommends \
    xfce4-panel xfce4-session xfce4-settings xfwm4 \
    xfce4-terminal thunar xfce4-screenshooter xfce4-taskmanager \
    mousepad dbus-x11 x11-xserver-utils gnome-icon-theme \
    xfce4-whiskermenu-plugin 2>&1 | _apt_filter || true'
    _umo_de_build "$_pkgs"
    _run_de_installer "XFCE4"
}

umo_de_openbox() {
    umo_log_step "Install Openbox (minimal)"
    _umo_de_build 'timeout 600 apt-get install -y --no-install-recommends \
    openbox obconf lxterminal pcmanfm tint2 feh 2>&1 | _apt_filter || true'
    _run_de_installer "Openbox"
}

umo_de_minimal() {
    umo_log_step "Install minimal X11"
    _umo_de_build 'timeout 600 apt-get install -y --no-install-recommends \
    xterm xfonts-base 2>&1 | _apt_filter || true'
    _run_de_installer "minimal X11"
}

_run_de_installer() {
    _label="$1"
    chmod +x "${UMO_INSTALL_DIR}/root/install-de.sh"
    printf "  %b>%b  Installing %s...\n" "$UMO_B_CYAN" "$UMO_NC" "$_label"
    "$HOME/umo-login.sh" -c "bash /root/install-de.sh"
    _rc=$?
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  %s installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_label"
    else
        printf "  %b%s%b  %s installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_label" "$_rc"
    fi
    rm -f "${UMO_INSTALL_DIR}/root/install-de.sh" 2>/dev/null || true
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
