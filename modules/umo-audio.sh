#!/bin/sh
# UMO — PulseAudio Audio Bridge (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_AUDIO_LOADED:-}" ] || return 0
_UMO_MOD_AUDIO_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"

UMO_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

umo_audio_install_termux() {
    umo_log_step "Installing PulseAudio in Termux..."

    if ! command -v pulseaudio >/dev/null 2>&1; then
        pkg install -y pulseaudio 2>/dev/null || \
        apt-get install -y pulseaudio 2>/dev/null || \
        umo_log_warn "Could not auto-install pulseaudio."
    fi

    umo_log_ok "PulseAudio ready."
}

umo_audio_configure() {
    umo_log_step "Configuring PulseAudio bridge..."

    mkdir -p "$UMO_TERMUX_PREFIX/etc/pulse"
    _pa_config="$UMO_TERMUX_PREFIX/etc/pulse/default.pa"

    if [ -f "$_pa_config" ] && ! grep -q "UMO Audio" "$_pa_config" 2>/dev/null; then
        cat >> "$_pa_config" << 'EOF'

# ===== UMO Audio Bridge =====
load-module module-native-protocol-tcp auth-anonymous=1
EOF
    fi

    mkdir -p "$UMO_TERMUX_PREFIX/tmp/pulse-runtime"

    umo_log_ok "PulseAudio bridge configured."
}

umo_audio_create_ubuntu_fix() {
    umo_log_step "Creating Ubuntu audio scripts..."

    cat > "${UMO_INSTALL_DIR:?}/usr/local/bin/umo-fix-audio" << 'EOF'
#!/bin/sh
# UMO — Fix Audio Routing

echo "[==>] Fixing audio inside UMO..."

if [ -S "/tmp/pulse-native" ]; then
    export PULSE_SERVER="unix:/tmp/pulse-native"
elif [ -S "/tmp/pulse-runtime/native" ]; then
    export PULSE_SERVER="unix:/tmp/pulse-runtime/native"
else
    export PULSE_SERVER=127.0.0.1
fi

export PULSE_LATENCY_MSEC=60

# Test
if command -v pactl >/dev/null 2>&1; then
    pactl info 2>/dev/null && echo "[OK] PulseAudio connected!" || \
        echo "[WARN] PulseAudio not responding"
fi

# Persist in bashrc
for _rc in /root/.bashrc /home/ubuntu/.bashrc; do
    if [ -f "$_rc" ] && ! grep -q "PULSE_SERVER" "$_rc" 2>/dev/null; then
        echo 'export PULSE_SERVER=127.0.0.1' >> "$_rc"
        echo 'export PULSE_LATENCY_MSEC=60' >> "$_rc"
    fi
done

echo "[OK] Audio fix applied."
EOF
    chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/umo-fix-audio"

    umo_log_ok "Ubuntu audio fix ready."
}

umo_audio_create_termux_helper() {
    cat > "$HOME/umo-fix-audio.sh" << EOF
#!/bin/sh
# UMO — Fix Audio (run in Termux)
echo "[==>] Starting PulseAudio..."
pulseaudio --start 2>/dev/null || true
sleep 1
mkdir -p $UMO_TERMUX_PREFIX/tmp/pulse-runtime
exec \$HOME/umo-login.sh -c "bash /usr/local/bin/umo-fix-audio"
EOF
    chmod +x "$HOME/umo-fix-audio.sh"
}

umo_audio_setup() {
    umo_audio_install_termux
    umo_audio_configure
    umo_audio_create_ubuntu_fix
    umo_audio_create_termux_helper
}
