#!/bin/sh
# UMO — Network & Download Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_NET_LOADED:-}" ] || return 0
_UMO_NET_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

_UMO_NET_MIN_SIZE=1048576

umo_net_mirror_list() {
    _ver="${1:-22.04}"
    
    _arch=$(uname -m)
    case "$_arch" in
        aarch64|arm64) _uarch="arm64" ;;
        armv7l|armv8l|arm) _uarch="armhf" ;;
        *) _uarch="arm64" ;;
    esac

    case "$_ver" in
        22.04|jammy)
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04.5/release/ubuntu-base-22.04.5-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/jammy/daily/current/jammy-base-${_uarch}.tar.gz"
            ;;
        24.04|noble)
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.1-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/24.04.1/release/ubuntu-base-24.04.1-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/noble/daily/current/noble-base-${_uarch}.tar.gz"
            ;;
        *)
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-${_uarch}.tar.gz"
            ;;
    esac
}

umo_net__file_size() {
    _f="$1"
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0
}

umo_net__validate_file() {
    _f="$1"
    [ -f "$_f" ] || return 1
    [ -s "$_f" ] || return 1
    _sz=$(umo_net__file_size "$_f")
    [ "$_sz" -ge "$_UMO_NET_MIN_SIZE" ] || return 1
    case "$_f" in
        *.gz|*.tgz) gzip -t "$_f" 2>/dev/null || return 1 ;;
        *.xz)       xz -t "$_f" 2>/dev/null || return 1 ;;
    esac
    return 0
}

umo_net_download() {
    _url="$1"
    _output="$2"

    umo_log_step "Download: $(basename "$_url")"

    if umo_sys_has_cmd wget; then
        wget --quiet --timeout=60 --tries=3 -O "$_output" "$_url" 2>/dev/null
        _rc=$?
        [ "$_rc" -eq 0 ] || return 1
        umo_net__validate_file "$_output" || return 1
        return 0
    elif umo_sys_has_cmd curl; then
        curl -L -s --max-time 300 -o "$_output" "$_url" 2>/dev/null
        _rc=$?
        [ "$_rc" -eq 0 ] || return 1
        umo_net__validate_file "$_output" || return 1
        return 0
    else
        umo_die "No download tool available. Install wget or curl"
    fi
}

umo_net_download_mirrors() {
    _output="$1"
    _ver="${UMO_UBUNTU_VERSION:-22.04}"
    _mirrors=$(umo_net_mirror_list "$_ver")
    _tmp_dir="${UMO_CACHE_DIR:-$HOME/.umo/cache}"
    mkdir -p "$_tmp_dir"

    if [ -f "$_output" ]; then
        if umo_net__validate_file "$_output"; then
            umo_log_info "Using cached archive."
            return 0
        else
            umo_log_warn "Cached archive is corrupt, re-downloading..."
            rm -f "$_output"
        fi
    fi

    for _url in $_mirrors; do
        [ -z "$_url" ] && continue

        if umo_net_download "$_url" "$_output"; then
            if umo_net__validate_file "$_output"; then
                return 0
            else
                umo_log_warn "Downloaded file invalid or corrupt, trying next mirror"
                rm -f "$_output"
            fi
        else
            umo_log_warn "Mirror failed, trying next"
            rm -f "$_output"
        fi
    done

    umo_die "All download mirrors failed"
}

umo_net_extract() {
    _archive="$1"
    _dest="${2:-.}"

    [ -f "$_archive" ] || umo_die "Archive not found: $_archive"
    mkdir -p "$_dest"

    umo_log_step "Extract archive"

    case "$_archive" in
        *.tar.gz|*.tgz)
            umo_run_quiet "Decompressing $(basename "$_archive")..." \
                proot --link2symlink tar -xzf "$_archive" -C "$_dest" --exclude='dev' || \
                umo_die "Extraction failed (gzip). Archive may be corrupt — re-run to re-download"
            ;;
        *.tar.xz)
            umo_run_quiet "Decompressing $(basename "$_archive")..." \
                proot --link2symlink tar -xJf "$_archive" -C "$_dest" --exclude='dev' || \
                umo_die "Extraction failed (xz). Archive may be corrupt — re-run to re-download"
            ;;
        *.zip)
            umo_run_quiet "Decompressing $(basename "$_archive")..." \
                unzip -q "$_archive" -d "$_dest" || \
                umo_die "Extraction failed (zip)"
            ;;
        *)
            umo_die "Unknown archive format: $_archive"
            ;;
    esac

    umo_log_ok "Extraction complete"
}

umo_net_verify_sha256() {
    _file="$1"
    _expected="$2"

    if [ -z "$_expected" ]; then
        umo_log_warn "No checksum provided, skipping verification"
        return 0
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        _actual=$(sha256sum "$_file" | awk '{print $1}')
    else
        _actual=$(shasum -a 256 "$_file" 2>/dev/null | awk '{print $1}')
    fi

    if [ "$_actual" = "$_expected" ]; then
        umo_log_ok "Checksum verified (SHA-256)"
        return 0
    else
        umo_log_err "Checksum mismatch!"
        umo_log_err "  Expected: $_expected"
        umo_log_err "  Actual:   $_actual"
        return 1
    fi
}

umo_net_speedtest() {
    _url="$1"
    _start=$(date +%s)
    _tmp="/tmp/.umo_speedtest_$$"

    wget -q -O "$_tmp" "$_url" 2>/dev/null || \
    curl -s -o "$_tmp" "$_url" 2>/dev/null || {
        echo "0"
        return
    }

    _size=$(stat -c%s "$_tmp" 2>/dev/null || stat -f%z "$_tmp" 2>/dev/null || echo 0)
    _end=$(date +%s)
    _duration=$((_end - _start))
    rm -f "$_tmp"

    [ "$_duration" -eq 0 ] && _duration=1
    _speed=$((_size / _duration / 1024))
    echo "$_speed"
}
