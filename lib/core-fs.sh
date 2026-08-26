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
                umo_log_warn "Cannot Create Directory: $_dir"
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
        umo_log_warn "Cannot Write: $_tmp"
        return 1
    fi
    if ! mv -f "$_tmp" "$_file" 2>/dev/null; then
        umo_log_warn "Cannot Finalize: $_file"
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
        umo_log_info "Backup Created: $_bak"
    fi
}

umo_fs_patch() {
    _file="$1"
    _marker="$2"
    _content="$3"

    if [ ! -f "$_file" ]; then
        touch "$_file" 2>/dev/null || {
            umo_log_warn "Cannot Create Patch Target: $_file"
            return 0
        }
    fi

    if grep -q "$_marker" "$_file" 2>/dev/null; then
        umo_log_debug "Patch Already Applied: $_marker"
        return 0
    fi

    umo_fs_backup "$_file"
    if printf '\n%s\n%s\n' "$_marker" "$_content" >> "$_file" 2>/dev/null; then
        umo_log_ok "Patched: $_file"
    else
        umo_log_warn "Could Not Patch: $_file"
    fi
    return 0
}

# Shorten a Termux host path for display: the Termux base prefix
# (/data/data/com.termux/files) is stripped so $HOME/umo-ubuntu prints
# as /home/umo-ubuntu. Paths outside the base are returned unchanged.
umo_fs_display_path() {
    _mdp="$1"
    _mdp_base="${PREFIX:-/data/data/com.termux/files}"
    case "$_mdp" in
        "$_mdp_base"/*) printf '%s' "${_mdp#"$_mdp_base"}" ;;
        *)              printf '%s' "$_mdp" ;;
    esac
}

umo_fs_render() {
    _template="$1"
    _output="$2"
    shift 2

    if [ ! -f "$_template" ]; then
        umo_log_warn "Template Not Found: $_template"
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
        umo_log_warn "Unreplaced Placeholders In $_output: $_remaining"
    fi

    umo_fs_write "$_output" "$_content" || return 1
    return 0
}
