#!/bin/sh

[ -z "${_UMO_UI_LOADED:-}" ] || return 0
_UMO_UI_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_ui_init() {
    printf '\033[3J'
    umo_screen_clear
    umo_banner
    printf "\n"
}

umo_ui_header() {
    _text="$1"
    _raw_text=$(printf '%b' "$_text" | sed "s/$(printf '\033')\[[0-9;]*m//g")
    _txtlen=$(printf '%s' "$_raw_text" | wc -m)

    umo_screen_clear
    umo_banner

    printf "\n"
    printf "  %b%b%b\n" "$UMO_BOLD" "$_text" "$UMO_NC"
    printf "  %b" "$UMO_COLOR_PRIMARY"
    _rule_len="$_txtlen"
    [ "$_rule_len" -lt 1 ] && _rule_len=1
    umo_repeat "$UMO_LINE_H" "$_rule_len"
    printf "%b\n" "$UMO_NC"
}

umo_ui_menu() {
    _title="$1"; shift

    umo_screen_clear
    umo_banner
    printf "\n"
    printf "  %b%b%b\n" "$UMO_BOLD" "$_title" "$UMO_NC"
    printf "  %b" "$UMO_COLOR_PRIMARY"
    _title_plain=$(printf '%s' "$_title" | sed "s/$(printf '\033')\[[0-9;]*m//g")
    _title_len=$(printf '%s' "$_title_plain" | wc -m)
    [ "$_title_len" -lt 1 ] && _title_len=1
    umo_repeat "$UMO_LINE_H" "$_title_len"
    printf "%b\n\n" "$UMO_NC"

    if [ "${UMO_GLYPH_SUPPORT:-0}" -eq 1 ]; then
        _bullet="❯"
        _prompt="╰─➤"
    else
        _bullet="*"
        _prompt="=>"
    fi

    _opt_num=0
    for _opt in "$@"; do
        _opt_num=$((_opt_num + 1))
        printf "  %b %s %b %b%-2s%b  %s\n" "$UMO_COLOR_PRIMARY" "$_bullet" "$UMO_NC" "$UMO_B_CYAN" "$_opt_num" "$UMO_NC" "$_opt"
    done
    printf "\n"

    while true; do
        printf "  %b%s%b Select an option %b[1-%d]%b: " "$UMO_COLOR_SUCCESS" "$_prompt" "$UMO_NC" "$UMO_DIM" "$_opt_num" "$UMO_NC"
        read -r _choice
        _choice=$(printf '%s' "$_choice" | tr -d '\r')

        case "$_choice" in
            ''|*[!0-9]*)
                umo_log_warn "Invalid choice. Please enter a number 1-$_opt_num"
                continue
                ;;
        esac

        if [ "$_choice" -lt 1 ] || [ "$_choice" -gt "$_opt_num" ]; then
            umo_log_warn "Choice out of range. Please enter 1-$_opt_num"
            continue
        fi

        _idx=0
        for _opt in "$@"; do
            _idx=$((_idx + 1))
            if [ "$_idx" -eq "$_choice" ]; then
                UMO_MENU_IDX="$_choice"
                printf "\n%b  %s Selected:%b %s\n\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC" "$_opt"
                return 0
            fi
        done
    done
}

umo_ui_confirm() {
    _prompt="$1"
    _default="${2:-Y}"

    while true; do
        _def_lower=$(printf '%s' "$_default" | tr '[:upper:]' '[:lower:]')
        if [ "$_def_lower" = "y" ]; then
            printf "%b  %s %b[%s/%s]%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_B_YELLOW" "Y" "n" "$UMO_NC"
        else
            printf "%b  %s %b[%s/%s]%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_B_YELLOW" "y" "N" "$UMO_NC"
        fi
        read -r _ans
        [ -z "$_ans" ] && _ans="$_default"
        _ans_lower=$(printf '%s' "$_ans" | tr '[:upper:]' '[:lower:]')
        case "$_ans_lower" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) umo_log_warn "Please answer yes or no" ;;
        esac
    done
}
