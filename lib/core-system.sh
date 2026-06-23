#!/bin/sh
# UMO — System & Platform Utilities (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_SYS_LOADED:-}" ] || return 0
_UMO_SYS_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_sys_is_termux() {
    [ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] && return 0
    [ -d "/data/data/com.termux" ] && return 0
    return 1
}

umo_sys_require_termux() {
    if ! umo_sys_is_termux; then
        umo_die "UMO must run inside Termux environment."
    fi
    umo_log_ok "Termux environment verified."
}

umo_sys_arch() {
    _arch=$(uname -m)
    case "$_arch" in
        aarch64|arm64) echo "aarch64" ;;
        armv7*|armhf)  echo "armhf" ;;
        *)             echo "$_arch" ;;
    esac
}

umo_sys_require_arch() {
    _current=$(umo_sys_arch)
    case "$_current" in
        aarch64) umo_log_ok "Architecture: $_current (supported)" ;;
        *)       umo_die "Unsupported architecture: $_current. UMO requires an ARM64 (aarch64) device." ;;
    esac
}

umo_sys_disk_free_mb() {
    _path="${1:-$HOME}"
    _kb=$(df -k "$_path" 2>/dev/null | awk 'NR==2 {print $4}')
    [ -z "$_kb" ] && _kb=$(df "$_path" 2>/dev/null | awk 'NR==2 {print $4}')
    echo "$((_kb / 1024))"
}

umo_sys_require_space() {
    _required_mb="${1:-2048}"
    _free_mb=$(umo_sys_disk_free_mb "$HOME")
    _free_gb=$((_free_mb / 1024))

    if [ "$_free_mb" -lt "$_required_mb" ]; then
        umo_die "Insufficient storage: ${_free_mb}MB free, ${_required_mb}MB required."
    fi
    umo_log_ok "Storage: ${_free_gb}GB available (${_required_mb}MB required)."
}

umo_sys_ram_mb() {
    if [ -f /proc/meminfo ]; then
        awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null
    else
        echo "0"
    fi
}

umo_sys_has_internet() {
    wget -q --spider --timeout=5 http://google.com 2>/dev/null && return 0
    curl -s --max-time 5 http://google.com >/dev/null 2>&1 && return 0
    ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && return 0
    return 1
}

umo_sys_require_internet() {
    umo_log_info "Checking internet connectivity..."
    if umo_sys_has_internet; then
        umo_log_ok "Internet connection verified."
    else
        umo_die "No internet connection. Please connect and retry."
    fi
}

umo_sys_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

umo_sys_require_cmd() {
    _cmd="$1"
    _pkg="${2:-$_cmd}"
    if ! umo_sys_has_cmd "$_cmd"; then
        umo_log_warn "Missing: $_cmd. Attempting to install $_pkg..."
        pkg install -y "$_pkg" 2>/dev/null || \
        apt-get install -y "$_pkg" 2>/dev/null || \
        umo_die "Failed to install $_pkg."
    fi
}

umo_sys_pkg_install() {
    [ $# -eq 0 ] && return 0
    if command -v pkg >/dev/null 2>&1; then
        umo_run_quiet "Installing dependencies" pkg install -y "$@" || true
    else
        umo_run_quiet "Installing dependencies" apt-get install -y "$@" || true
    fi
}

umo_sys_kill_by_name() {
    for _name in "$@"; do
        for _pid in $(pgrep -x "$_name" 2>/dev/null || true); do
            kill -9 "$_pid" 2>/dev/null || true
        done
    done
}

umo_sys_is_running() {
    pgrep -x "$1" >/dev/null 2>&1
}

umo_sys_setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        umo_log_warn "Storage not configured. Running termux-setup-storage..."
        termux-setup-storage || true
    fi
}

umo_sys_summary() {
    _platform="Termux"
    if command -v termux-info >/dev/null 2>&1; then
        _ver=$(termux-info 2>/dev/null | grep '^TERMUX_APK_RELEASE=' | head -1)
        [ -z "$_ver" ] && _ver=$(termux-info 2>/dev/null | grep '^TERMUX_VERSION=' | head -1)
        _platform="Termux (${_ver:-Unknown})"
    fi
    _arch=$(umo_sys_arch)
    _store=$(umo_sys_disk_free_mb)
    _ram=$(umo_sys_ram_mb)
    _dir="${UMO_INSTALL_DIR:-$HOME/umo-ubuntu}"

    _plen=$(printf '%s' "$_platform" | wc -m)
    [ "$_plen" -gt 28 ] && _platform="Termux"

    umo_ui_header "System Summary"
    umo_kv "Platform" "$_platform"
    umo_kv "Arch"     "$_arch"
    umo_kv "Storage"  "${_store}MB free"
    umo_kv "RAM"      "${_ram}MB available"
    umo_kv "Path"     "$_dir"
}
