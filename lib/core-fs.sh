#!/bin/sh

[ -z "${_UMO_FS_LOADED:-}" ] || return 0
_UMO_FS_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_fs_mkdir() {
    _fs_rc=0
    for _dir in "$@"; do
        if [ ! -d "$_dir" ]; then
            if ! mkdir -p "$_dir" 2>/dev/null; then
                umo_log_warn "Cannot Create Directory: $(umo_fs_display_path "$_dir")"
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
        umo_log_warn "Cannot Write: $(umo_fs_display_path "$_tmp")"
        return 1
    fi
    if ! mv -f "$_tmp" "$_file" 2>/dev/null; then
        umo_log_warn "Cannot Finalize: $(umo_fs_display_path "$_file")"
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
        umo_log_info "Backup Created: $(umo_fs_display_path "$_bak")"
    fi
}

umo_fs_patch() {
    _file="$1"
    _marker="$2"
    _content="$3"

    if [ ! -f "$_file" ]; then
        touch "$_file" 2>/dev/null || {
            umo_log_warn "Cannot Create Patch Target: $(umo_fs_display_path "$_file")"
            return 0
        }
    fi

    if grep -q "$_marker" "$_file" 2>/dev/null; then
        umo_log_debug "Patch Already Applied: $_marker"
        return 0
    fi

    umo_fs_backup "$_file"
    if printf '\n%s\n%s\n' "$_marker" "$_content" >> "$_file" 2>/dev/null; then
        umo_log_ok "Patched: $(umo_fs_display_path "$_file")"
    else
        umo_log_warn "Could Not Patch: $(umo_fs_display_path "$_file")"
    fi
    return 0
}

umo_fs_display_path() {
    _mdp="$1"
    _mdp_base="/data/data/com.termux/files"
    if [ -n "${PREFIX:-}" ]; then
        _mdp_files=$(cd "${PREFIX%/}/.." 2>/dev/null && pwd) || _mdp_files=""
        case "$_mdp_files" in
            */files) _mdp_base="$_mdp_files" ;;
        esac
    fi
    case "$_mdp" in
        "$_mdp_base")   printf '%s' "/" ;;
        "$_mdp_base"/*) printf '%s' "${_mdp#"$_mdp_base"}" ;;
        *)              printf '%s' "$_mdp" ;;
    esac
}

umo_fs_render() {
    _template="$1"
    _output="$2"
    shift 2

    if [ ! -f "$_template" ]; then
        umo_log_warn "Template Not Found: $(umo_fs_display_path "$_template")"
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
        umo_log_warn "Unreplaced Placeholders In $(umo_fs_display_path "$_output"): $_remaining"
    fi

    umo_fs_write "$_output" "$_content" || return 1
    return 0
}
