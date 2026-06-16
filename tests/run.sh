#!/bin/sh
# UMO — Test Suite (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SCRIPT_DIR/lib/core-ansi.sh"

_tests_run=0
_tests_passed=0
_tests_failed=0

assert_true() {
    _tests_run=$((_tests_run + 1))
    if "$@" >/dev/null 2>&1; then
        _tests_passed=$((_tests_passed + 1))
        printf "  %bPASS%b  %s\n" "$UMO_B_GREEN" "$UMO_NC" "$*"
    else
        _tests_failed=$((_tests_failed + 1))
        printf "  %bFAIL%b  %s\n" "$UMO_B_RED" "$UMO_NC" "$*"
    fi
}

assert_eq() {
    _tests_run=$((_tests_run + 1))
    if [ "$1" = "$2" ]; then
        _tests_passed=$((_tests_passed + 1))
        printf "  %bPASS%b  %s == %s\n" "$UMO_B_GREEN" "$UMO_NC" "$1" "$2"
    else
        _tests_failed=$((_tests_failed + 1))
        printf "  %bFAIL%b  %s != %s\n" "$UMO_B_RED" "$UMO_NC" "$1" "$2"
    fi
}

test_core() {
    printf "\n%b[Core Library]%b\n" "$UMO_B_YELLOW" "$UMO_NC"

    assert_true [ -n "$UMO_B_GREEN" ]
    assert_true [ -n "$UMO_B_RED" ]
    assert_true [ -n "$UMO_B_BLUE" ]

    assert_true command -v umo_log_ok >/dev/null
    assert_true command -v umo_log_err >/dev/null
    assert_true command -v umo_progress >/dev/null
    assert_true command -v umo_banner >/dev/null
}

test_files() {
    printf "\n%b[File Structure]%b\n" "$UMO_B_YELLOW" "$UMO_NC"

    assert_true [ -f "$SCRIPT_DIR/bin/umo-install" ]
    assert_true [ -f "$SCRIPT_DIR/bin/umo-start" ]
    assert_true [ -f "$SCRIPT_DIR/bin/umo-stop" ]
    assert_true [ -f "$SCRIPT_DIR/lib/core-ansi.sh" ]
    assert_true [ -f "$SCRIPT_DIR/lib/core-ui.sh" ]
    assert_true [ -f "$SCRIPT_DIR/lib/core-system.sh" ]
    assert_true [ -f "$SCRIPT_DIR/lib/core-net.sh" ]
    assert_true [ -f "$SCRIPT_DIR/lib/core-fs.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-proot.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-vnc.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-audio.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-systemctl.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-desktop.sh" ]
    assert_true [ -f "$SCRIPT_DIR/modules/umo-apps.sh" ]
    assert_true [ -f "$SCRIPT_DIR/config/xstartup" ]
    assert_true [ -f "$SCRIPT_DIR/config/sources.list" ]
    assert_true [ -f "$SCRIPT_DIR/install.sh" ]
    assert_true [ -f "$SCRIPT_DIR/README.md" ]
    assert_true [ -f "$SCRIPT_DIR/LICENSE" ]
}

test_perms() {
    printf "\n%b[Permissions]%b\n" "$UMO_B_YELLOW" "$UMO_NC"

    assert_true [ -x "$SCRIPT_DIR/bin/umo-install" ]
    assert_true [ -x "$SCRIPT_DIR/bin/umo-start" ]
    assert_true [ -x "$SCRIPT_DIR/bin/umo-stop" ]
    assert_true [ -x "$SCRIPT_DIR/install.sh" ]
}

test_summary() {
    printf "\n"
    umo_rule "=" 60
    printf "  Tests Run:    %d\n" "$_tests_run"
    printf "  %bPassed:%b     %d\n" "$UMO_B_GREEN" "$UMO_NC" "$_tests_passed"
    printf "  %bFailed:%b     %d\n" "$UMO_B_RED" "$UMO_NC" "$_tests_failed"
    umo_rule "=" 60
    printf "\n"

    [ "$_tests_failed" -eq 0 ] && exit 0 || exit 1
}

umo_banner
printf "\n%bRunning UMO Test Suite...%b\n\n" "$UMO_B_CYAN" "$UMO_NC"

test_core
test_files
test_perms
test_summary
