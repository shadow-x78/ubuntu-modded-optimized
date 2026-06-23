#!/bin/sh
# UMO — Filesystem & Path Utilities (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_FS_LOADED:-}" ] || return 0
_UMO_FS_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_fs_mkdir() {
    for _dir in "$@"; do
        if [ ! -d "$_dir" ]; then
            mkdir -p "$_dir" || umo_die "Cannot create directory: $_dir"
        fi
    done
}

umo_fs_write() {
    _file="$1"
    _content="$2"
    _tmp="${_file}.tmp.$$"

    printf '%s' "$_content" > "$_tmp" || umo_die "Cannot write: $_tmp"
    mv -f "$_tmp" "$_file" || umo_die "Cannot finalize: $_file"
}

umo_fs_backup() {
    _src="$1"
    _ts=$(date +%Y%m%d_%H%M%S)
    _bak="${_src}.umo-bak-${_ts}"

    if [ -f "$_src" ]; then
        cp -f "$_src" "$_bak" || true
        umo_log_info "Backup created: $_bak"
    fi
}

umo_fs_patch() {
    _file="$1"
    _marker="$2"
    _content="$3"

    if [ ! -f "$_file" ]; then
        touch "$_file"
    fi

    if grep -q "$_marker" "$_file" 2>/dev/null; then
        umo_log_debug "Patch already applied: $_marker"
        return 0
    fi

    umo_fs_backup "$_file"
    printf '\n%s\n%s\n' "$_marker" "$_content" >> "$_file"
    umo_log_ok "Patched: $_file"
}

umo_fs_render() {
    _template="$1"
    _output="$2"
    shift 2

    if [ ! -f "$_template" ]; then
        umo_die "Template not found: $_template"
    fi

    _content=$(cat "$_template")

    while [ "$#" -ge 2 ]; do
        _key="$1"
        _val="$2"
        shift 2
        _content=$(printf '%s' "$_content" | sed "s|{{$_key}}|$_val|g")
    done

    umo_fs_write "$_output" "$_content"
}

umo_fs_link() {
    _src="$1"
    _dst="$2"
    [ -L "$_dst" ] && rm -f "$_dst"
    [ -f "$_dst" ] && umo_fs_backup "$_dst" && rm -f "$_dst"
    ln -sf "$_src" "$_dst"
}

umo_fs_remove() {
    for _path in "$@"; do
        if [ -d "$_path" ]; then
            rm -rf "$_path"
        elif [ -f "$_path" ]; then
            rm -f "$_path"
        fi
    done
}

umo_fs_humansize() {
    _bytes="$1"
    if [ "$_bytes" -lt 1024 ]; then
        echo "${_bytes}B"
    elif [ "$_bytes" -lt 1048576 ]; then
        echo "$((_bytes / 1024))KB"
    elif [ "$_bytes" -lt 1073741824 ]; then
        echo "$((_bytes / 1048576))MB"
    else
        echo "$((_bytes / 1073741824))GB"
    fi
}

umo_fs_newest() {
    _dir="$1"
    _pattern="${2:-*}"
    find "$_dir" -maxdepth 1 -name "$_pattern" -type f -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | tail -1 | cut -d' ' -f2-
}
