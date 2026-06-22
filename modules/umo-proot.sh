#!/bin/sh
# UMO — Proot Container Manager (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_PROOT_LOADED:-}" ] || return 0
_UMO_MOD_PROOT_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-system.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_PROOT_DIR="${UMO_INSTALL_DIR:-$HOME/umo-ubuntu}"
UMO_TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"
UMO_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

umo_proot_prepare() {
    umo_log_step "Preparing proot container..."

    for _d in dev proc sys tmp sdcard data termux root home/ubuntu; do
        umo_fs_mkdir "$UMO_PROOT_DIR/$_d"
    done

    if [ -f "$UMO_TERMUX_PREFIX/etc/resolv.conf" ]; then
        cp "$UMO_TERMUX_PREFIX/etc/resolv.conf" "$UMO_PROOT_DIR/etc/resolv.conf" 2>/dev/null || true
    fi

    if [ -f "$UMO_TERMUX_PREFIX/etc/hosts" ]; then
        cp "$UMO_TERMUX_PREFIX/etc/hosts" "$UMO_PROOT_DIR/etc/hosts" 2>/dev/null || true
    fi

    umo_log_ok "Proot directories ready."
}

umo_proot_cmd() {
    _user="${1:-root}"
    _workdir="${2:-/root}"

    _audio_bind=""
    if [ -S "$UMO_TERMUX_PREFIX/root/pulse-$(id -u)/native" ]; then
        _audio_bind="-b $UMO_TERMUX_PREFIX/root/pulse-$(id -u)/native:/root/pulse-native"
    elif [ -S "$UMO_TERMUX_PREFIX/root/pulse-native" ]; then
        _audio_bind="-b $UMO_TERMUX_PREFIX/root/pulse-native:/root/pulse-native"
    fi

    printf 'proot \
        --link2symlink \
        -0 \
        -r %s \
        -b /dev \
        -b /proc \
        -b /sys \
        -b %s:/sdcard \
        -b %s:/termux \
        -b /data \
        -b %s/tmp:/tmp \
        %s \
        -w %s \
        /usr/bin/env -i \
        HOME=%s \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        TERM=%s \
        LANG=C.UTF-8 \
        PULSE_SERVER=127.0.0.1 \
        PULSE_LATENCY_MSEC=60 \
        PROOT_NO_SECCOMP=1 \
        PROOT_LOAD_EXT_LIBS=0 \
        /bin/bash --login' \
        "$UMO_PROOT_DIR" \
        "$UMO_TERMUX_HOME" \
        "$UMO_TERMUX_HOME" \
        "$UMO_TERMUX_PREFIX" \
        "${_audio_bind}" \
        "$_workdir" \
        "$_workdir" \
        "${TERM:-xterm-256color}"
}

umo_proot_create_scripts() {
    umo_log_step "Creating login wrappers..."

    cat > "$UMO_TERMUX_HOME/umo-login.sh" << EOF
#!/bin/sh
# UMO — Ubuntu Login Wrapper
INSTALL_DIR="$UMO_PROOT_DIR"
PREFIX="$UMO_TERMUX_PREFIX"

[ -d "\$INSTALL_DIR" ] || { echo "[ERR] UMO not installed."; exit 1; }

export PROOT_NO_SECCOMP=1
unset LD_PRELOAD
unset LD_LIBRARY_PATH

AUDIO_SOCK=""
[ -S "\$PREFIX/root/pulse-\$(id -u)/native" ] && AUDIO_SOCK="-b \$PREFIX/root/pulse-\$(id -u)/native:/root/pulse-native"
[ -S "\$PREFIX/root/pulse-native" ] && AUDIO_SOCK="-b \$PREFIX/root/pulse-native:/root/pulse-native"

exec proot --link2symlink -0 -r "\$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \
    -b "\$PREFIX/tmp:/tmp" \$AUDIO_SOCK \
    -w /root \
    /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/bash --login "\$@"
EOF
    chmod +x "$UMO_TERMUX_HOME/umo-login.sh"

    cat > "$UMO_TERMUX_HOME/umo-user.sh" << EOF
#!/bin/sh
# UMO — Ubuntu User Login
INSTALL_DIR="$UMO_PROOT_DIR"
PREFIX="$UMO_TERMUX_PREFIX"

export PROOT_NO_SECCOMP=1
unset LD_PRELOAD
unset LD_LIBRARY_PATH

exec proot --link2symlink -0 -r "\$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \
    -b "\$PREFIX/tmp:/tmp" \
    -w /home/ubuntu \
    /usr/bin/env -i HOME=/home/ubuntu PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \
    /bin/su - ubuntu "\$@"
EOF
    chmod +x "$UMO_TERMUX_HOME/umo-user.sh"

    cat > "$UMO_TERMUX_HOME/umo-start.sh" << 'EOF'
#!/bin/sh
# UMO — Quick Start
echo "[==>] Starting UMO environment..."
termux-wake-lock 2>/dev/null || true
pulseaudio --start 2>/dev/null || true
sleep 1
exec "$HOME/umo-login.sh"
EOF
    chmod +x "$UMO_TERMUX_HOME/umo-start.sh"

    umo_log_ok "Login scripts ready."
}

umo_proot_patch_bashrc() {
    _bashrc="$UMO_PROOT_DIR/root/.bashrc"
    [ ! -f "$_bashrc" ] && touch "$_bashrc"

    umo_fs_patch "$_bashrc" "# ===== UMO Environment =====" '
export PULSE_SERVER=127.0.0.1
export PULSE_LATENCY_MSEC=60
export DISPLAY=:1
export PROOT_NO_SECCOMP=1
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.0

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias startvnc="bash /usr/local/bin/umo-startvnc"
alias stopvnc="bash /usr/local/bin/umo-stopvnc"

command -v neofetch >/dev/null 2>&1 && neofetch
'
}

umo_proot_exec() {
    "$UMO_TERMUX_HOME/umo-login.sh" -c "$*"
}

umo_proot_create_user() {
    umo_log_step "Creating user 'ubuntu'..."

    cat > "$UMO_PROOT_DIR/root/setup-user.sh" << 'INNER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sudo adduser

if ! id -u ubuntu >/dev/null 2>&1; then
    adduser --disabled-password --gecos '' ubuntu
    echo 'ubuntu:ubuntu' | chpasswd
    usermod -aG sudo ubuntu
fi

if [ -d /etc/sudoers.d ]; then
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
    chmod 440 /etc/sudoers.d/ubuntu
fi
INNER
    chmod +x "$UMO_PROOT_DIR/root/setup-user.sh"
    umo_run_quiet "Creating user 'ubuntu'" "$UMO_TERMUX_HOME/umo-login.sh" -c "bash /root/setup-user.sh"
    rm -f "$UMO_PROOT_DIR/root/setup-user.sh"

    umo_log_ok "User 'ubuntu' created (password: ubuntu)."
}

umo_proot_setup() {
    umo_proot_prepare
    umo_proot_create_scripts
    umo_proot_patch_bashrc
}
