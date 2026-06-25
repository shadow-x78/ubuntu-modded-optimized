#!/bin/sh
# UMO — Application Suite Installer (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_APPS_LOADED:-}" ] || return 0
_UMO_MOD_APPS_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_APP_SET="${UMO_APP_SET:-basic}"

umo_apps_basic() {
    umo_log_step "Install base utilities"
    _run_installer "Base utilities" "
apt-get install -y nano wget curl git htop neofetch man-db ca-certificates || true
dpkg --configure -a || true
apt-get install -y zip unzip tar xz-utils || true
dpkg --configure -a || true
apt-get install -y locales tzdata || true
dpkg --configure -a || true
locale-gen en_US.UTF-8 || true
"
}

umo_apps_browsers() {
    umo_log_step "Install browsers"
    _run_installer "Browsers" "
apt-get install -y firefox-esr || true
dpkg --configure -a || true
"
}

umo_apps_office() {
    umo_log_step "Install LibreOffice"
    _run_installer "LibreOffice" "
apt-get install -y libreoffice-writer libreoffice-calc libreoffice-impress || true
dpkg --configure -a || true
"
}

umo_apps_media() {
    umo_log_step "Install media tools"
    _run_installer "Media tools" "
apt-get install -y vlc ffmpeg || true
dpkg --configure -a || true
"
}

umo_apps_dev() {
    umo_log_step "Install development tools"
    _run_installer "Development tools" "
apt-get install -y python3 python3-pip python3-venv nodejs npm || true
apt-get install -y build-essential gcc g++ make cmake || true
dpkg --configure -a || true
"
}

umo_apps_termux() {
    umo_log_step "Install Termux integration"
    _run_installer "Termux integration" "
apt-get install -y termux-api 2>/dev/null || true
apt-get install -y xclip xsel || true
dpkg --configure -a || true
"
}

_run_installer() {
    _label="$1"
    _script_body="$2"
    _script="${UMO_INSTALL_DIR:?}/root/install-apps.sh"
    printf '#!/bin/sh\nexport DEBIAN_FRONTEND=noninteractive\n%s\n' "$_script_body" > "$_script"
    chmod +x "$_script"
    printf "  %b>%b  Installing %s...\n" "$UMO_B_CYAN" "$UMO_NC" "$_label"
    "$HOME/umo-login.sh" -c "bash /root/install-apps.sh"
    _rc=$?
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  %s installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_label"
    else
        printf "  %b%s%b  %s installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_label" "$_rc"
    fi
    rm -f "$_script" 2>/dev/null || true
}

umo_apps_install() {
    case "$UMO_APP_SET" in
        basic)   umo_apps_basic ;;
        dev)     umo_apps_basic; umo_apps_dev ;;
        media)   umo_apps_basic; umo_apps_media ;;
        browser) umo_apps_basic; umo_apps_browsers ;;
        office)  umo_apps_basic; umo_apps_office ;;
        full)
            umo_apps_basic
            umo_apps_browsers
            umo_apps_office
            umo_apps_media
            umo_apps_dev
            umo_apps_termux
            ;;
        *)
            umo_log_warn "Unknown app set '$UMO_APP_SET', using basic"
            umo_apps_basic
            ;;
    esac
    umo_log_ok "All applications installed"
}
