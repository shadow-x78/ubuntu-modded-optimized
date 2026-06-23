#!/bin/sh
# UMO — ANSI Terminal Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_ANSI_LOADED:-}" ] || return 0
_UMO_ANSI_LOADED=1

UMO_NC='\033[0m'
UMO_RESET='\033[0m'
UMO_BOLD='\033[1m'
UMO_DIM='\033[2m'
UMO_ITALIC='\033[3m'
UMO_UNDERLINE='\033[4m'
UMO_BLINK='\033[5m'
UMO_REVERSE='\033[7m'
UMO_HIDDEN='\033[8m'

UMO_BLACK='\033[0;30m'
UMO_RED='\033[0;31m'
UMO_GREEN='\033[0;32m'
UMO_YELLOW='\033[0;33m'
UMO_BLUE='\033[0;34m'
UMO_MAGENTA='\033[0;35m'
UMO_CYAN='\033[0;36m'
UMO_WHITE='\033[0;37m'
UMO_GRAY='\033[0;90m'

UMO_B_BLACK='\033[1;30m'
UMO_B_RED='\033[1;31m'
UMO_B_GREEN='\033[1;32m'
UMO_B_YELLOW='\033[1;33m'
UMO_B_BLUE='\033[1;34m'
UMO_B_MAGENTA='\033[1;35m'
UMO_B_CYAN='\033[1;36m'
UMO_B_WHITE='\033[1;37m'

UMO_BG_BLACK='\033[40m'
UMO_BG_RED='\033[41m'
UMO_BG_GREEN='\033[42m'
UMO_BG_YELLOW='\033[43m'
UMO_BG_BLUE='\033[44m'
UMO_BG_MAGENTA='\033[45m'
UMO_BG_CYAN='\033[46m'
UMO_BG_WHITE='\033[47m'
UMO_BG_GRAY='\033[100m'

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
    UMO_G_DBG='⋯';       UMO_G_RUN='⠋'
    UMO_G_BRANCH='├─';   UMO_G_LEAF='└─'
    UMO_BAR_FILL='█';    UMO_BAR_EMPTY='░'
    UMO_LINE_H='─'
else
    UMO_G_STEP='==>';    UMO_G_STEP_BLOCK='|'
    UMO_G_OK='OK';       UMO_G_ERR='ERR'
    UMO_G_WARN='!';      UMO_G_INFO='i'
    UMO_G_DBG='~';       UMO_G_RUN='*'
    UMO_G_BRANCH='-';    UMO_G_LEAF='-'
    UMO_BAR_FILL='#';    UMO_BAR_EMPTY='-'
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
umo_cursor_home() { printf '\033[H'; }
umo_screen_clear() { printf '\033[2J\033[3J\033[H'; }
umo_line_clear()   { printf '\033[2K\r'; }
umo_line_up()      { printf '\033[1A'; }

umo_color() {
    _c="$1"; shift
    printf "%b%s%b" "$_c" "$*" "$UMO_NC"
}

umo_log__time() {
    if [ "${UMO_LOG_TIME:-0}" = "1" ]; then
        printf '%s ' "$(date '+%H:%M:%S')"
    fi
}

