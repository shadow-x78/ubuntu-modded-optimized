#!/bin/sh
# UMO - Module: Application Sets (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_MOD_APPS_LOADED:-}" ] || return 0
_UMO_MOD_APPS_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_APP_SET="${UMO_APP_SET:-basic}"

umo_apps_basic() {
    umo_log_step "Install base utilities"
    _run_installer "Base utilities" "
apt-get install -y --no-install-recommends nano wget curl git htop man-db ca-certificates || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends fastfetch || apt-get install -y --no-install-recommends neofetch || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends zip unzip tar xz-utils bzip2 p7zip-full || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends locales tzdata || true
dpkg --configure -a || true
locale-gen en_US.UTF-8 || true
apt-get install -y --no-install-recommends mousepad ristretto file-roller || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends firefox-esr || true
dpkg --configure -a || true
"
}

umo_apps_browsers() {
    umo_log_step "Install browsers"
    _run_installer "Browsers" "
apt-get install -y --no-install-recommends firefox-esr || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends epiphany-browser || true
dpkg --configure -a || true
"
}

umo_apps_office() {
    umo_log_step "Install office suite"
    _run_installer "Office suite" "
apt-get install -y --no-install-recommends libreoffice-writer libreoffice-calc libreoffice-impress || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends atril fonts-liberation || true
dpkg --configure -a || true
"
}

umo_apps_media() {
    umo_log_step "Install media tools"
    _run_installer "Media tools" "
apt-get install -y --no-install-recommends vlc ffmpeg || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends mpv || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends audacity || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends gimp || true
dpkg --configure -a || true
"
}

umo_apps_dev() {
    umo_log_step "Install development tools"
    _run_installer "Development tools" "
apt-get install -y --no-install-recommends python3 python3-pip python3-venv || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends nodejs npm || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends build-essential gcc g++ make cmake gdb || true
dpkg --configure -a || true
apt-get install -y --no-install-recommends vim tmux openssh-client manpages-dev sqlite3 || true
dpkg --configure -a || true
"
}

umo_apps_termux() {
    umo_log_step "Install Termux integration"
    _run_installer "Termux integration" "
apt-get install -y termux-api 2>/dev/null || true
apt-get install -y --no-install-recommends xclip xsel || true
dpkg --configure -a || true
"
}

_run_installer() {
    _label="$1"
    _script_body="$2"
    _script="${UMO_INSTALL_DIR:?}/root/install-apps.sh"
    printf '#!/bin/sh\nexport DEBIAN_FRONTEND=noninteractive LC_ALL=C LANG=C\n[ -t 0 ] && exec </dev/null\n%s\n' "$_script_body" > "$_script"
    chmod +x "$_script"
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-apps.sh" </dev/null || _rc=$?
    if [ "$_rc" -eq 0 ]; then
        umo_log_ok "$_label installed"
    else
        umo_log_warn "$_label installation finished with warnings (code $_rc)"
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
        none)
            umo_log_info "Application installation disabled."
            return 0
            ;;
        *)
            umo_log_warn "Unknown app set '$UMO_APP_SET', using basic"
            umo_apps_basic
            ;;
    esac
    umo_log_ok "All applications installed"
}
