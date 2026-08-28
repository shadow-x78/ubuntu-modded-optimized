#!/bin/sh

[ -z "${_UMO_MOD_APPS_LOADED:-}" ] || return 0
_UMO_MOD_APPS_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_APP_SET="${UMO_APP_SET:-basic}"

umo_apps_basic() {
    umo_log_step "Install Base Utilities"
    _run_installer "Base utilities" '
_apt "Core Utilities" nano wget curl git htop man-db ca-certificates ncurses-term
_fetch_pkg="fastfetch"
apt-cache show fastfetch >> "$_LOG" 2>&1 || _fetch_pkg="neofetch"
if [ "$_fetch_pkg" = "neofetch" ]; then
    _warn "Fastfetch Unavailable On This Release - Installing Neofetch Instead"
fi
_apt "Fetch Tool" "$_fetch_pkg"
_apt "Archivers" zip unzip tar xz-utils bzip2 p7zip-full
_apt "Locales And Timezone Data" locales tzdata
locale-gen en_US.UTF-8 >> "$_LOG" 2>&1 || true
_apt "Text, Images And Archives" mousepad ristretto file-roller
_apt "Falkon Web Browser" falkon
_umo_harden_browser
if command -v falkon >/dev/null 2>&1; then
    _bv=$(dpkg-query -W falkon 2>/dev/null | head -1 | cut -f2)
    _ok "Browser Available: Falkon ${_bv:-installed}"
else
    _fail "Browser Missing: Falkon Failed To Install"
fi
' "nano git zip mousepad falkon htop fastfetch,neofetch"
}

umo_apps_browsers() {
    umo_log_step "Install Browsers"
    _run_installer "Browsers" '
_apt "Falkon Web Browser" falkon
_umo_harden_browser
if command -v falkon >/dev/null 2>&1; then
    _bv=$(dpkg-query -W falkon 2>/dev/null | head -1 | cut -f2)
    _ok "Browser Available: Falkon ${_bv:-installed}"
else
    _fail "Browser Missing: Falkon Failed To Install"
fi
' "falkon"
}

umo_apps_office() {
    umo_log_step "Install Office Suite"
    _run_installer "Office suite" '
_apt "LibreOffice (Writer, Calc, Impress)" libreoffice-writer libreoffice-calc libreoffice-impress
_apt "PDF Viewer And Fonts" atril fonts-liberation
' "libreoffice atril"
}

umo_apps_media() {
    umo_log_step "Install Media Tools"
    _run_installer "Media tools" '
_apt "VLC Media Player" vlc
_apt "FFmpeg" ffmpeg
_apt "MPV Player" mpv
_apt "Audacity Audio Editor" audacity
_apt "GIMP Image Editor" gimp
' "vlc ffmpeg mpv audacity gimp"
}

umo_apps_dev() {
    umo_log_step "Install Development Tools"
    _run_installer "Development tools" '
_apt "Python 3 (pip, venv, dev headers)" python3 python3-pip python3-venv python3-dev
_apt "Node.js And npm" nodejs npm
_apt "Build Toolchain (GCC, Make, CMake, GDB)" build-essential gcc g++ make cmake gdb pkg-config
_apt "Developer Utilities (vim, tmux, ssh, sqlite)" vim tmux openssh-client manpages-dev sqlite3
_apt "Geany Lightweight IDE" geany
_umo_setup_code_repo
_apt "Visual Studio Code (Microsoft Repo)" code
_umo_harden_code
' "python3 node npm gcc make cmake vim geany pkg-config code"
}

umo_apps_termux() {
    umo_log_step "Install Termux Integration"
    _run_installer "Termux integration" '
timeout 600 apt-get install -y termux-api >> "$_LOG" 2>&1 || true
_apt "Clipboard Tools" xclip xsel
' "xclip"
}

