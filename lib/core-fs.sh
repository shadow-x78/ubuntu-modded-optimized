#!/bin/sh
# UMO - Core Library: Filesystem Helpers and Templates (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_FS_LOADED:-}" ] || return 0
_UMO_FS_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_fs_mkdir() {
    _fs_rc=0
    for _dir in "$@"; do
        if [ ! -d "$_dir" ]; then
            if ! mkdir -p "$_dir" 2>/dev/null; then
                umo_log_warn "Cannot create directory: $_dir"
                _fs_rc=1
            fi
        fi
    done
    return $_fs_rc
}

umo_fs_write() {
    _file="$1"
    _content="$2"
    _tmp="${_file}.tmp.$$"

    if ! printf '%s' "$_content" > "$_tmp" 2>/dev/null; then
        umo_log_warn "Cannot write: $_tmp"
        return 1
    fi
    if ! mv -f "$_tmp" "$_file" 2>/dev/null; then
        umo_log_warn "Cannot finalize: $_file"
        rm -f "$_tmp" 2>/dev/null || true
        return 1
    fi
    return 0
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
        touch "$_file" 2>/dev/null || {
            umo_log_warn "Cannot create patch target: $_file"
            return 0
        }
    fi

    if grep -q "$_marker" "$_file" 2>/dev/null; then
        umo_log_debug "Patch already applied: $_marker"
        return 0
    fi

    umo_fs_backup "$_file"
    if printf '\n%s\n%s\n' "$_marker" "$_content" >> "$_file" 2>/dev/null; then
        umo_log_ok "Patched: $_file"
    else
        umo_log_warn "Could not patch: $_file"
    fi
    return 0
}

umo_fs_render() {
    _template="$1"
    _output="$2"
    shift 2

    if [ ! -f "$_template" ]; then
        umo_log_warn "Template not found: $_template"
        return 1
    fi

    _content=$(cat "$_template")

    while [ "$#" -ge 2 ]; do
        _key="$1"
        _val="$2"
        shift 2
        _content=$(printf '%s' "$_content" | sed "s|{{$_key}}|$_val|g")
    done

    _remaining=$(printf '%s' "$_content" | grep -oE '\{\{[A-Z_][A-Z0-9_]*\}\}' | head -5 || true)
    if [ -n "$_remaining" ]; then
        umo_log_warn "Unreplaced placeholders in $_output: $_remaining"
    fi

    umo_fs_write "$_output" "$_content" || return 1
    return 0
}