umo_log_ok()    { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK"   "$UMO_NC" "$(umo_log__time)" "$*"; }
umo_log_err()   { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_DANGER"  "$UMO_G_ERR"  "$UMO_NC" "$(umo_log__time)" "$*" >&2; }
umo_log_warn()  { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_WARN"    "$UMO_G_WARN" "$UMO_NC" "$(umo_log__time)" "$*" >&2; }
umo_log_info()  { printf "  %b%s%b  %s%s\n" "$UMO_COLOR_INFO"    "$UMO_G_INFO" "$UMO_NC" "$(umo_log__time)" "$*"; }
umo_log_debug() { [ "${UMO_DEBUG:-0}" = "1" ] && printf "  %b%s%b  %s%s\n" "$UMO_GRAY" "$UMO_G_DBG" "$UMO_NC" "$(umo_log__time)" "$*"; }
umo_die()       { umo_log_err "$*"; exit 1; }

umo_log_step()  {
    if [ "$UMO_GLYPH_SUPPORT" -eq 1 ] 2>/dev/null; then
        printf "\n%b%s%b  %b%s%b\n" "$UMO_COLOR_PRIMARY" "$UMO_G_STEP_BLOCK" "$UMO_NC" "$UMO_BOLD" "$*" "$UMO_NC"
    else
        printf "\n%b%s%b  %b%s%b\n" "$UMO_B_CYAN" "$UMO_G_STEP" "$UMO_NC" "$UMO_BOLD" "$*" "$UMO_NC"
    fi
}

umo_log_sub()      { printf "     %b%s%b %s\n" "$UMO_COLOR_MUTED" "$UMO_G_BRANCH" "$UMO_NC" "$*"; }
umo_log_sub_last() { printf "     %b%s%b %s\n" "$UMO_COLOR_MUTED" "$UMO_G_LEAF"   "$UMO_NC" "$*"; }

umo_log_file() {
    _msg="$1"
    _logdir="${UMO_LOG_DIR:-$HOME/.umo/logs}"
    mkdir -p "$_logdir"
    _logfile="$_logdir/umo-$(date +%Y%m%d).log"
    printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$_msg" >> "$_logfile"
}

umo_progress() {
    _current="${1:-0}"
    _total="${2:-100}"
    _width="${3:-40}"
    _label="${4:-Progress}"

    [ "$_total" -le 0 ] && _total=1
    _pct=$(( _current * 100 / _total ))
    _filled=$(( _current * _width / _total ))
    _empty=$(( _width - _filled ))

    _bar_filled=$(umo_repeat "$UMO_BAR_FILL" "$_filled")
    _bar_empty=$(umo_repeat "$UMO_BAR_EMPTY" "$_empty")

    printf "\r  %b[%b%s%b%s%b] %3d%% %b%s%b" \
        "$UMO_COLOR_PRIMARY" \
        "$UMO_COLOR_SUCCESS" "$_bar_filled" \
        "$UMO_COLOR_MUTED" "$_bar_empty" \
        "$UMO_COLOR_PRIMARY" \
        "$_pct" \
        "$UMO_DIM" "$_label" "$UMO_NC"

    [ "$_current" -ge "$_total" ] && printf "\n"
}

umo_spinner() {
    _msg="$1"
    _i=0

    if [ "$UMO_GLYPH_SUPPORT" -eq 1 ] 2>/dev/null; then
        _spin_set='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        _spin_len=10
    else
        _spin_set='|/-\\'
        _spin_len=4
    fi

    umo_cursor_hide
    while true; do
        _char=$(printf '%s' "$_spin_set" | cut -c$((_i + 1))-$((_i + 1)))
        printf "\r  %b%s%b  %s%b" "$UMO_B_CYAN" "$_char" "$UMO_NC" "$_msg" "$UMO_NC"
        _i=$(( (_i + 1) % _spin_len ))
        sleep 0.08
    done
}

umo_run_quiet() {
    _label="$1"
    shift
    _logdir="${UMO_LOG_DIR:-$HOME/.umo/logs}"
    mkdir -p "$_logdir"
    _logfile="$_logdir/umo-quiet-$$.log"

    umo_spinner "$_label" &
    _spin_pid=$!

    _rc=0
    "$@" > "$_logfile" 2>&1 || _rc=$?

    kill "$_spin_pid" 2>/dev/null
    wait "$_spin_pid" 2>/dev/null || true
    umo_line_clear
    umo_cursor_show

    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  %s\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_label"
        umo_log_file "$_label"
        rm -f "$_logfile"
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

umo_rule() {
    _char="${1:-$UMO_LINE_H}"
    _cols="${2:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    printf "%b" "$UMO_COLOR_PRIMARY"
    umo_repeat "$_char" "$_cols"; printf '\n'
    printf "%b" "$UMO_NC"
}

umo_banner_full() {
    _cols="${1:-$(tput cols 2>/dev/null || echo 80)}"
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

    _tag="Ubuntu Modded Optimized · v${UMO_VERSION:-3.3.5}"
    _taglen=$(printf '%s' "$_tag" | wc -m)
    _tagpad=$(( (_cols - _taglen) / 2 )); [ "$_tagpad" -lt 0 ] && _tagpad=0
    printf "%b%*s%s%b\n" "$UMO_COLOR_ACCENT" "$_tagpad" '' "$_tag" "$UMO_NC"

    _auth="By Shadow-x78"
    _authlen=$(printf '%s' "$_auth" | wc -m)
    _authpad=$(( (_cols - _authlen) / 2 )); [ "$_authpad" -lt 0 ] && _authpad=0
    printf "%b%*s%s%b\n\n" "$UMO_COLOR_MUTED" "$_authpad" '' "$_auth" "$UMO_NC"
}

umo_banner_compact() {
    umo_banner_full "$@"
}

umo_banner() {
    _w=$(tput cols 2>/dev/null || echo 60)
    umo_banner_full "$_w"
}

umo_logo() {
    printf "%b[UMO]%b %s\n" "$UMO_COLOR_PRIMARY" "$UMO_NC" "$*"
}

umo_badge() {
    _cols="${1:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    _ver="${UMO_VERSION:-3.3.5}"
    _edition="${UMO_EDITION:-Open Source}"
    _txt="v$_ver — $_edition Edition"
    _txtlen=$(printf '%s' "$_txt" | wc -m)
    _pad=$(( (_cols - _txtlen) / 2 )); [ "$_pad" -lt 0 ] && _pad=0
    printf "%b%*s%s%b\n" "$UMO_DIM" "$_pad" '' "$_txt" "$UMO_NC"
}

umo_kv() {
    _k="$1"; _v="$2"
    printf "  %b%-20s%b %b%s%b\n" "$UMO_B_WHITE" "$_k:" "$UMO_NC" "$UMO_B_GREEN" "$_v" "$UMO_NC"
}
