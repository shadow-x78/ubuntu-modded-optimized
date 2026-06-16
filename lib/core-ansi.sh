#!/bin/sh
# UMO — ANSI Terminal Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

# Strict mode guard
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

umo_cursor_hide() { printf '\033[?25l'; }
umo_cursor_show() { printf '\033[?25h'; }
umo_cursor_home() { printf '\033[H'; }
umo_screen_clear() { printf '\033[2J\033[H'; }
umo_line_clear()   { printf '\033[2K\r'; }
umo_line_up()      { printf '\033[1A'; }

umo_color() {
    _c="$1"; shift
    printf "%b%s%b" "$_c" "$*" "$UMO_NC"
}

# UMO Brand Palette (256-color)
UMO_COLOR_PRIMARY='\033[38;5;33m'
UMO_COLOR_ACCENT='\033[38;5;135m'
UMO_COLOR_DANGER='\033[38;5;160m'
UMO_COLOR_SUCCESS='\033[38;5;34m'

umo_log_ok()    { printf "%b[OK]%b  %s\n" "$UMO_B_GREEN" "$UMO_NC" "$*"; }
umo_log_err()   { printf "%b[ERR]%b %s\n" "$UMO_B_RED"   "$UMO_NC" "$*" >&2; }
umo_log_warn()  { printf "%b[WARN]%b %s\n" "$UMO_B_YELLOW" "$UMO_NC" "$*" >&2; }
umo_log_info()  { printf "%b[INFO]%b %s\n" "$UMO_B_BLUE"  "$UMO_NC" "$*"; }
umo_log_step()  { printf "%b[==>]%b %s\n" "$UMO_B_CYAN"  "$UMO_NC" "$*"; }
umo_log_debug() { [ "${UMO_DEBUG:-0}" = "1" ] && printf "%b[DBG]%b  %s\n" "$UMO_GRAY" "$UMO_NC" "$*"; }
umo_die()       { umo_log_err "$*"; exit 1; }

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

    printf "\r%b[%b%*s%b%*s%b] %3d%% %b%s%b" \
        "$UMO_B_BLUE" \
        "$UMO_B_GREEN" "$_filled" '' \
        "$UMO_B_BLACK" "$_empty" '' \
        "$UMO_B_BLUE" \
        "$_pct" \
        "$UMO_DIM" "$_label" "$UMO_NC"

    [ "$_current" -ge "$_total" ] && printf "\n"
}

umo_spinner() {
    _msg="$1"
    _pid="$2"
    _spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    _i=0

    umo_cursor_hide
    while kill -0 "$_pid" 2>/dev/null; do
        _char=$(printf '%s' "$_spin" | cut -c$((_i+1))-$((_i+1)))
        printf "\r%b%s%b %s%b" "$UMO_B_CYAN" "$_char" "$UMO_NC" "$_msg" "$UMO_NC"
        _i=$(( (_i + 1) % 10 ))
        sleep 0.08
    done
    umo_line_clear
    umo_cursor_show
}

umo_rule() {
    _char="${1:-═}"
    _cols="${2:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    printf "%b" "$UMO_B_BLUE"
    printf '%*s\n' "$_cols" '' | tr ' ' "$_char"
    printf "%b" "$UMO_NC"
}

umo_banner_full() {
    printf "%b\n" "$UMO_COLOR_PRIMARY"
    printf "  ██╗   ██╗███╗   ███╗ ██████╗\n"
    printf "  ██║   ██║████╗ ████║██╔═══██╗\n"
    printf "  ██║   ██║██╔████╔██║██║   ██║\n"
    printf "  ██║   ██║██║╚██╔╝██║██║   ██║\n"
    printf "  ╚██████╔╝██║ ╚═╝ ██║╚██████╔╝\n"
    printf "   ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ %b\n" "$UMO_NC"
    printf "%b      Ubuntu Modded Optimized — by Shadow-x78%b\n" "$UMO_COLOR_ACCENT" "$UMO_NC"
    printf "\n"
}

umo_banner_compact() {
    printf "%b[UMO]%b Ubuntu Modded Optimized v%b%s%b — Shadow-x78\n" \
        "$UMO_COLOR_PRIMARY" "$UMO_NC" "$UMO_BOLD" "${UMO_VERSION:-3.0.0}" "$UMO_NC"
}

umo_banner() {
    _w=$(tput cols 2>/dev/null || echo 60)
    if [ "${_w:-0}" -ge 78 ]; then
        umo_banner_full
    else
        umo_banner_compact
    fi
}

umo_logo() {
    printf "%b[UMO]%b %s\n" "$UMO_COLOR_PRIMARY" "$UMO_NC" "$*"
}

umo_badge() {
    _ver="${UMO_VERSION:-3.0.0}"
    _edition="${UMO_EDITION:-Open Source}"
    printf "%b v%s — %s Edition %b\n" "$UMO_DIM" "$_ver" "$_edition" "$UMO_NC"
}

umo_box() {
    _title="$1"
    _width="${2:-60}"
    _cols="${3:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    _left=$(( (_cols - _width) / 2 )); [ "$_left" -lt 0 ] && _left=0

    printf "%b" "$UMO_B_BLUE"
    printf "%*s╔%*s╗\n" "$_left" '' "$((_width-2))" '' | tr ' ' '═'
    if [ -n "$_title" ]; then
        _tlen=$(printf '%s' "$_title" | wc -m)
        _pad=$(( (_width - 2 - _tlen) / 2 )); [ "$_pad" -lt 1 ] && _pad=1
        printf "%*s║%*s%s%*s║\n" "$_left" '' "$_pad" '' "$_title" "$((_width-2-_tlen-_pad))" ''
        printf "%*s╠%*s╣\n" "$_left" '' "$((_width-2))" '' | tr ' ' '═'
    fi
    printf "%b" "$UMO_NC"
}

umo_kv() {
    _k="$1"; _v="$2"
    printf "  %b%-20s%b %b%s%b\n" "$UMO_B_WHITE" "$_k:" "$UMO_NC" "$UMO_B_GREEN" "$_v" "$UMO_NC"
}
