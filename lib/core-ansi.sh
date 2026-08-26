#!/bin/sh
# UMO - Core Library: ANSI Colors, Logging, Spinner (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

[ -z "${_UMO_ANSI_LOADED:-}" ] || return 0
_UMO_ANSI_LOADED=1

UMO_NC='\033[0m'
UMO_BOLD='\033[1m'
UMO_DIM='\033[2m'

UMO_B_CYAN='\033[1;36m'
UMO_B_GREEN='\033[1;32m'
UMO_B_YELLOW='\033[1;33m'
UMO_B_WHITE='\033[1;37m'

UMO_COLOR_SUPPORT=0
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -z "${UMO_NO_256:-}" ]; then
    _umo_colors=$(tput colors 2>/dev/null || echo 0)
    if [ "$_umo_colors" -ge 256 ] 2>/dev/null; then
        UMO_COLOR_SUPPORT=256
    elif [ "$_umo_colors" -ge 16 ] 2>/dev/null; then
        UMO_COLOR_SUPPORT=16
    fi
fi

if [ "$UMO_COLOR_SUPPORT" -eq 256 ] 2>/dev/null; then
    UMO_COLOR_PRIMARY='\033[38;5;208m'
    UMO_COLOR_ACCENT='\033[38;5;135m'
    UMO_COLOR_INFO='\033[38;5;39m'
    UMO_COLOR_MUTED='\033[38;5;245m'
    UMO_COLOR_DANGER='\033[38;5;160m'
    UMO_COLOR_SUCCESS='\033[38;5;34m'
    UMO_COLOR_WARN='\033[38;5;220m'
    UMO_GRAD_1='\033[38;5;208m'
    UMO_GRAD_2='\033[38;5;214m'
    UMO_GRAD_3='\033[38;5;220m'
elif [ "$UMO_COLOR_SUPPORT" -eq 16 ] 2>/dev/null; then
    UMO_COLOR_PRIMARY='\033[1;33m'
    UMO_COLOR_ACCENT='\033[1;35m'
    UMO_COLOR_INFO='\033[1;36m'
    UMO_COLOR_MUTED='\033[0;37m'
    UMO_COLOR_DANGER='\033[1;31m'
    UMO_COLOR_SUCCESS='\033[1;32m'
    UMO_COLOR_WARN='\033[1;33m'
    UMO_GRAD_1='\033[0;33m'
    UMO_GRAD_2='\033[1;33m'
    UMO_GRAD_3='\033[1;37m'
else
    UMO_COLOR_PRIMARY=''
    UMO_COLOR_ACCENT=''
    UMO_COLOR_INFO=''
    UMO_COLOR_MUTED=''
    UMO_COLOR_DANGER=''
    UMO_COLOR_SUCCESS=''
    UMO_COLOR_WARN=''
    UMO_GRAD_1=''
    UMO_GRAD_2=''
    UMO_GRAD_3=''
fi

UMO_GLYPH_SUPPORT=0
_UMO_SPINNER_PID=""
if [ -z "${UMO_ASCII:-}" ]; then
    case "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" in
        *UTF-8*|*utf8*) [ -t 1 ] && UMO_GLYPH_SUPPORT=1 ;;
    esac
    if [ "$UMO_GLYPH_SUPPORT" -eq 0 ] 2>/dev/null && command -v locale >/dev/null 2>&1; then
        _umo_charmap=$(locale charmap 2>/dev/null || true)
        case "$_umo_charmap" in
            UTF-8*|utf-8*) [ -t 1 ] && UMO_GLYPH_SUPPORT=1 ;;
        esac
    fi
fi

if [ "$UMO_GLYPH_SUPPORT" -eq 1 ] 2>/dev/null; then
    UMO_G_STEP='❯';      UMO_G_STEP_BLOCK='▌'
    UMO_G_OK='✔';        UMO_G_ERR='✖'
    UMO_G_WARN='⚠';      UMO_G_INFO='ℹ'
    UMO_G_DBG='⋯'
    UMO_LINE_H='─'
else
    UMO_G_STEP='==>';    UMO_G_STEP_BLOCK='|'
    UMO_G_OK='OK';       UMO_G_ERR='ERR'
    UMO_G_WARN='!';      UMO_G_INFO='i'
    UMO_G_DBG='~'
    UMO_LINE_H='-'
