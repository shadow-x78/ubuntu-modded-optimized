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
    UMO_GRAD_1=''
    UMO_GRAD_2=''
    UMO_GRAD_3=''
fi

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
    _spin='|/-\\'
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
    _char="${1:--}"
    _cols="${2:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    printf "%b" "$UMO_COLOR_PRIMARY"
    printf '%*s\n' "$_cols" '' | tr ' ' "$_char"
    printf "%b" "$UMO_NC"
}

umo_banner_full() {
    _cols="${1:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"

    _l1=' __  __  ___ '
    _l2='|  \/  |/ _ \'
    _l3='| |\/| | | | |'
    _l4='| |  | | |_| |'
    _l5='|_|  |_|\___/ '
    _l6='             '

    _len1=13
    _len2=14
    _len3=14
    _len4=14
    _len5=14
    _len6=13

    _pad1=$(( (_cols - _len1) / 2 )); [ "$_pad1" -lt 0 ] && _pad1=0
    _pad2=$(( (_cols - _len2) / 2 )); [ "$_pad2" -lt 0 ] && _pad2=0
    _pad3=$(( (_cols - _len3) / 2 )); [ "$_pad3" -lt 0 ] && _pad3=0
    _pad4=$(( (_cols - _len4) / 2 )); [ "$_pad4" -lt 0 ] && _pad4=0
    _pad5=$(( (_cols - _len5) / 2 )); [ "$_pad5" -lt 0 ] && _pad5=0
    _pad6=$(( (_cols - _len6) / 2 )); [ "$_pad6" -lt 0 ] && _pad6=0

    printf "%b%*s%s%b\n" "$UMO_GRAD_1" "$_pad1" '' "$_l1" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_2" "$_pad2" '' "$_l2" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_3" "$_pad3" '' "$_l3" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_3" "$_pad4" '' "$_l4" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_2" "$_pad5" '' "$_l5" "$UMO_NC"
    printf "%b%*s%s%b\n" "$UMO_GRAD_1" "$_pad6" '' "$_l6" "$UMO_NC"

    _tag="Ubuntu Modded Optimized v${UMO_VERSION:-3.1.0}"
    _taglen=$(printf '%s' "$_tag" | wc -m)
    _tagpad=$(( (_cols - _taglen) / 2 )); [ "$_tagpad" -lt 0 ] && _tagpad=0
    printf "%b%*s%s%b\n" "$UMO_COLOR_ACCENT" "$_tagpad" '' "$_tag" "$UMO_NC"

    _auth="by Shadow-x78"
    _authlen=$(printf '%s' "$_auth" | wc -m)
    _authpad=$(( (_cols - _authlen) / 2 )); [ "$_authpad" -lt 0 ] && _authpad=0
    printf "%b%*s%s%b\n\n" "$UMO_COLOR_MUTED" "$_authpad" '' "$_auth" "$UMO_NC"
}

umo_banner_compact() {
    _ver="${UMO_VERSION:-3.1.0}"
    printf "%b[UMO]%b Ubuntu Modded Optimized %bv%s%b — Shadow-x78\n" \
        "$UMO_COLOR_PRIMARY" "$UMO_NC" "$UMO_BOLD" "$_ver" "$UMO_NC"
}

umo_banner() {
    _w=$(tput cols 2>/dev/null || echo 60)
    if [ "${_w:-0}" -ge 78 ]; then
        umo_banner_full "$_w"
    else
        umo_banner_compact
    fi
}

umo_logo() {
    printf "%b[UMO]%b %s\n" "$UMO_COLOR_PRIMARY" "$UMO_NC" "$*"
}

umo_badge() {
    _cols="${1:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
    _ver="${UMO_VERSION:-3.1.0}"
    _edition="${UMO_EDITION:-Open Source}"
    _txt="v$_ver — $_edition Edition"
    _txtlen=$(printf '%s' "$_txt" | wc -m)
    _pad=$(( (_cols - _txtlen) / 2 )); [ "$_pad" -lt 0 ] && _pad=0
    printf "%b%*s%s%b\n" "$UMO_DIM" "$_pad" '' "$_txt" "$UMO_NC"
}

umo_box() {
    _title="$1"
    _width="${2:-60}"
    _cols="${3:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"

    [ "$_width" -gt "$((_cols - 4))" ] 2>/dev/null && _width=$((_cols - 4))
    [ "$_width" -lt 40 ] 2>/dev/null && _width=40

    _left=$(( (_cols - _width) / 2 )); [ "$_left" -lt 0 ] && _left=0

    printf "%b" "$UMO_COLOR_PRIMARY"
    printf "%*s+%*s+\n" "$_left" '' "$((_width-2))" '' | tr ' ' '-'
    if [ -n "$_title" ]; then
        _tlen=$(printf '%s' "$_title" | wc -m)
        _pad=$(( (_width - 2 - _tlen) / 2 )); [ "$_pad" -lt 1 ] && _pad=1
        printf "%*s|%*s%s%*s|\n" "$_left" '' "$_pad" '' "$_title" "$((_width-2-_tlen-_pad))" ''
        printf "%*s+%*s+\n" "$_left" '' "$((_width-2))" '' | tr ' ' '-'
    fi
    printf "%b" "$UMO_NC"
}

umo_kv() {
    _k="$1"; _v="$2"
    printf "  %b%-20s%b %b%s%b\n" "$UMO_B_WHITE" "$_k:" "$UMO_NC" "$UMO_B_GREEN" "$_v" "$UMO_NC"
}
