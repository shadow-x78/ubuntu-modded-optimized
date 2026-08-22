#!/bin/sh

[ -z "${_UMO_MOD_PROOT_LOADED:-}" ] || return 0
_UMO_MOD_PROOT_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-system.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_PROOT_DIR="${UMO_INSTALL_DIR:-$HOME/umo-ubuntu}"
UMO_TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"
UMO_TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
UMO_SCRIPT_HOME="${UMO_SCRIPT_DIR:-$UMO_TERMUX_HOME/.umo}"
UMO_LOGIN_SH="${UMO_LOGIN_SH:-$UMO_SCRIPT_HOME/umo-login.sh}"

umo_proot_prepare() {
    umo_log_step "Prepare proot container"

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

    _dpkg_src="$UMO_PROOT_DIR/var/lib/dpkg"

    umo_fs_mkdir "$_dpkg_src" \
        "$_dpkg_src/updates" "$_dpkg_src/info" \
        "$_dpkg_src/parts" "$_dpkg_src/triggers"

    for _f in status status-old available lock lock-frontend; do
        touch "$_dpkg_src/$_f" 2>/dev/null || true
    done
    chmod -R 755 "$_dpkg_src" 2>/dev/null || true

    umo_fs_mkdir "$UMO_PROOT_DIR/usr/sbin"
    cat > "$UMO_PROOT_DIR/usr/sbin/policy-rc.d" << 'POLICY'
#!/bin/sh
exit 101
POLICY
    chmod +x "$UMO_PROOT_DIR/usr/sbin/policy-rc.d"

    rm -f "$UMO_PROOT_DIR/usr/local/sbin/dpkg" 2>/dev/null || true

    umo_fs_mkdir "$UMO_PROOT_DIR/etc/apt/apt.conf.d"
    umo_fs_mkdir "$UMO_PROOT_DIR/etc/apt/sources.list.d"
    rm -f "$UMO_PROOT_DIR/etc/apt/sources.list.d"/*.list \
          "$UMO_PROOT_DIR/etc/apt/sources.list.d"/*.sources 2>/dev/null || true

    cat > "$UMO_PROOT_DIR/etc/apt/apt.conf.d/99-umo-sandbox" 2>/dev/null << 'APTCONF'
APT::Sandbox::User "root";
Dpkg::Options:: "--force-all";
Dpkg::Options:: "--force-confdef";
Dpkg::Options:: "--force-confold";
Dpkg::Options:: "--force-unsafe-io";
Dpkg::Use-Pty "0";
DPkg::FlushSTDIN "false";
DPkg::Run-Directory "/";
DPkg::DropPrivileges "false";
DPkg::NoTriggers "true";
DPkg::TriggersPending "false";
Dpkg::Post-Invoke {};
Dpkg::Pre-Invoke {};
Debug::NoLocking "1";
APT::Get::AllowUnauthenticated "true";
APT::Acquire::AllowInsecureRepositories "true";
APTCONF

    cat > "$UMO_PROOT_DIR/etc/dpkg/dpkg.cfg.d/force-unsafe-io" 2>/dev/null << 'DPCFG'
force-unsafe-io
DPCFG

    for _f in invoke-rc.d service systemctl; do
        if [ -x "$UMO_PROOT_DIR/usr/sbin/$_f" ] && [ ! -L "$UMO_PROOT_DIR/usr/sbin/$_f" ]; then
            mv "$UMO_PROOT_DIR/usr/sbin/$_f" "$UMO_PROOT_DIR/usr/sbin/$_f.real" 2>/dev/null || true
            ln -sf /bin/true "$UMO_PROOT_DIR/usr/sbin/$_f" 2>/dev/null || true
        fi
    done

    cat > "$UMO_PROOT_DIR/root/divert-triggers.sh" << 'DIVERT'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
if command -v debconf-set-selections >/dev/null 2>&1; then
    echo "man-db man-db/auto-update boolean false" | debconf-set-selections 2>/dev/null || true
fi
for _bin in gtk-update-icon-cache update-initramfs systemd-hwdb update-command-not-found update-mime-database update-desktop-database; do
    if [ -e "/usr/bin/$_bin" ] && [ ! -L "/usr/bin/$_bin" ]; then
        dpkg-divert --local --rename --add "/usr/bin/$_bin" 2>/dev/null || true
        ln -sf /bin/true "/usr/bin/$_bin"
    elif [ -e "/usr/sbin/$_bin" ] && [ ! -L "/usr/sbin/$_bin" ]; then
        dpkg-divert --local --rename --add "/usr/sbin/$_bin" 2>/dev/null || true
        ln -sf /bin/true "/usr/sbin/$_bin"
    fi
done
DIVERT
    chmod +x "$UMO_PROOT_DIR/root/divert-triggers.sh"

    chmod +x "$UMO_PROOT_DIR/usr/bin/dpkg" "$UMO_PROOT_DIR/usr/bin/apt-get" 2>/dev/null || true
    : > "$UMO_PROOT_DIR/var/lib/dpkg/lock"
    : > "$UMO_PROOT_DIR/var/lib/dpkg/lock-frontend"
    umo_log_ok "Proot directories ready"
}

umo_proot_create_scripts() {
    umo_log_step "Create login wrappers"

    rm -rf "$UMO_PROOT_DIR/.fake_proc" 2>/dev/null || true
    rm -f "$UMO_PROOT_DIR/swapfile" 2>/dev/null || true

    if ! mkdir -p "$UMO_SCRIPT_HOME" 2>/dev/null; then
        umo_log_warn "Cannot create $UMO_SCRIPT_HOME - falling back to \$HOME"
        UMO_SCRIPT_HOME="$UMO_TERMUX_HOME"
        UMO_LOGIN_SH="$UMO_SCRIPT_HOME/umo-login.sh"
    fi

    cat > "$UMO_SCRIPT_HOME/umo-login.sh" << EOF
#!/bin/sh
INSTALL_DIR="$UMO_PROOT_DIR"
PREFIX="$UMO_TERMUX_PREFIX"

[ -d "\$INSTALL_DIR" ] || { echo "[ERR] UMO not installed."; exit 1; }

unset LD_PRELOAD
unset LD_LIBRARY_PATH

AUDIO_SOCK=""
[ -S "\$PREFIX/tmp/pulse-\$(id -u)/native" ] && AUDIO_SOCK="-b \$PREFIX/tmp/pulse-\$(id -u)/native:/tmp/pulse-native"
[ -S "\$PREFIX/root/pulse-\$(id -u)/native" ] && AUDIO_SOCK="-b \$PREFIX/root/pulse-\$(id -u)/native:/tmp/pulse-native"
[ -S "\$PREFIX/tmp/pulse-native" ] && AUDIO_SOCK="-b \$PREFIX/tmp/pulse-native:/tmp/pulse-native"

cd "\$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "\$INSTALL_DIR" \\
    -b /dev -b /proc -b /sys \\
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \\
    -b "\$PREFIX/tmp:/tmp" -b "\$PREFIX/tmp:/dev/shm" \\
    \$AUDIO_SOCK \\
    -w / \\
    /usr/bin/env -i PWD=/ HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \\
    /bin/bash --login "\$@"
EOF
    chmod +x "$UMO_SCRIPT_HOME/umo-login.sh"

    cat > "$UMO_SCRIPT_HOME/umo-user.sh" << EOF
#!/bin/sh
INSTALL_DIR="$UMO_PROOT_DIR"
PREFIX="$UMO_TERMUX_PREFIX"

unset LD_PRELOAD
unset LD_LIBRARY_PATH

cd "\$INSTALL_DIR" || exit 1

exec proot --link2symlink --sysvipc -0 -r "\$INSTALL_DIR" \\
    -b /dev -b /proc -b /sys \\
    -b "\$HOME:/sdcard" -b "\$HOME:/termux" \\
    -b "\$PREFIX/tmp:/tmp" -b "\$PREFIX/tmp:/dev/shm" \\
    -w / \\
    /usr/bin/env -i PWD=/ HOME=/home/umo PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
    TERM="\$TERM" LANG=C.UTF-8 PULSE_SERVER=127.0.0.1 PULSE_LATENCY_MSEC=60 \\
    /bin/su - umo "\$@"
EOF
    chmod +x "$UMO_SCRIPT_HOME/umo-user.sh"

    cat > "$UMO_SCRIPT_HOME/umo-start.sh" << EOF
#!/bin/sh
echo "[==>] Starting UMO environment..."
termux-wake-lock 2>/dev/null || true
pulseaudio --start 2>/dev/null || true
sleep 1
exec "$UMO_SCRIPT_HOME/umo-login.sh"
EOF
    chmod +x "$UMO_SCRIPT_HOME/umo-start.sh"

    if [ "$UMO_SCRIPT_HOME" != "$UMO_TERMUX_HOME" ]; then
        for _legacy in umo-login.sh umo-user.sh umo-start.sh umo-stop.sh umo-vnc-start.sh umo-vnc-stop.sh; do
            rm -f "$UMO_TERMUX_HOME/$_legacy" 2>/dev/null || true
        done
    fi

    umo_log_ok "Login scripts ready ($UMO_SCRIPT_HOME)"
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

alias ls="ls --color=auto 2>/dev/null"
alias ll="ls -alF 2>/dev/null"
alias la="ls -A 2>/dev/null"
alias l="ls -CF 2>/dev/null"
alias startvnc="bash /usr/local/bin/umo-startvnc"
alias stopvnc="bash /usr/local/bin/umo-stopvnc"

if [ -n "$PS1" ]; then
    printf "\n\033[38;5;208m"
    printf "  ██╗   ██╗███╗   ███╗ ██████╗  \n"
    printf "  ██║   ██║████╗ ████║██╔═══██╗ \n"
    printf "  ██║   ██║██╔████╔██║██║   ██║ \n"
    printf "  ██║   ██║██║╚██╔╝██║██║   ██║ \n"
    printf "  ╚██████╔╝██║ ╚═╝ ██║╚██████╔╝ \n"
    printf "   ╚═════╝ ╚═╝     ╚═╝ ╚═════╝  \n"
    printf "\033[0m\n"
    printf "\033[38;5;208m  ────────────────────────────────────────────────────────\033[0m\n\n"
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch --logo none
    elif command -v neofetch >/dev/null 2>&1; then
        neofetch
    fi
fi
'
}

umo_proot_create_user() {
    umo_log_step "Create default user 'umo'"

    _etc="$UMO_PROOT_DIR/etc"

    if ! grep -q '^umo:' "$_etc/passwd" 2>/dev/null; then
        echo "umo:x:1000:1000:UMO User:/home/umo:/bin/bash" >> "$_etc/passwd"
    fi

    _distro_codename="jammy"
    [ "${UMO_UBUNTU_VERSION:-22.04}" = "24.04" ] && _distro_codename="noble"
    cat > "$UMO_PROOT_DIR/etc/apt/sources.list" << SRCLIST
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports ${_distro_codename} main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports ${_distro_codename}-updates main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports ${_distro_codename}-backports main restricted universe multiverse
deb [trusted=yes] http://ports.ubuntu.com/ubuntu-ports ${_distro_codename}-security main restricted universe multiverse
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

    _etc="$UMO_PROOT_DIR/etc"
    chmod 644 "$_etc/passwd" "$_etc/group"
    chmod 640 "$_etc/shadow" "$_etc/gshadow"

    for _gid in 3003 9997 20488 50488 1015 1023 1024 1028 1065 3001 3002 3006 3009 3011 3012 $(id -G 2>/dev/null); do
        [ -n "$_gid" ] || continue
        if ! grep -q ":x:$_gid:" "$_etc/group" 2>/dev/null; then
            echo "android_$_gid:x:$_gid:" >> "$_etc/group"
        fi
    done

    umo_fs_mkdir "$_etc/sudoers.d"
    if [ -x "$UMO_LOGIN_SH" ]; then
        "$UMO_LOGIN_SH" -c \
            "chmod 755 /etc/sudoers.d && printf 'umo ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/umo && chmod 440 /etc/sudoers.d/umo" \
            </dev/null 2>/dev/null || true
    fi

    umo_log_ok "User 'umo' created (password: umo)"
}

umo_proot_setup() {
    umo_proot_prepare
    umo_proot_create_scripts
    if [ -x "$UMO_LOGIN_SH" ]; then
        "$UMO_LOGIN_SH" -c "bash /root/divert-triggers.sh" </dev/null >/dev/null 2>&1 || true
        rm -f "$UMO_PROOT_DIR/root/divert-triggers.sh" 2>/dev/null || true
    fi
    umo_proot_patch_bashrc
}
