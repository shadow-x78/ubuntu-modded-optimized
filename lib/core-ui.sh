#!/bin/sh
# UMO — TUI Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_UI_LOADED:-}" ] || return 0
_UMO_UI_LOADED=1

. "${UMO_LIB_DIR:-.}/core-ansi.sh"

umo_ui_init() {
    umo_screen_clear
    umo_banner
    printf "\n"
}

umo_ui_header() {
    _text="$1"
    _cols="${2:-$(tput cols 2>/dev/null || echo 80)}"
    _cols="${_cols:-80}"
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

    # Print title inline without clearing screen again
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

        # Strip any trailing CR from input (safety for CRLF terminals)
        _choice=$(printf '%s' "$_choice" | tr -d '\r')

        if [ -z "$_choice" ] || ! printf '%s' "$_choice" | grep -qE '^[0-9]+$'; then
            umo_log_warn "Invalid choice. Please enter a number 1-$_opt_num"
            continue
        fi
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
    printf "\n"
    umo_ui_header "$UMO_COLOR_PRIMARY$_title$UMO_NC"
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

            if [ "${UMO_GLYPH_SUPPORT:-0}" -eq 1 ]; then
                _ptr_glyph="❯"
                _mark_glyph="◉"
                _unmark_glyph="○"
            else
                _ptr_glyph=">"
                _mark_glyph="X"
                _unmark_glyph=" "
            fi

            if [ "$_i" -eq "$_cursor" ]; then
                _ptr="$_ptr_glyph"
                _pfix="$UMO_B_CYAN"
                _lfix="$UMO_BOLD"
            else
                _ptr=" "
                _pfix=""
                _lfix=""
            fi

            if [ "$_state" = "1" ]; then
                _mark="$_mark_glyph"
                _mfix="$UMO_B_GREEN"
            else
                _mark="$_unmark_glyph"
                _mfix="$UMO_DIM"
            fi

            printf "  %b%s%b %b[%s]%b %b%s%b\n" "$_pfix" "$_ptr" "$UMO_NC" "$_mfix" "$_mark" "$UMO_NC" "$_lfix" "$_label" "$UMO_NC"
        done

        printf "\n  %b↑/↓ Navigate | Space Toggle | Enter Confirm%b " "$UMO_DIM" "$UMO_NC"
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

umo_ui_pause() {
    _msg="${1:-Press [Enter] to continue...}"
    printf "\n%b  %s%b" "$UMO_DIM" "$_msg" "$UMO_NC"
    read -r _dummy
}
