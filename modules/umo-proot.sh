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

    for _d in dev proc sys tmp sdcard data termux root home/umo; do
        umo_fs_mkdir "$UMO_PROOT_DIR/$_d"
    done

    if [ -f "$UMO_TERMUX_PREFIX/etc/resolv.conf" ]; then
        cp "$UMO_TERMUX_PREFIX/etc/resolv.conf" "$UMO_PROOT_DIR/etc/resolv.conf" 2>/dev/null || true
    fi

    if [ -f "$UMO_TERMUX_PREFIX/etc/hosts" ]; then
        cp "$UMO_TERMUX_PREFIX/etc/hosts" "$UMO_PROOT_DIR/etc/hosts" 2>/dev/null || true
    fi

    umo_fs_mkdir "$UMO_PROOT_DIR/etc/dpkg/dpkg.cfg.d"
    printf 'force-unsafe-io\nno-lock\n' > "$UMO_PROOT_DIR/etc/dpkg/dpkg.cfg.d/umo-proot" 2>/dev/null || true

    umo_fs_mkdir "$UMO_PROOT_DIR/usr/local/sbin"
    cat > "$UMO_PROOT_DIR/usr/local/sbin/dpkg" << 'DPKGWRAP'
#!/bin/sh
/usr/bin/dpkg --force-all "$@" || true
DPKGWRAP
    chmod +x "$UMO_PROOT_DIR/usr/local/sbin/dpkg"

    umo_fs_mkdir "$UMO_PROOT_DIR/etc/apt/apt.conf.d"
    umo_fs_mkdir "$UMO_PROOT_DIR/etc/apt/sources.list.d"
    rm -f "$UMO_PROOT_DIR/etc/apt/sources.list.d"/*.list \
          "$UMO_PROOT_DIR/etc/apt/sources.list.d"/*.sources 2>/dev/null || true

    cat > "$UMO_PROOT_DIR/etc/apt/apt.conf.d/99-umo-sandbox" 2>/dev/null << 'APTCONF'
APT::Sandbox::User "root";
Dpkg::Options:: "--no-lock";
Dpkg::Options:: "--force-all";
Dpkg::Options:: "--force-unsafe-io";
Dpkg::Use-Pty "0";
DPkg::FlushSTDIN "false";
DPkg::Run-Directory "/";
DPkg::DropPrivileges "false";
Debug::NoLocking "1";
APT::Get::AllowUnauthenticated "true";
APT::Acquire::AllowInsecureRepositories "true";
Dir::Bin::dpkg "/usr/local/sbin/dpkg";
APTCONF

    chmod +x "$UMO_PROOT_DIR/usr/bin/dpkg" "$UMO_PROOT_DIR/usr/bin/apt-get" 2>/dev/null || true
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
        --sysvipc \
        -0 \
        -r %s \
        -b /dev \
        -b /proc \
        -b /sys \
        -b %s:/sdcard \
        -b %s:/termux \
        -b /data \
        -b %s/tmp:/tmp -b %s/tmp:/dev/shm \
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
        /bin/bash --login' \
        "$UMO_PROOT_DIR" \
        "$UMO_TERMUX_HOME" \
        "$UMO_TERMUX_HOME" \
        "$UMO_TERMUX_PREFIX" \
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

cd "\$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "\$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \
    -b "\$PREFIX/tmp:/tmp" -b "\$PREFIX/tmp:/dev/shm" \$AUDIO_SOCK \
    -w / \
    /usr/bin/env -i PWD=/ HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 PROOT_NO_SECCOMP=1 \
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

cd "\$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "\$INSTALL_DIR" \
    -b /dev -b /proc -b /sys \
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \
    -b "\$PREFIX/tmp:/tmp" -b "\$PREFIX/tmp:/dev/shm" \
    -w / \
    /usr/bin/env -i PWD=/ HOME=/home/umo PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 PROOT_NO_SECCOMP=1 \
    /bin/su - umo "\$@"
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
    umo_log_step "Creating user 'umo'..."

    umo_fs_mkdir "$UMO_PROOT_DIR/etc/apt"
    cat > "$UMO_PROOT_DIR/etc/apt/sources.list" << SRCLIST
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
SRCLIST

    rm -f "$UMO_PROOT_DIR/etc/group.lock" \
          "$UMO_PROOT_DIR/etc/passwd.lock" \
          "$UMO_PROOT_DIR/etc/shadow.lock" \
          "$UMO_PROOT_DIR/etc/gshadow.lock" \
          "$UMO_PROOT_DIR/etc/.pwd.lock" 2>/dev/null || true

    grep -q "^umo:" "$UMO_PROOT_DIR/etc/group"  || \
        printf "umo:x:1000:\n" >> "$UMO_PROOT_DIR/etc/group"
    grep -q "^umo:" "$UMO_PROOT_DIR/etc/gshadow" 2>/dev/null || \
        printf "umo:!::\n" >> "$UMO_PROOT_DIR/etc/gshadow" 2>/dev/null || true
    grep -q "^umo:" "$UMO_PROOT_DIR/etc/passwd"  || \
        printf "umo:x:1000:1000::/home/umo:/bin/bash\n" >> "$UMO_PROOT_DIR/etc/passwd"

    _pw_hash=$(openssl passwd -6 -salt "umosalt" "umo" 2>/dev/null || echo "!")
    grep -q "^umo:" "$UMO_PROOT_DIR/etc/shadow" 2>/dev/null || \
        printf "umo:%s:19000:0:99999:7:::\n" "$_pw_hash" >> "$UMO_PROOT_DIR/etc/shadow" 2>/dev/null || true

    cp -rp "$UMO_PROOT_DIR/etc/skel/." "$UMO_PROOT_DIR/home/umo/" 2>/dev/null || true
    chmod 755 "$UMO_PROOT_DIR/home/umo"

    umo_fs_mkdir "$UMO_PROOT_DIR/etc/sudoers.d"
    "$UMO_TERMUX_HOME/umo-login.sh" -c \
        "chmod 755 /etc/sudoers.d && printf 'umo ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/umo && chmod 440 /etc/sudoers.d/umo" \
        2>/dev/null || true

    umo_log_ok "User 'umo' created (password: umo)."
}

umo_proot_setup() {
    umo_proot_prepare
    umo_proot_create_scripts
    umo_proot_patch_bashrc
}
