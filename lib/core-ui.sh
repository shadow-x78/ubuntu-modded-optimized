#!/bin/sh
# UMO — TUI Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_UI_LOADED:-}" ] || return 0
_UMO_UI_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_ui_init() {
    umo_screen_clear
    umo_banner
    umo_rule
}

umo_ui_header() {
    _text="$1"
    printf "\n%b%s%b\n\n" "$UMO_COLOR_PRIMARY" "$_text" "$UMO_NC"
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
    umo_rule
    printf "\n%b  => %s%b\n\n" "$UMO_COLOR_PRIMARY" "$_title" "$UMO_NC"

    _opt_num=0
    for _opt in "$@"; do
        _opt_num=$((_opt_num + 1))
        printf "     %b[%2d]%b  %s\n" "$UMO_B_CYAN" "$_opt_num" "$UMO_NC" "$_opt"
    done
    printf "\n"

    while true; do
        printf "%b  => Enter choice [1-%d]: %b" "$UMO_B_GREEN" "$_opt_num" "$UMO_NC"
        read -r _choice

        if [ -z "$_choice" ] || [ "$_choice" -lt 1 ] || [ "$_choice" -gt "$_opt_num" ] 2>/dev/null; then
            umo_log_warn "Invalid choice. Please enter 1-$_opt_num"
            continue
        fi

        _idx=0
        for _opt in "$@"; do
            _idx=$((_idx + 1))
            if [ "$_idx" -eq "$_choice" ]; then
                UMO_MENU_RESULT="$_opt"
                UMO_MENU_IDX="$_choice"
                printf "\n%b  [OK] Selected:%b %s\n\n" "$UMO_B_GREEN" "$UMO_NC" "$_opt"
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
            *) umo_log_warn "Please answer yes or no." ;;
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
    printf "%b  %s%b: " "$UMO_B_WHITE" "$_prompt" "$UMO_NC"
    stty -echo 2>/dev/null
    read -r _ans
    stty echo 2>/dev/null
    printf "\n"
    UMO_INPUT_RESULT="$_ans"
}

umo_ui_checklist() {
    _title="$1"; shift

    umo_screen_clear
    umo_banner
    umo_rule
    printf "\n%b  => %s%b\n\n" "$UMO_COLOR_PRIMARY" "$_title" "$UMO_NC"
    printf "  %b[Space]=Toggle  [Enter]=Confirm%b\n\n" "$UMO_DIM" "$UMO_NC"

    _idx=0
    for _item in "$@"; do
        _idx=$((_idx + 1))
        eval "_chk_${_idx}=\"0\""
        eval "_lbl_${_idx}=\"$_item\""
    done
    _total="$_idx"

    _cursor=1
    while true; do
        _i=0
        while [ "$_i" -lt "$_total" ]; do
            _i=$((_i + 1))
            eval "_state=\"\$_chk_${_i}\""
            eval "_label=\"\$_lbl_${_i}\""

            if [ "$_i" -eq "$_cursor" ]; then
                _ptr=">"
                _pfix="$UMO_B_CYAN"
            else
                _ptr=" "
                _pfix=""
            fi

            if [ "$_state" = "1" ]; then
                _mark="X"
                _mfix="$UMO_B_GREEN"
            else
                _mark=" "
                _mfix=""
            fi

            printf "  %s%s [%s]%s %s\n" "$_pfix" "$_ptr" "$_mark" "$UMO_NC" "$_label"
        done

        printf "\n%b  ↑/↓ Navigate | Space Toggle | Enter Confirm %b" "$UMO_DIM" "$UMO_NC"
        _key=$(dd bs=1 count=1 2>/dev/null) || true

if [ -z "$_key" ]; then
            printf "\n  %bNumeric mode: enter item numbers (space-separated, empty=confirm): %b" "$UMO_B_YELLOW" "$UMO_NC"
            read -r _num_input
            if [ -z "$_num_input" ]; then
                break
            fi
            for _num in $_num_input; do
                if [ "$_num" -ge 1 ] && [ "$_num" -le "$_total" ] 2>/dev/null; then
                    eval "_chk_${_num}=\"1\""
                fi
            done
            continue
        fi

        case "$_key" in
            $(printf '\033'))
                _seq=$(dd bs=1 count=2 2>/dev/null)
                case "$_seq" in
                    A) [ "$_cursor" -gt 1 ] && _cursor=$((_cursor - 1)) ;;
                    B) [ "$_cursor" -lt "$_total" ] && _cursor=$((_cursor + 1)) ;;
                esac
                ;;
            ' ')
                eval "_old=\"\$_chk_${_cursor}\""
                if [ "$_old" = "1" ]; then _new="0"; else _new="1"; fi
                eval "_chk_${_cursor}=\"$_new\""
                ;;
            '') break ;;
        esac

        _i=0
        while [ "$_i" -lt "$_total" ]; do
            umo_line_up
            umo_line_clear
            _i=$((_i + 1))
        done
        umo_line_up
        umo_line_clear
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

umo_ui_panel() {
    _title="$1"; shift

    _cols=$(tput cols 2>/dev/null || echo 80)
    _cols="${_cols:-80}"

    _max_line=0
    for _line in "$@"; do
        _llen=$(printf '%s' "$_line" | wc -m)
        [ "$_llen" -gt "$_max_line" ] && _max_line=$_llen
    done

    _width=$(( _max_line + 8 ))
    [ "$_width" -gt "$((_cols - 4))" ] 2>/dev/null && _width=$((_cols - 4))
    [ "$_width" -lt 40 ] 2>/dev/null && _width=40

    _left=$(( (_cols - _width) / 2 )); [ "$_left" -lt 0 ] && _left=0

    printf "\n"
    umo_box "$_title" "$_width" "$_cols"

    for _line in "$@"; do
        _llen=$(printf '%s' "$_line" | wc -m)
        _pad=$(( _width - 4 - _llen ))
        [ "$_pad" -lt 0 ] && _pad=0
        printf "%*s%b|%b  %s%*s%b|\n" "$_left" '' "$UMO_COLOR_PRIMARY" "$UMO_NC" "$_line" "$_pad" '' "$UMO_COLOR_PRIMARY"
    done

    printf "%b" "$UMO_COLOR_PRIMARY"
    printf "%*s+%*s+\n" "$_left" '' "$((_width-2))" '' | tr ' ' '-'
    printf "%b" "$UMO_NC"
    printf "\n"
}

umo_ui_pause() {
    _msg="${1:-Press [Enter] to continue...}"
    printf "\n%b  %s%b" "$UMO_DIM" "$_msg" "$UMO_NC"
    read -r _dummy
}
