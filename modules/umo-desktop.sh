#!/bin/sh

[ -z "${_UMO_MOD_DE_LOADED:-}" ] || return 0
_UMO_MOD_DE_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_DE="${UMO_DE:-xfce4}"

_umo_de_header() {
    printf '%s\n' '#!/bin/sh'
    _umo_log_container_prelude
    cat << 'HDR'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null
_LOG=/root/install-de.log

HDR
    _tz_area="${UMO_TZ%%/*}"
    _tz_zone="${UMO_TZ#*/}"
    [ -n "$_tz_area" ] || _tz_area="Etc"
    [ -n "$_tz_zone" ] || _tz_zone="UTC"
    printf 'echo "tzdata tzdata/Areas select %s" | debconf-set-selections 2>/dev/null || true\n' "$_tz_area"
    printf 'echo "tzdata tzdata/Zones/%s select %s" | debconf-set-selections 2>/dev/null || true\n' "$_tz_area" "$_tz_zone"
    printf '\n'
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
    _de_label="$3"
    {
        _umo_de_header
        cat << EOF

_step "Preparing $_de_label Package Database..."
_um_apt_repair >> "\$_LOG" 2>&1

_step "Updating Package Lists..."
apt-get update >> "\$_LOG" 2>&1 || true

_attempt=0
until command -v $_probe >/dev/null 2>&1 || [ "\$_attempt" -ge 3 ]; do
    _attempt=\$((_attempt + 1))
    _step "Installing $_de_label Packages (Attempt \$_attempt Of 3)..."
$_pkgs_block
    dpkg --configure -a >> "\$_LOG" 2>&1 || true
done

if ! command -v $_probe >/dev/null 2>&1; then
    _fail "$_de_label Install Failed - Real Apt Errors:"
    tail -n 30 /var/log/apt/term.log 2>/dev/null | sed 's/^/      /' || true
fi

_step "Finalizing $_de_label Package Database..."
_um_apt_repair >> "\$_LOG" 2>&1
EOF
    } > "${UMO_INSTALL_DIR:?}/root/install-de.sh"
}

umo_de_lxde() {
    umo_log_step "Install LXDE (Ultra-Lightweight)"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf xdg-utils >> "$_LOG" 2>&1 || true' startlxde LXDE
    _run_de_installer "LXDE" startlxde \
        "apt-get update && apt-get install -y --no-install-recommends lxde-core lxde-common lxsession lxterminal pcmanfm openbox obconf xdg-utils"
}

umo_de_xfce4() {
    umo_log_step "Install XFCE4 (Professional Set)"
    _pkgs='timeout 1800 apt-get install -y --no-install-recommends \
    xfce4-panel xfce4-session xfce4-settings xfwm4 xfdesktop4 \
    xfce4-terminal thunar xfce4-screenshooter xfce4-taskmanager \
    mousepad dbus-x11 x11-xserver-utils gnome-icon-theme \
    xfce4-whiskermenu-plugin plank xdg-utils >> "$_LOG" 2>&1 || true'
    _umo_de_build "$_pkgs" startxfce4 XFCE4
    _run_de_installer "XFCE4" startxfce4 \
        "apt-get update && apt-get install -y --no-install-recommends xfce4-panel xfce4-session xfce4-settings xfwm4 xfdesktop4 xfce4-terminal thunar dbus-x11 x11-xserver-utils plank xdg-utils"
}

umo_de_openbox() {
    umo_log_step "Install Openbox (Minimal)"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    openbox obconf lxterminal pcmanfm tint2 feh exo-utils xdg-utils >> "$_LOG" 2>&1 || true' openbox-session Openbox
    _run_de_installer "Openbox" openbox-session \
        "apt-get update && apt-get install -y --no-install-recommends openbox obconf lxterminal pcmanfm tint2 feh exo-utils xdg-utils"
}

umo_de_minimal() {
    umo_log_step "Install Minimal X11"
    _umo_de_build 'timeout 1800 apt-get install -y --no-install-recommends \
    xterm xfonts-base >> "$_LOG" 2>&1 || true' xterm "Minimal X11"
    _run_de_installer "Minimal X11" xterm \
        "apt-get update && apt-get install -y --no-install-recommends xterm xfonts-base"
}

_run_de_installer() {
    _label="$1"
    _probe="$2"
    _repair="$3"
    chmod +x "${UMO_INSTALL_DIR}/root/install-de.sh"
    umo_log_run "Installing $_label..."
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-de.sh" </dev/null || _rc=$?
    if [ "$_rc" -eq 0 ]; then
        umo_log_ok "$_label Installed"
    else
        umo_log_warn "$_label Installation Encountered Errors (Code $_rc)"
    fi
    if [ -n "$_probe" ] && ! "$UMO_LOGIN_SH" -c "command -v $_probe >/dev/null 2>&1"; then
        printf "\n"
        umo_log_err "CRITICAL: $_label Core Component '$_probe' Missing - Desktop Would Be Empty"
        umo_log_info "Evidence Kept In-Container: /root/install-de.log, /root/install-de.last.sh"
        umo_log_info "Real Apt Errors: umo login -c \"tail -n 30 /var/log/apt/term.log\""
        umo_log_info "Repair Inside The Container: umo login, then: $_repair, then: umo stop && umo start"
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
            umo_log_warn "Unknown DE '$UMO_DE', Using XFCE4"
            umo_de_xfce4
            ;;
    esac
}
