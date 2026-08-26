#!/bin/sh
# UMO - Core Library: RootFS Download Mirrors (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

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
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.4-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-${_uarch}.tar.gz"
            echo "https://cdimage.ubuntu.com/ubuntu-base/noble/daily/current/noble-base-${_uarch}.tar.gz"
            ;;
        *)
            echo "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-${_uarch}.tar.gz"
            ;;
    esac
}

umo_net_checksums() {
    case "$1" in
        *ubuntu-base-22.04.5-base-arm64.tar.gz) echo "075d4abd2817a5023ab0a82f5cb314c5ec0aa64a9c0b40fd3154ca3bfdae979f" ;;
        *ubuntu-base-22.04.5-base-armhf.tar.gz) echo "fd77cb0659326b75c08ce06b6b8649d2e13ef9a704a8e9212fec32cb97d42add" ;;
        *ubuntu-base-24.04.4-base-arm64.tar.gz) echo "04207713ece899c3740823d33690441ad3a7f0ded1101aca744e2b0f37ac7ff2" ;;
        *ubuntu-base-24.04.4-base-armhf.tar.gz) echo "991520b47f6586f38a78505cf016e300b6191bb8ff86a0723481ec23a37ab7f4" ;;
        *ubuntu-base-24.04.3-base-arm64.tar.gz) echo "7b2dced6dd56ad5e4a813fa25c8de307b655fdabc6ea9213175a92c48dabb048" ;;
        *ubuntu-base-24.04.3-base-armhf.tar.gz) echo "747909a2f81d816fc6252f076757fcf6bd75a55f848a1c049ee79c0e88c0b9a0" ;;
        *) echo "" ;;
    esac
}

umo_net__verify_sha256() {
    _f="$1"
    _want="$2"
    _got=""
    if command -v sha256sum >/dev/null 2>&1; then
        _got="$(sha256sum "$_f" 2>/dev/null | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
        _got="$(shasum -a 256 "$_f" 2>/dev/null | awk '{print $1}')"
    else
        umo_log_warn "No sha256sum/shasum available, cannot verify checksum"
        return 0
    fi
    [ "$_got" = "$_want" ]
}

umo_net__post_check() {
    _f="$1"
    _url="$2"
    umo_net__validate_file "$_f" || return 1
    _want="$(umo_net_checksums "$_url")"
    if [ -n "$_want" ]; then
        if umo_net__verify_sha256 "$_f" "$_want"; then
            umo_log_ok "[OK] SHA-256 verified: $(basename "$_url")"
        else
            umo_log_warn "SHA-256 mismatch for $(basename "$_url"), discarding download"
            return 1
        fi
    else
        umo_log_info "SKIP checksum (mirror has none): $(basename "$_url")"
    fi
    return 0
}

umo_net__file_size() {
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
        _rc=0
        wget --quiet --timeout=60 --tries=3 -O "$_output" "$_url" 2>/dev/null || _rc=$?
        [ "$_rc" -eq 0 ] || return 1
        umo_net__post_check "$_output" "$_url" || { rm -f "$_output"; return 1; }
        return 0
    elif umo_sys_has_cmd curl; then
        _rc=0
        curl -L -s --max-time 300 -o "$_output" "$_url" 2>/dev/null || _rc=$?
        [ "$_rc" -eq 0 ] || return 1
        umo_net__post_check "$_output" "$_url" || { rm -f "$_output"; return 1; }
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
                umo_die "Extraction failed (gzip). Archive may be corrupt - re-run to re-download"
            ;;
        *.tar.xz)
            umo_run_quiet "Decompressing $(basename "$_archive")..." \
                proot --link2symlink tar -xJf "$_archive" -C "$_dest" --exclude='dev' || \
                umo_die "Extraction failed (xz). Archive may be corrupt - re-run to re-download"
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
