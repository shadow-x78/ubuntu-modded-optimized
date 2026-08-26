#!/bin/sh
# UMO - Module: PulseAudio Bridge (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_MOD_AUDIO_LOADED:-}" ] || return 0
_UMO_MOD_AUDIO_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

umo_audio_install_termux() {
    umo_log_step "Install PulseAudio In Termux"

    if ! command -v pulseaudio >/dev/null 2>&1; then
        pkg install -y pulseaudio 2>/dev/null || \
        apt-get install -y pulseaudio 2>/dev/null || \
        umo_log_warn "Could Not Auto-Install PulseAudio"
    fi

    umo_log_ok "PulseAudio Ready"
}

umo_audio_configure() {
    umo_log_step "Configure PulseAudio Bridge"

    if ! mkdir -p "$UMO_TERMUX_PREFIX/etc/pulse" 2>/dev/null; then
        umo_log_warn "Cannot Write PulseAudio Config Dir"
        return 0
    fi
    _pa_config="$UMO_TERMUX_PREFIX/etc/pulse/default.pa"

    if [ -f "$_pa_config" ] && ! grep -q "UMO Audio" "$_pa_config" 2>/dev/null; then
        cat >> "$_pa_config" << 'EOF'

# UMO Audio bridge (localhost only)
load-module module-native-protocol-tcp listen=127.0.0.1 auth-anonymous=1
EOF
    fi

    mkdir -p "$UMO_TERMUX_PREFIX/root/pulse-runtime" 2>/dev/null || true

    umo_log_ok "PulseAudio Bridge Configured"
    return 0
}

umo_audio_setup() {
    umo_audio_install_termux || true
    umo_audio_configure || true
    return 0
}