fi

umo_repeat() {
    _rc_char="$1"; _rc_count="$2"
    _rc_out=''
    _rc_i=0
    [ "$_rc_count" -lt 0 ] 2>/dev/null && _rc_count=0
    while [ "$_rc_i" -lt "$_rc_count" ]; do
        _rc_out="$_rc_out$_rc_char"
        _rc_i=$(( _rc_i + 1 ))
    done
    printf '%s' "$_rc_out"
}

umo_cursor_hide() { printf '\033[?25l'; }
umo_cursor_show() { printf '\033[?25h'; }
umo_screen_clear() { printf '\033[2J\033[3J\033[H'; }
umo_line_clear()   { printf '\033[2K\r'; }

umo_log__time() {
    if [ "${UMO_LOG_TIME:-0}" = "1" ]; then
        printf '%s ' "$(date '+%H:%M:%S')"
    fi
}

umo_log_ok()    { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK"   "$UMO_NC" "$(umo_log__time)" "$*"; }
umo_log_err()   { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_DANGER"  "$UMO_G_ERR"  "$UMO_NC" "$(umo_log__time)" "$*" >&2; }
umo_log_warn()  { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_WARN"    "$UMO_G_WARN" "$UMO_NC" "$(umo_log__time)" "$*" >&2; }
umo_log_info()  { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_INFO"    "$UMO_G_INFO" "$UMO_NC" "$(umo_log__time)" "$*"; }
umo_log_debug() {
    if [ "${UMO_DEBUG:-0}" = "1" ]; then
        printf "  %b%s%b  %s%s\n" "$UMO_COLOR_MUTED" "$UMO_G_DBG" "$UMO_NC" "$(umo_log__time)" "$*"
    fi
    return 0
}

umo_die()       { umo_log_err "$*"; exit 1; }

umo_log_step()  {
    if [ "$UMO_GLYPH_SUPPORT" -eq 1 ] 2>/dev/null; then
        printf "\n%b%s%b  %b%s%b\n" "$UMO_COLOR_PRIMARY" "$UMO_G_STEP_BLOCK" "$UMO_NC" "$UMO_BOLD" "$*" "$UMO_NC"
    else
        printf "\n%b%s%b  %b%s%b\n" "$UMO_B_CYAN" "$UMO_G_STEP" "$UMO_NC" "$UMO_BOLD" "$*" "$UMO_NC"
    fi
}

umo_log_file() {
    _msg="$1"
    _logdir="${UMO_LOG_DIR:-$HOME/.umo/logs}"
    mkdir -p "$_logdir"
    _logfile="$_logdir/umo-$(date +%Y%m%d).log"
    printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$_msg" >> "$_logfile"
}

umo_spinner() {
    _msg="$1"
    _i=0

    if [ "$UMO_GLYPH_SUPPORT" -eq 1 ] 2>/dev/null; then
        set -- "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
        _spin_len=10
    else
        set -- "|" "/" "-" "\\"
        _spin_len=4
    fi

    umo_cursor_hide
    while true; do
        _idx=$((_i + 1))
        eval "_char=\${$_idx}"
        printf "\r  %b%s%b  %s%b" "$UMO_B_CYAN" "$_char" "$UMO_NC" "$_msg" "$UMO_NC"
        _i=$(( (_i + 1) % _spin_len ))
        sleep 0.25
    done
}

umo_run_quiet() {
    _label="$1"
    shift
    _logdir="${UMO_LOG_DIR:-$HOME/.umo/logs}"
    mkdir -p "$_logdir" 2>/dev/null || true
    _logfile="$_logdir/umo-quiet-$$.log"

    umo_spinner "$_label" &
    _UMO_SPINNER_PID=$!

    _rc=0
    "$@" </dev/null > "$_logfile" 2>&1 || _rc=$?

    umo_spinner_stop

    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  %s\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_label"
        umo_log_file "$_label"
        rm -f "$_logfile" 2>/dev/null || true
        return 0
    else
        printf "  %b%s%b  %s failed\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_label"
        if [ -s "$_logfile" ]; then
            printf "  %bLast 30 lines of log:%b\n" "$UMO_DIM" "$UMO_NC"
            tail -n 30 "$_logfile" 2>/dev/null | while IFS= read -r _line; do
                printf "    %s\n" "$_line"
            done
        fi
        return 1
    fi
}

_umo_stream_filter() {
    grep -vE "^(Get:[0-9]|Ign:|Hit:[0-9]|Reading package|Building dependency|debconf:)" || true
}

umo_run_stream() {
    _label="$1"
    shift

    umo_log_step "$_label"

    _stamp="${TMPDIR:-/tmp}/umo-stream-rc.$$"
    {
        "$@" </dev/null 2>&1
        printf '%s' "$?" > "$_stamp" 2>/dev/null || true
    } | _umo_stream_filter

    _rc="$(cat "$_stamp" 2>/dev/null || echo 0)"
    rm -f "$_stamp" 2>/dev/null || true

    if [ "$_rc" = "0" ]; then
        umo_log_ok "$_label"
    else
        umo_log_warn "$_label finished with warnings (code $_rc)"
    fi
    return 0
}

umo_spinner_stop() {
    if [ -n "${_UMO_SPINNER_PID:-}" ]; then
        kill -KILL "$_UMO_SPINNER_PID" 2>/dev/null || true
        wait "$_UMO_SPINNER_PID" 2>/dev/null || true
        _UMO_SPINNER_PID=""
    fi
    umo_line_clear
    umo_cursor_show 2>/dev/null || true
}

umo_term_cols() {
    if [ -z "${UMO_TERM_COLS:-}" ]; then
        UMO_TERM_COLS=$(tput cols 2>/dev/null || echo 80)
        [ -z "$UMO_TERM_COLS" ] && UMO_TERM_COLS=80
    fi
    printf '%s' "$UMO_TERM_COLS"
}

umo_rule() {
    _char="${1:-$UMO_LINE_H}"
    _cols="${2:-$(umo_term_cols)}"
    _cols="${_cols:-80}"
    printf "%b" "$UMO_COLOR_PRIMARY"
    umo_repeat "$_char" "$_cols"; printf '\n'
    printf "%b" "$UMO_NC"
}

umo_banner_full() {
    _cols="${1:-$(umo_term_cols)}"
    _cols="${_cols:-80}"

    _l1='██╗   ██╗███╗   ███╗ ██████╗  '
    _l2='██║   ██║████╗ ████║██╔═══██╗ '
    _l3='██║   ██║██╔████╔██║██║   ██║ '
    _l4='██║   ██║██║╚██╔╝██║██║   ██║ '
    _l5='╚██████╔╝██║ ╚═╝ ██║╚██████╔╝ '
    _l6=' ╚═════╝ ╚═╝     ╚═╝ ╚═════╝  '

    _logo_w=30
    _pad=$(( (_cols - _logo_w) / 2 )); [ "$_pad" -lt 0 ] && _pad=0

    printf "%b%*s%s%b\n" "$UMO_GRAD_1" "$_pad" '' "$_l1" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_2" "$_pad" '' "$_l2" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_3" "$_pad" '' "$_l3" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_3" "$_pad" '' "$_l4" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_2" "$_pad" '' "$_l5" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_1" "$_pad" '' "$_l6" "$UMO_NC"
    printf '\n'

    _tag="Ubuntu Modded Optimized · v${UMO_VERSION:-4.15.0}"
    _taglen=$(printf '%s' "$_tag" | wc -m)
    _tagpad=$(( (_cols - _taglen) / 2 )); [ "$_tagpad" -lt 0 ] && _tagpad=0
    printf "%b%*s%s%b\n" "$UMO_COLOR_ACCENT" "$_tagpad" '' "$_tag" "$UMO_NC"

    _auth="By shadow-x78"
    _authlen=$(printf '%s' "$_auth" | wc -m)
    _authpad=$(( (_cols - _authlen) / 2 )); [ "$_authpad" -lt 0 ] && _authpad=0
    printf "%b%*s%s%b\n\n" "$UMO_COLOR_MUTED" "$_authpad" '' "$_auth" "$UMO_NC"
}

umo_banner() {
    umo_banner_full "$(umo_term_cols)"
}

umo_kv() {
    _k="$1"; _v="$2"
    printf "  %b%-20s%b %b%s%b\n" "$UMO_B_WHITE" "$_k:" "$UMO_NC" "$UMO_B_GREEN" "$_v" "$UMO_NC"
}
