#!/bin/sh
# UMO — Application Suite Installer (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_APPS_LOADED:-}" ] || return 0
_UMO_MOD_APPS_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_APP_SET="${UMO_APP_SET:-basic}"

umo_apps_basic() {
    umo_log_step "Installing base utilities..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq nano wget curl git htop neofetch man-db ca-certificates
apt-get install -y -qq zip unzip tar xz-utils
apt-get install -y -qq locales tzdata
locale-gen en_US.UTF-8
"
}

umo_apps_browsers() {
    umo_log_step "Installing browsers..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq firefox || apt-get install -y -qq firefox-esr || true
apt-get install -y -qq chromium-browser || apt-get install -y -qq chromium || true
"
}

umo_apps_office() {
    umo_log_step "Installing LibreOffice..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq libreoffice-writer libreoffice-calc libreoffice-impress
"
}

umo_apps_media() {
    umo_log_step "Installing media tools..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq vlc ffmpeg
"
}

umo_apps_dev() {
    umo_log_step "Installing development tools..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nodejs npm
apt-get install -y -qq build-essential gcc g++ make cmake
"
}

umo_apps_termux() {
    umo_log_step "Installing Termux integration..."
    _run_installer "
apt-get update -qq
apt-get install -y -qq termux-api 2>/dev/null || true
apt-get install -y -qq xclip xsel
"
}

_run_installer() {
    _script="${UMO_INSTALL_DIR:?}/tmp/install-apps.sh"
    printf '#!/bin/sh\n%s\n' "$1" > "$_script"
    chmod +x "$_script"
    "$HOME/umo-login.sh" -c "bash /tmp/install-apps.sh"
    rm -f "$_script"
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
    umo_log_ok "Application installation complete."
}
