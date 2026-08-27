#!/bin/sh

set -e

_GET_REPO="shadow-x78/ubuntu-modded-optimized"
_GET_DEST="${UMO_HOME:-$HOME/.local/share/umo}"
_GET_CACHE="$HOME/.umo/cache"
_GET_NO_RUN="${UMO_NO_RUN:-}"

for _a in "$@"; do
    case "$_a" in
        --no-run) _GET_NO_RUN=1 ;;
    esac
done

_UMO_NC=''; _UMO_GRN=''; _UMO_RED=''; _UMO_CYN=''; _UMO_PRI=''
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    _UMO_NC='\033[0m'; _UMO_GRN='\033[38;5;34m'; _UMO_RED='\033[38;5;196m'
    _UMO_CYN='\033[38;5;39m'; _UMO_PRI='\033[38;5;208m'
fi
_UMO_G_OK='OK'; _UMO_G_ERR='ERR'; _UMO_G_INFO='i'; _UMO_G_RUN='|'
if [ -t 1 ]; then
    _UMO_UTF8=0
    case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in *UTF-8*|*utf8*) _UMO_UTF8=1 ;; esac
    if [ "$_UMO_UTF8" -eq 0 ] && command -v locale >/dev/null 2>&1; then
        case "$(locale charmap 2>/dev/null)" in UTF-8*|utf-8*) _UMO_UTF8=1 ;; esac
    fi
    if [ "$_UMO_UTF8" -eq 1 ]; then
        _UMO_G_OK='✔'; _UMO_G_ERR='✖'; _UMO_G_INFO='ℹ'; _UMO_G_RUN='▌'
    fi
fi
_umo_ok()   { printf "  %b%s%b  %s\n" "$_UMO_GRN" "$_UMO_G_OK" "$_UMO_NC" "$1"; }
_umo_err()  { printf "  %b%s%b  %s\n" "$_UMO_RED" "$_UMO_G_ERR" "$_UMO_NC" "$1" >&2; }
_umo_info() { printf "  %b%s%b  %s\n" "$_UMO_CYN" "$_UMO_G_INFO" "$_UMO_NC" "$1"; }
_umo_step() { printf "  %b%s%b  %s\n" "$_UMO_PRI" "$_UMO_G_RUN" "$_UMO_NC" "$1"; }

_umo_dp() {
    _dp_b="/data/data/com.termux/files"
    if [ -n "${PREFIX:-}" ]; then
        _dp_f=$(cd "${PREFIX%/}/.." 2>/dev/null && pwd) || _dp_f=""
        case "$_dp_f" in
            */files) _dp_b="$_dp_f" ;;
        esac
    fi
    case "$1" in
        "$_dp_b")   printf '%s' "/" ;;
        "$_dp_b"/*) printf '%s' "${1#"$_dp_b"}" ;;
        *)          printf '%s' "$1" ;;
    esac
}

_umo_step "UMO Release Installer"

if [ ! -d "${PREFIX:-/data/data/com.termux/files/usr}" ] || ! command -v termux-info >/dev/null 2>&1; then
    if [ ! -d /data/data/com.termux ]; then
        _umo_err "UMO must run inside Termux."
        exit 1
    fi
fi

mkdir -p "$_GET_CACHE"

if command -v curl >/dev/null 2>&1; then
    _GET_DL_CURL=1
elif command -v wget >/dev/null 2>&1; then
    _GET_DL_CURL=0
else
    _umo_err "Neither curl nor wget found."
    echo "      Install one with: pkg install curl"
    exit 1
fi

_get_fetch() {
    if [ "$_GET_DL_CURL" = 1 ]; then
        curl -fsSL --max-time "$_GET_TIMEOUT" -o "$2" "$1"
    else
        wget -q -T "$_GET_TIMEOUT" -O "$2" "$1"
    fi
}

_umo_step "Fetching Latest Release From GitHub..."
_GET_TIMEOUT=60
_rel_json="$_GET_CACHE/latest-release.json"
if ! _get_fetch "https://api.github.com/repos/$_GET_REPO/releases/latest" "$_rel_json"; then
    _umo_err "Could not reach GitHub Releases API."
    echo "      Check your internet connection and retry."
    exit 1
fi

_tag=$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_rel_json" | head -1)
if [ -z "$_tag" ]; then
    _umo_err "Could not detect latest release tag."
    exit 1
fi

_tb_url=$(sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(.*\.tar\.gz\)".*/\1/p' "$_rel_json" | head -1)
_sh_url=$(sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(.*\.sha256\)".*/\1/p' "$_rel_json" | head -1)
if [ -z "$_tb_url" ] || [ -z "$_sh_url" ]; then
    _umo_err "Release $_tag has no downloadable tarball."
    exit 1
fi

_umo_info "Latest release: $_tag"
_tb_file="$_GET_CACHE/$(basename "$_tb_url")"
_sh_file="$_GET_CACHE/$(basename "$_sh_url")"

_get_fetch "$_tb_url" "$_tb_file" || { _umo_err "Tarball download failed."; exit 1; }
_get_fetch "$_sh_url" "$_sh_file" || { _umo_err "Checksum download failed."; exit 1; }

if command -v sha256sum >/dev/null 2>&1; then
    _actual=$(sha256sum "$_tb_file" | awk '{print $1}')
else
    _actual=$(shasum -a 256 "$_tb_file" | awk '{print $1}')
fi
_expected=$(awk '{print $1}' "$_sh_file")
if [ -z "$_actual" ] || [ "$_actual" != "$_expected" ]; then
    _umo_err "SHA-256 verification failed."
    echo "      Expected: $_expected"
    echo "      Actual:   $_actual"
    rm -f "$_tb_file" "$_sh_file"
    exit 1
fi
_umo_ok "SHA-256 verified"

_tmp_dest="$_GET_CACHE/.install-tmp.$$"
rm -rf "$_tmp_dest"
mkdir -p "$_tmp_dest"
tar -xzf "$_tb_file" -C "$_tmp_dest" || { _umo_err "Extraction failed."; exit 1; }
if [ ! -f "$_tmp_dest/bin/umo-install" ]; then
    _umo_err "Release tarball is malformed (bin/umo-install missing)."
    rm -rf "$_tmp_dest"
    exit 1
fi

rm -rf "$_GET_DEST.old"
if [ -d "$_GET_DEST" ]; then
    mv "$_GET_DEST" "$_GET_DEST.old"
fi
mkdir -p "$(dirname "$_GET_DEST")"
mv "$_tmp_dest" "$_GET_DEST"
rm -rf "$_GET_DEST.old"
chmod +x "$_GET_DEST/bin/umo-install" 2>/dev/null || true

_umo_ok "UMO $_tag installed to $(_umo_dp "$_GET_DEST")"
rm -f "$_tb_file" "$_sh_file" "$_rel_json" 2>/dev/null || true

if [ -n "$_GET_NO_RUN" ]; then
    echo ""
    _umo_info "Next steps:"
    echo "      sh $_GET_DEST/bin/umo-install"
    exit 0
fi

_umo_step "Starting Installer..."
if [ -t 0 ]; then
    exec sh "$_GET_DEST/bin/umo-install"
elif [ -e /dev/tty ]; then
    exec sh "$_GET_DEST/bin/umo-install" < /dev/tty
else
    _umo_info "No TTY available, running non-interactive"
    exec sh "$_GET_DEST/bin/umo-install" --no-gui
fi
