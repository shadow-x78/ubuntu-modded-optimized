#!/bin/sh
# UMO — Network & Download Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_NET_LOADED:-}" ] || return 0
_UMO_NET_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

UMO_MIRROR_OFFICIAL="https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-arm64-root.tar.xz"
UMO_MIRROR_CDMAGE="https://cdimage.ubuntu.com/ubuntu-base/jammy/daily/current/jammy-base-arm64.tar.gz"
UMO_MIRROR_ANLINUX="https://raw.githubusercontent.com/EXALAB/AnLinux-Resources/master/Rootfs/Ubuntu/arm64/ubuntu-rootfs-arm64.tar.xz"

UMO_MIRROR_LIST="
$UMO_MIRROR_OFFICIAL
$UMO_MIRROR_CDMAGE
$UMO_MIRROR_ANLINUX
"

umo_net_download() {
    _url="$1"
    _output="$2"

    umo_log_step "Downloading: $(basename "$_url")"

    if umo_sys_has_cmd wget; then
        wget --show-progress --progress=bar:force:noscroll \
             --timeout=60 --tries=3 \
             -O "$_output" "$_url" 2>&1 | \
        while IFS= read -r _line; do
            case "$_line" in
                *%*)
                    _pct=$(printf '%s' "$_line" | sed 's/.*\([0-9]\+%\).*/\1/')
                    printf "\r  %bDownload:%b %s" "$UMO_B_CYAN" "$UMO_NC" "$_pct"
                    ;;
            esac
        done
        printf "\n"
        return 0
    elif umo_sys_has_cmd curl; then
        curl -L --progress-bar --max-time 300 \
             -o "$_output" "$_url"
        return 0
    else
        umo_die "No download tool available. Install wget or curl."
    fi
}

umo_net_download_mirrors() {
    _output="$1"
    _mirrors="${2:-$UMO_MIRROR_LIST}"
    _tmp_dir="${UMO_CACHE_DIR:-$HOME/.umo/cache}"
    mkdir -p "$_tmp_dir"

    for _url in $_mirrors; do
        [ -z "$_url" ] && continue
        _filename="$_tmp_dir/$(basename "$_url")"

        if [ -f "$_filename" ] && [ -s "$_filename" ]; then
            umo_log_info "Using cached archive."
            cp -f "$_filename" "$_output"
            return 0
        fi

        if umo_net_download "$_url" "$_filename"; then
            cp -f "$_filename" "$_output"
            return 0
        else
            umo_log_warn "Mirror failed, trying next..."
            rm -f "$_filename"
        fi
    done

    umo_die "All download mirrors failed."
}

umo_net_extract() {
    _archive="$1"
    _target="$2"

    umo_log_step "Extracting archive..."
    mkdir -p "$_target"

    case "$_archive" in
        *.tar.xz) tar -xJf "$_archive" -C "$_target" --exclude='dev' || true ;;
        *.tar.gz) tar -xzf "$_archive" -C "$_target" --exclude='dev' || true ;;
        *.zip)    unzip -q "$_archive" -d "$_target" || true ;;
        *)        umo_die "Unknown archive format: $_archive" ;;
    esac

    # Ensure essential mount points exist
    for _dir in dev proc sys tmp sdcard data termux; do
        mkdir -p "$_target/$_dir"
    done

    umo_log_ok "Extraction complete."
}

umo_net_verify_sha256() {
    _file="$1"
    _expected="$2"

    if [ -z "$_expected" ]; then
        umo_log_warn "No checksum provided, skipping verification."
        return 0
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        _actual=$(sha256sum "$_file" | awk '{print $1}')
    else
        _actual=$(shasum -a 256 "$_file" 2>/dev/null | awk '{print $1}')
    fi

    if [ "$_actual" = "$_expected" ]; then
        umo_log_ok "Checksum verified (SHA-256)."
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
