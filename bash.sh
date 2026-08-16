#!/bin/sh
# UMO - Release Installer (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

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

echo "[UMO] Release installer"

if [ ! -d "${PREFIX:-/data/data/com.termux/files/usr}" ] || ! command -v termux-info >/dev/null 2>&1; then
    if [ ! -d /data/data/com.termux ]; then
        echo "[ERR] UMO must run inside Termux."
        exit 1
    fi
fi

mkdir -p "$_GET_CACHE"

if command -v curl >/dev/null 2>&1; then
    _GET_DL_CURL=1
elif command -v wget >/dev/null 2>&1; then
    _GET_DL_CURL=0
else
    echo "[ERR] Neither curl nor wget found."
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

echo "[..] Fetching latest release from GitHub..."
_GET_TIMEOUT=60
_rel_json="$_GET_CACHE/latest-release.json"
if ! _get_fetch "https://api.github.com/repos/$_GET_REPO/releases/latest" "$_rel_json"; then
    echo "[ERR] Could not reach GitHub Releases API."
    echo "      Check your internet connection and retry."
    exit 1
fi

_tag=$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_rel_json" | head -1)
if [ -z "$_tag" ]; then
    echo "[ERR] Could not detect latest release tag."
    exit 1
fi

_tb_url=$(sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(.*\.tar\.gz\)".*/\1/p' "$_rel_json" | head -1)
_sh_url=$(sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(.*\.sha256\)".*/\1/p' "$_rel_json" | head -1)
if [ -z "$_tb_url" ] || [ -z "$_sh_url" ]; then
    echo "[ERR] Release $_tag has no downloadable tarball."
    exit 1
fi

echo "[..] Latest release: $_tag"
_tb_file="$_GET_CACHE/$(basename "$_tb_url")"
_sh_file="$_GET_CACHE/$(basename "$_sh_url")"

_get_fetch "$_tb_url" "$_tb_file" || { echo "[ERR] Tarball download failed."; exit 1; }
_get_fetch "$_sh_url" "$_sh_file" || { echo "[ERR] Checksum download failed."; exit 1; }

if command -v sha256sum >/dev/null 2>&1; then
    _actual=$(sha256sum "$_tb_file" | awk '{print $1}')
else
    _actual=$(shasum -a 256 "$_tb_file" | awk '{print $1}')
fi
_expected=$(awk '{print $1}' "$_sh_file")
if [ -z "$_actual" ] || [ "$_actual" != "$_expected" ]; then
    echo "[ERR] SHA-256 verification failed."
    echo "      Expected: $_expected"
    echo "      Actual:   $_actual"
    rm -f "$_tb_file" "$_sh_file"
    exit 1
fi
echo "[OK] SHA-256 verified."

_tmp_dest="$_GET_CACHE/.install-tmp.$$"
rm -rf "$_tmp_dest"
mkdir -p "$_tmp_dest"
tar -xzf "$_tb_file" -C "$_tmp_dest" || { echo "[ERR] Extraction failed."; exit 1; }
if [ ! -f "$_tmp_dest/bin/umo-install" ]; then
    echo "[ERR] Release tarball is malformed (bin/umo-install missing)."
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

echo "[OK] UMO $_tag installed to $_GET_DEST"
rm -f "$_tb_file" "$_sh_file" "$_rel_json" 2>/dev/null || true

if [ -n "$_GET_NO_RUN" ]; then
    echo ""
    echo "Next steps:"
    echo "  sh $_GET_DEST/bin/umo-install"
    exit 0
fi

echo "[..] Starting installer..."
if [ -t 0 ]; then
    exec sh "$_GET_DEST/bin/umo-install"
elif [ -e /dev/tty ]; then
    exec sh "$_GET_DEST/bin/umo-install" < /dev/tty
else
    echo "[..] No TTY available, running non-interactive"
    exec sh "$_GET_DEST/bin/umo-install" --no-gui
fi
