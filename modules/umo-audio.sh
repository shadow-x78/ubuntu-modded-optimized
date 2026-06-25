#!/bin/sh
# UMO — PulseAudio Audio Bridge (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_AUDIO_LOADED:-}" ] || return 0
_UMO_MOD_AUDIO_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

umo_audio_install_termux() {
    umo_log_step "Install PulseAudio in Termux"

    if ! command -v pulseaudio >/dev/null 2>&1; then
        pkg install -y pulseaudio 2>/dev/null || \
        apt-get install -y pulseaudio 2>/dev/null || \
        umo_log_warn "Could not auto-install pulseaudio."
    fi

    umo_log_ok "PulseAudio ready."
}

umo_audio_configure() {
    umo_log_step "Configure PulseAudio bridge"

    mkdir -p "$UMO_TERMUX_PREFIX/etc/pulse"
    _pa_config="$UMO_TERMUX_PREFIX/etc/pulse/default.pa"

    if [ -f "$_pa_config" ] && ! grep -q "UMO Audio" "$_pa_config" 2>/dev/null; then
        cat >> "$_pa_config" << 'EOF'

load-module module-native-protocol-tcp auth-anonymous=1
EOF
    fi

    mkdir -p "$UMO_TERMUX_PREFIX/root/pulse-runtime"

    umo_log_ok "PulseAudio bridge configured."
}

umo_audio_setup() {
    umo_audio_install_termux
    umo_audio_configure
}