_run_installer() {
    _label="$1"
    _script_body="$2"
    _probes="$3"
    _script="${UMO_INSTALL_DIR:?}/root/install-apps.sh"
    {
        printf '%s\n' '#!/bin/sh'
        _umo_log_container_prelude
        printf '%s\n' 'export DEBIAN_FRONTEND=noninteractive LC_ALL=C LANG=C'
        printf '%s\n' '[ -t 0 ] && exec </dev/null'
        printf '%s\n' '_LOG=/root/install-apps.log'
        printf '%s\n' '_STATUS=/root/.umo-apps-status'
        printf '%s\n' 'printf "MISSING=probe-not-run\n" > "$_STATUS" 2>/dev/null || true'
        printf '%s\n' '_um_ts() { date "+%H:%M:%S" 2>/dev/null || echo "?"; }'
        printf '%s\n' "printf '\n===== [%s] %s =====\n' \"\$( _um_ts )\" \"$_label\" >> \"\$_LOG\" 2>/dev/null || true"
        printf '%s\n' '_apt() {'
        printf '%s\n' '    _lbl="$1"; shift'
        printf '%s\n' '    _step "Installing $_lbl..."'
        printf '%s\n' '    printf "[%s] group %s: %s\n" "$(_um_ts)" "$_lbl" "$*" >> "$_LOG" 2>/dev/null || true'
        printf '%s\n' '    _rcg=0'
        printf '%s\n' '    timeout 1800 apt-get install -y --no-install-recommends "$@" >> "$_LOG" 2>&1 || _rcg=$?'
        printf '%s\n' '    if [ "$_rcg" -ne 0 ]; then'
        printf '%s\n' '        printf "[%s] group %s failed (rc=%s), repairing and retrying once\n" "$(_um_ts)" "$_lbl" "$_rcg" >> "$_LOG" 2>/dev/null || true'
        printf '%s\n' '        dpkg --configure -a >> "$_LOG" 2>&1 || true'
        printf '%s\n' '        timeout 600 apt-get update >> "$_LOG" 2>&1 || true'
        printf '%s\n' '        _rcg=0'
        printf '%s\n' '        timeout 1800 apt-get install -y --no-install-recommends "$@" >> "$_LOG" 2>&1 || _rcg=$?'
        printf '%s\n' '    fi'
        printf '%s\n' '    if [ "$_rcg" -eq 0 ]; then'
        printf '%s\n' '        _ok "$_lbl Installed"'
        printf '%s\n' '    else'
        printf '%s\n' '        _fail "$_lbl Failed - Real Apt Errors:"'
        printf '%s\n' "        grep -E \"^(E:|Err:|W:)\" \"\$_LOG\" 2>/dev/null | awk '!_u[\$0]++' | tail -n 6 | sed 's/^/      /' || true"
        printf '%s\n' '    fi'
        printf '%s\n' '    return "$_rcg"'
        printf '%s\n' '}'
        printf '%s\n' '_umo_harden_browser() {'
        printf '%s\n' '    _fd=/usr/share/applications/org.kde.falkon.desktop'
        printf '%s\n' '    if [ -f "$_fd" ]; then'
        printf '%s\n' '        sed -i "0,/^Exec=/s|^Exec=.*|Exec=/usr/local/bin/umo-browser %U|" "$_fd" 2>/dev/null || true'
        printf '%s\n' '        sed -i "s|^DBusActivatable=.*|DBusActivatable=false|" "$_fd" 2>/dev/null || true'
        printf '%s\n' '    fi'
        printf '%s\n' '    _eph=/usr/share/applications/org.gnome.Epiphany.desktop'
        printf '%s\n' '    if [ -f "$_eph" ]; then'
        printf '%s\n' '        sed -i "s|^Exec=.*|Exec=/usr/local/bin/umo-browser %U|" "$_eph" 2>/dev/null || true'
        printf '%s\n' '        sed -i "s|^DBusActivatable=.*|DBusActivatable=false|" "$_eph" 2>/dev/null || true'
        printf '%s\n' '    fi'
        printf '%s\n' '    _svc=/usr/share/dbus-1/services/org.gnome.Epiphany.service'
        printf '%s\n' '    [ -f "$_svc" ] && mv -f "$_svc" "$_svc.umo-disabled" 2>/dev/null || true'
        printf '%s\n' '}'
        printf '%s\n' '_umo_setup_code_repo() {'
        printf '%s\n' '    _list=/etc/apt/sources.list.d/vscode.list'
        printf '%s\n' '    [ -f "$_list" ] && return 0'
        printf '%s\n' '    _key=/usr/share/keyrings/packages.microsoft.gpg'
        printf '%s\n' '    _asc=/tmp/packages.microsoft.asc'
        printf '%s\n' '    mkdir -p /usr/share/keyrings 2>/dev/null || true'
        printf '%s\n' '    if [ ! -s "$_key" ]; then'
        printf '%s\n' '        if command -v wget >/dev/null 2>&1; then'
        printf '%s\n' '            timeout 120 wget -qO "$_asc" https://packages.microsoft.com/keys/microsoft.asc >> "$_LOG" 2>&1 || true'
        printf '%s\n' '        elif command -v curl >/dev/null 2>&1; then'
        printf '%s\n' '            timeout 120 curl -fsSL -o "$_asc" https://packages.microsoft.com/keys/microsoft.asc >> "$_LOG" 2>&1 || true'
        printf '%s\n' '        fi'
        printf '%s\n' '        if [ -s "$_asc" ]; then'
        printf '%s\n' '            if command -v gpg >/dev/null 2>&1; then'
        printf '%s\n' '                gpg --dearmor < "$_asc" > "$_key" 2>> "$_LOG" || true'
        printf '%s\n' '            fi'
        printf '%s\n' '            [ -s "$_key" ] || grep -E "^[A-Za-z0-9+/]+={0,2}\$" "$_asc" 2>/dev/null | base64 -d > "$_key" 2>> "$_LOG" || true'
        printf '%s\n' '        fi'
        printf '%s\n' '        rm -f "$_asc" 2>/dev/null || true'
        printf '%s\n' '    fi'
        printf '%s\n' '    if [ -s "$_key" ]; then'
        printf '%s\n' '        printf "deb [arch=amd64,arm64,armhf signed-by=%s] https://packages.microsoft.com/repos/code stable main\n" "$_key" > "$_list" 2>>"$_LOG" || true'
        printf '%s\n' '        timeout 600 apt-get update >> "$_LOG" 2>&1 || true'
        printf '%s\n' '    fi'
        printf '%s\n' '    [ -f "$_list" ] || printf "[%s] VS Code repo unavailable - code will not install\n" "$(_um_ts)" >> "$_LOG" 2>/dev/null || true'
        printf '%s\n' '}'
        printf '%s\n' '_umo_harden_code() {'
        printf '%s\n' '    _cd=/usr/share/applications/code.desktop'
        printf '%s\n' '    if [ -f "$_cd" ]; then'
        printf '%s\n' '        sed -i "s|^Exec=.*|Exec=/usr/local/bin/umo-code %U|" "$_cd" 2>/dev/null || true'
        printf '%s\n' '    fi'
        printf '%s\n' '}'
        printf '%s\n' 'timeout 600 apt-get update >> "$_LOG" 2>&1 || true'
        printf '%s\n' 'dpkg --configure -a >> "$_LOG" 2>&1 || true'
        printf '%s\n' "$_script_body"
        printf '%s\n' '_missing=""'
        printf '%s\n' "for _b in $_probes; do"
        printf '%s\n' '    case "$_b" in'
        printf '%s\n' '        *,*)'
        printf '%s\n' '            _alt1="${_b%%,*}"; _alt2="${_b##*,}"'
        printf '%s\n' '            command -v "$_alt1" >/dev/null 2>&1 || command -v "$_alt2" >/dev/null 2>&1 || _missing="${_missing:+$_missing,}$_b"'
        printf '%s\n' '            ;;'
        printf '%s\n' '        *)'
        printf '%s\n' '            command -v "$_b" >/dev/null 2>&1 || _missing="${_missing:+$_missing,}$_b"'
        printf '%s\n' '            ;;'
        printf '%s\n' '    esac'
        printf '%s\n' 'done'
        printf '%s\n' 'if [ -n "$_missing" ]; then'
        printf '%s\n' '    printf "MISSING=%s\n" "$_missing" > "$_STATUS" 2>/dev/null || true'
        printf '%s\n' '    _fail "Set Result: Missing $_missing"'
        printf '%s\n' 'else'
        printf '%s\n' '    printf "OK\n" > "$_STATUS" 2>/dev/null || true'
        printf '%s\n' '    _ok "Set Result: All Probes Passed"'
        printf '%s\n' 'fi'
    } > "$_script"
    chmod +x "$_script"
    umo_log_run "Installing $_label..."
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-apps.sh" </dev/null || _rc=$?
    _status=$("$UMO_LOGIN_SH" -c "cat /root/.umo-apps-status 2>/dev/null" </dev/null 2>/dev/null || true)
    case "$_status" in
        OK)
            umo_log_ok "$_label Installed"
            ;;
        MISSING=*)
            umo_log_warn "$_label Finished, Missing Packages: ${_status#MISSING=}"
            umo_log_info "Diagnose: umo login -c \"tail -40 /root/install-apps.log\""
            ;;
        *)
            if [ "$_rc" -eq 0 ]; then
                umo_log_warn "$_label Finished With Warnings"
            else
                umo_log_warn "$_label Installation Failed (Code $_rc)"
                umo_log_info "Diagnose: umo login -c \"tail -40 /root/install-apps.log\""
            fi
            ;;
    esac
    mv -f "$_script" "${UMO_INSTALL_DIR}/root/install-apps.last.sh" 2>/dev/null || \
        rm -f "$_script" 2>/dev/null || true
}

