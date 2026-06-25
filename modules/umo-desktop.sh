#!/bin/sh
# UMO — Desktop Environment Installer (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_DE_LOADED:-}" ] || return 0
_UMO_MOD_DE_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_DE="${UMO_DE:-xfce4}"

umo_de_lxde() {
    umo_log_step "Install LXDE (ultra-lightweight)"
    cat > "${UMO_INSTALL_DIR:?}/root/install-de.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get install -y lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf || true
dpkg --configure -a || true
INNER
    _run_de_installer "LXDE"
}

umo_de_xfce4() {
    umo_log_step "Install XFCE4 (recommended)"
    cat > "${UMO_INSTALL_DIR:?}/root/install-de.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get install -y xfce4 xfce4-goodies xfce4-terminal thunar dbus-x11 || true
apt-get install -y xubuntu-icon-theme xfce4-whiskermenu-plugin || true
dpkg --configure -a || true
INNER
    _run_de_installer "XFCE4"
}

umo_de_openbox() {
    umo_log_step "Install Openbox (minimal)"
    cat > "${UMO_INSTALL_DIR:?}/root/install-de.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get install -y openbox obconf lxterminal pcmanfm tint2 feh || true
dpkg --configure -a || true
INNER
    _run_de_installer "Openbox"
}

umo_de_minimal() {
    umo_log_step "Install minimal X11"
    cat > "${UMO_INSTALL_DIR:?}/root/install-de.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get install -y xterm xfonts-base || true
dpkg --configure -a || true
INNER
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
