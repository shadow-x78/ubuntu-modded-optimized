#!/bin/sh
# UMO - System & Platform Utilities (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

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
        umo_die "UMO must run inside Termux environment"
    fi
    umo_log_ok "Termux environment verified"
}

umo_sys_arch() {
    _arch=$(uname -m)
    case "$_arch" in
        aarch64|arm64) echo "aarch64" ;;
        armv7*|armhf)  echo "armhf" ;;
        *)             echo "$_arch" ;;
    esac
}

umo_sys_supported_archs() {
    printf '%s\n' aarch64
}

umo_sys_arch_supported() {
    _arch="$1"
    umo_sys_supported_archs | grep -qx "$_arch"
}

umo_sys_require_arch() {
    _detected=$(uname -m)
    _normalized=$(umo_sys_arch)

    if umo_sys_arch_supported "$_normalized"; then
        umo_log_ok "Architecture: $_normalized (detected: $_detected, supported)"
        return 0
    fi

    _supported_list=$(umo_sys_supported_archs | tr '\n' ' ' | sed 's/ $//')

    umo_log_err "Unsupported architecture: $_detected (normalized: $_normalized)"
    umo_log_err "  Supported: $_supported_list"
    umo_log_err "  Reason: aarch64 (ARM64) is the only architecture Termux"
    umo_log_err "          can run reliably with full Ubuntu proot; armhf"
    umo_log_err "          lacks modern Ubuntu packages and x86_64 hits"
    umo_log_err "          kernel-level ptrace blocking on Android."
    umo_log_err "  Fix:   Use a device with an ARM64 (aarch64) CPU."
    umo_log_err "         Nearly all phones and tablets from 2018 onward"
    umo_log_err "         are ARM64. Verify with: uname -m  (should print aarch64)"
    umo_die "Aborting because the host architecture is not supported."
}

umo_sys_disk_free_mb() {
    _path="${1:-$HOME}"
    _kb=$(df -k "$_path" 2>/dev/null | awk 'NR==2 {print $4}')
    [ -z "$_kb" ] && _kb=$(df "$_path" 2>/dev/null | awk 'NR==2 {print $4}')
    case "$_kb" in
        ''|*[!0-9]*) _kb=0 ;;
    esac
    echo "$((_kb / 1024))"
}

umo_sys_require_space() {
    _required_mb="${1:-2048}"
    _free_mb=$(umo_sys_disk_free_mb "$HOME")
    _free_gb=$((_free_mb / 1024))

    if [ "$_free_mb" -lt "$_required_mb" ]; then
        umo_die "Insufficient storage: ${_free_mb}MB free, ${_required_mb}MB required"
    fi
    umo_log_ok "Storage: ${_free_gb}GB available (${_required_mb}MB required)"
}

umo_sys_ram_mb() {
    if [ -f /proc/meminfo ]; then
        awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null
    else
        echo "0"
    fi
}

umo_sys_has_internet() {
    if command -v nslookup >/dev/null 2>&1; then
        nslookup ports.ubuntu.com >/dev/null 2>&1 && return 0
    fi
    if command -v getent >/dev/null 2>&1; then
        getent hosts ports.ubuntu.com >/dev/null 2>&1 && return 0
    fi
    wget -q --spider --timeout=6 https://ports.ubuntu.com 2>/dev/null && return 0
    curl -s --max-time 6 -o /dev/null https://ports.ubuntu.com 2>/dev/null && return 0
    ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1 && return 0
    return 1
}

umo_sys_require_internet() {
    if umo_sys_has_internet; then
        umo_log_ok "Internet connection verified"
    else
        umo_die "No internet connection. Please connect and retry"
    fi
}

umo_sys_has_cmd() {
    command -v "$1" >/dev/null 2>&1
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
