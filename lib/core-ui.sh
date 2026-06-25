#!/bin/sh
# UMO — TUI Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

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

umo_ui_footer() {
    _text="${1:-Press [Enter] to continue...}"
    printf "\n%b%s%b" "$UMO_DIM" "$_text" "$UMO_NC"
    read -r _umo_dummy
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
                UMO_MENU_RESULT="$_opt"
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

umo_ui_input() {
    _prompt="$1"
    _default="${2:-}"

    if [ -n "$_default" ]; then
        printf "%b  %s %b[%s]%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_B_YELLOW" "$_default" "$UMO_NC"
    else
        printf "%b  %s%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_NC"
    fi
    read -r _ans
    if [ -z "$_ans" ] && [ -n "$_default" ]; then
        _ans="$_default"
    fi
    UMO_INPUT_RESULT="$_ans"
}

umo_ui_password() {
    _prompt="$1"
    printf "%b  %s (input hidden)%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_NC"
    read -r _ans
    UMO_INPUT_RESULT="$_ans"
}

umo_ui_checklist() {
    _title="$1"; shift

    umo_screen_clear
    umo_banner
    printf "\n"
    printf "  %b%b%b\n" "$UMO_BOLD" "$_title" "$UMO_NC"
    printf "  %b" "$UMO_COLOR_PRIMARY"
    _cl_plain=$(printf '%s' "$_title" | sed "s/$(printf '\033')\[[0-9;]*m//g")
    _cl_len=$(printf '%s' "$_cl_plain" | wc -m)
    [ "$_cl_len" -lt 1 ] && _cl_len=1
    umo_repeat "$UMO_LINE_H" "$_cl_len"
    printf "%b\n\n" "$UMO_NC"

    _idx=0
    for _item in "$@"; do
        _idx=$((_idx + 1))
        eval "_chk_${_idx}=\"0\""
        eval "_lbl_${_idx}=\"$_item\""
    done
    _total="$_idx"

    if [ "${UMO_GLYPH_SUPPORT:-0}" -eq 1 ]; then
        _mark_on="◉"
        _mark_off="○"
    else
        _mark_on="X"
        _mark_off=" "
    fi

    while true; do
        _i=0
        while [ "$_i" -lt "$_total" ]; do
            _i=$((_i + 1))
            eval "_state=\"\$_chk_${_i}\""
            eval "_label=\"\$_lbl_${_i}\""
            if [ "$_state" = "1" ]; then
                _mark="$_mark_on"
                _mfix="$UMO_B_GREEN"
            else
                _mark="$_mark_off"
                _mfix="$UMO_DIM"
            fi
            printf "  %b%-2s%b  %b[%s]%b  %s\n" "$UMO_B_CYAN" "$_i" "$UMO_NC" "$_mfix" "$_mark" "$UMO_NC" "$_label"
        done

        printf "\n  %bEnter numbers to toggle (space-separated), or press Enter to confirm:%b " "$UMO_DIM" "$UMO_NC"
        read -r _num_input
        _num_input=$(printf '%s' "$_num_input" | tr -d '\r')

        if [ -z "$_num_input" ]; then
            break
        fi

        for _num in $_num_input; do
            case "$_num" in
                *[!0-9]*) continue ;;
            esac
            if [ "$_num" -ge 1 ] && [ "$_num" -le "$_total" ] 2>/dev/null; then
                eval "_old=\"\$_chk_${_num}\""
                if [ "$_old" = "1" ]; then
                    eval "_chk_${_num}=\"0\""
                else
                    eval "_chk_${_num}=\"1\""
                fi
            fi
        done

        umo_screen_clear
        umo_banner
        printf "\n"
        printf "  %b%b%b\n" "$UMO_BOLD" "$_title" "$UMO_NC"
        printf "  %b" "$UMO_COLOR_PRIMARY"
        umo_repeat "$UMO_LINE_H" "$_cl_len"
        printf "%b\n\n" "$UMO_NC"
    done

    UMO_CHECKLIST_RESULT=""
    _i=0
    while [ "$_i" -lt "$_total" ]; do
        _i=$((_i + 1))
        eval "_state=\"\$_chk_${_i}\""
        if [ "$_state" = "1" ]; then
            eval "_label=\"\$_lbl_${_i}\""
            UMO_CHECKLIST_RESULT="$UMO_CHECKLIST_RESULT$_label "
        fi
    done
}

umo_ui_pause() {
    _msg="${1:-Press [Enter] to continue...}"
    printf "\n%b  %s%b" "$UMO_DIM" "$_msg" "$UMO_NC"
    read -r _dummy
}