_umo_deploy_browser_wrapper() {
    for _bw_name in umo-browser umo-code; do
        _bw_src="$SCRIPT_DIR/config/container/$_bw_name"
        _bw_dst="${UMO_INSTALL_DIR:?}/usr/local/bin/$_bw_name"
        if [ -f "$_bw_src" ]; then
            mkdir -p "$(dirname "$_bw_dst")" 2>/dev/null || true
            cp -f "$_bw_src" "$_bw_dst" 2>/dev/null || true
            chmod +x "$_bw_dst" 2>/dev/null || true
        fi
    done
}

_umo_apps_disk_check() {
    _ad_free_kb=$(df -Pk "$UMO_INSTALL_DIR" 2>/dev/null | awk 'NR==2{print $4}')
    [ -n "$_ad_free_kb" ] || return 0
    _ad_need_kb=1200000
    case "$UMO_APP_SET" in
        dev)    _ad_need_kb=3400000 ;;
        media)  _ad_need_kb=3600000 ;;
        office) _ad_need_kb=2800000 ;;
        full)   _ad_need_kb=7000000 ;;
    esac
    _ad_free_mb=$((_ad_free_kb / 1024))
    _ad_need_mb=$((_ad_need_kb / 1024))
    if [ "$_ad_free_kb" -lt "$_ad_need_kb" ] 2>/dev/null; then
        umo_log_warn "Low Disk Space (${_ad_free_mb}MB Free, ~${_ad_need_mb}MB Recommended For '$UMO_APP_SET') - Some Packages May Fail"
    fi
    return 0
}

umo_apps_install() {
    _umo_deploy_browser_wrapper
    _umo_apps_disk_check
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
            umo_log_info "Application Installation Disabled."
            return 0
            ;;
        *)
            umo_log_warn "Unknown App Set '$UMO_APP_SET', Using Basic"
            umo_apps_basic
            ;;
    esac
    umo_log_ok "Application Phase Complete"
}
