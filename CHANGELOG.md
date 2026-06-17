# Changelog

All notable changes to this project will be documented in this file.

## [v3.1.6] - 2026-06-17

### 🚀 Added
- **Quiet Runner (`umo_run_quiet`):** `lib/core-ansi.sh` — wraps long-running commands with a Braille/ASCII spinner, captures output to a temp log, and on failure prints the last 30 lines. Replaces silent `2>/dev/null || true` swallowing across all modules.
- **Download Validation:** `lib/core-net.sh` — minimum file-size guard (`_UMO_NET_MIN_SIZE=1 MB`) and `umo_net__validate_file()` prevent corrupted or truncated rootfs archives from being accepted.
- **Timestamp Logging:** `lib/core-ansi.sh` — optional `UMO_LOG_TIME=1` prefix for every log line.
- **Warn Color:** `lib/core-ansi.sh` — dedicated `UMO_COLOR_WARN` (ANSI 220 / bold yellow) replaces the previous reuse of `UMO_B_YELLOW`.

### 🎨 Changed
- **Glyph Refresh:** `lib/core-ansi.sh` — step indicator changed to `▌`/`❯`, progress bar to `█/░`, spinner to Braille cycle `⠋⠙⠹...`, and added `UMO_G_RUN` glyph.
- **Menu Polish:** `lib/core-ui.sh` — `umo_ui_header` now draws an under-rule with `─`; menus show `[Space]=Toggle [Enter]=Confirm` hint.
- **Log Indentation:** All log helpers (`umo_log_ok`, `umo_log_err`, `umo_log_warn`, etc.) now use 2-space indentation for consistent hierarchy.
- **Extraction Hardening:** `lib/core-net.sh` — archive extraction no longer silently ignores `tar`/`unzip` errors; non-zero exit codes now `umo_die` with the actual status.
- **App/Desktop Installers:** `_run_installer` and `_run_de_installer` now pass human-readable labels into `umo_run_quiet` so every install phase is visible and traceable.

### 🐛 Fixed
- **Pkg Install Quiet:** `lib/core-system.sh` — `umo_sys_pkg_install` now wraps all package installs under a single `umo_run_quiet` spinner instead of printing raw `pkg`/`apt` stdout per package. Eliminates the #1 visual source of layout corruption.
- **Download Output Leak:** `lib/core-net.sh` — `umo_net_download` switched from `--show-progress` to `--quiet` (wget) and `-s` (curl). The old `--show-progress` + `--progress=bar:force:noscroll` printed raw terminal control sequences that destroyed the TUI layout. On failure, the last 30 lines are available via `umo_run_quiet`.
- **Archive Copy Robustness:** `lib/core-net.sh` — both cached-copy and post-download copy paths now guard `cp` failures with `{ ... } || { warn; rm; continue; }` instead of silently failing and leaving a missing file.
- **Box-Drawing Fallback:** `lib/core-ansi.sh` + `lib/core-ui.sh` — new `UMO_LINE_H` variable guarded by `UMO_GLYPH_SUPPORT`. Draws `─` in UTF-8 environments and `-` in ASCII/non-UTF-8 locales, replacing the hardcoded Unicode rule that rendered as ``.
- **Banner Line Bug:** `lib/core-ansi.sh` — corrected `_l7` line 7 of the UMO banner: format string `%b %*s %s %b` was consuming the color code as the width argument due to `%*s` eating two args. Now passes a valid color (`UMO_GRAD_1`) as the first `%b`.
- **System Check Spacing:** `bin/umo-install` + `lib/core-system.sh` — `umo_phase_check` now opens with `umo_ui_header "System Check"`, and `umo_sys_require_internet` uses `umo_log_info` instead of `umo_log_step`. Prevents the overlapping `▌ Checking... ✔` visual clash.
- **UTF-8 Detection:** `lib/core-ansi.sh` — glyph detection now falls back to `locale charmap` when `LANG`/`LC_ALL` variables do not contain "UTF-8". Respects `UMO_ASCII=1` for forced ASCII mode.
- **Readme Whitespace:** `README.md` & `README_AR.md` — fixed stray extra space in ASCII logo bottom line.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.6.

---

## [v3.1.5] - 2026-06-17

### 🚀 Added
- **Ubuntu Version Menu:** Interactive selection between Ubuntu 22.04 LTS (Jammy) and 24.04 LTS (Noble) in `umo_phase_config`.
- **UMO Glyph Log:** Professional Unicode glyph-based logging system with tree-style sub-steps.
  - Glyphs: `▶` (step), `✔` (ok), `✖` (err), `⚠` (warn), `ℹ` (info), `⋯` (debug), `├─/└─` (sub-steps).
  - Automatic ASCII fallback when Unicode is unavailable (`UMO_ASCII=1` or non-UTF-8 locale).
  - Progress bar now uses `▣/▱` blocks with glyph fallback to `#/-`.

### 🐛 Fixed
- **Same-File Copy Guard:** `lib/core-net.sh` — `cp` no longer fails with `are the same file` when cache path equals output path.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.5.

---

## [v3.1.4] - 2026-06-17

### 🗑️ Removed
- **Framed Panels:** `umo_ui_panel()` and `umo_box()` removed entirely.
- **Environment Validation Panel:** Deleted the duplicate static "Checking..." box in `umo_phase_check()`.

### 🎨 Changed
- **Line-Based Design:** All summary panels now use `umo_ui_header` + `umo_kv` for clean key:value output.
- **Configuration Summary:** Migrated to `umo_kv "Desktop"`, `Apps`, `Install`, `Version`.
- **System Summary:** Migrated to `umo_kv "Platform"`, `Arch`, `Storage`, `RAM`, `Path`.
- **Installation Complete:** Migrated to `umo_kv` lines for Version, Desktop, Path, VNC, Perf, User.
- **Banner Author:** Label changed from `Shadow-x78` to `By Shadow-x78`.
- **Separators:** Replaced dash rules (`umo_rule`) with blank lines in `umo_ui_init`, `umo_ui_menu`, and `umo_ui_checklist`.
- **Step Spacing:** `umo_log_step` now prepends a blank line before every `[==>]` message across all 41 call sites.

### 🐛 Fixed
- **Termux Info Display:** `umo_sys_summary()` now reads `TERMUX_APK_RELEASE` or `TERMUX_VERSION` from `termux-info` instead of capturing the header line `Termux Variables:`.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.4.

---

## [v3.1.3] - 2026-06-17

### 🎨 Changed
- **Banner:** ASCII `UMO` logo now shown on all screen sizes; removed the `[UMO]` compact line.
- **Tagline:** Reformatted to centered `Ubuntu Modded Optimized · v3.1.3` with `Shadow-x78` below.

### 🔄 Updated
- **Validation Panel:** `umo_ui_panel()` auto-fits any terminal width (minimum clamped to fit).
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.3.

---

## [v3.1.2] - 2026-06-17

### 🔄 Updated
- **systemctl Emulator:** `umo-systemctl.sh` — now presented and documented as a
  generic service manager (`start|stop|restart|status|enable|disable <service>`)
  instead of SSH-centric; clearer usage and status output.
- **Docs:** README, INSTALL, TROUBLESHOOTING (EN+AR) examples use a generic
  `<service>` token; SSH shown only as an example. SSH start helper retained.
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.2.

---

## [v3.1.1] - 2026-06-17

### 🚀 Added
- **ASCII Banner:** Restored large block-letter UMO logo (7-line) with orange gradient centering.
- **Panel Overflow Guard:** `umo_ui_panel()` now trims lines wider than the box and appends `…`.

### 🔄 Updated
- **Architecture Warning:** `core-system.sh` — clearer message for x86_64 users; indicates primary target is ARM64.
- **Summary Panel:** Compact key labels (`Platform`, `Arch`, `Path`) to prevent overflow.
- **Version Bump:** All badges, inline defaults, and `bin/umo-install` bumped to v3.1.1.

### 🐛 Fixed
- **Table Width:** `umo_ui_panel()` minimum raised to 52 and clamped to terminal width; eliminates off-screen boxes.

---

## [v3.1.0] - 2026-06-17

### 🚀 Added
- **256-Color Detection:** Auto-fallback between 256 / 16 / no-color modes via `tput colors`, `NO_COLOR`, `UMO_NO_256`.
- **Brand Palette:** Ubuntu orange identity — `UMO_COLOR_PRIMARY` = `38;5;208m`.

### 🔄 Updated
- **Logo Banner:** 6-line orange gradient (top light → bottom dark), centered via terminal width.
- **TUI Panel:** `umo_ui_panel()` now auto-fits width to content instead of hardcoded 60.
- **Session Box:** `bin/umo-start` — fixed misaligned VNC line, dynamic box width, inline color fallback.
- **Summary Colors:** `bin/umo-install` — Quick Commands and Inside Ubuntu now use brand palette.
- **Changelog:** Formatted with emoji categories matching reference standard.
- **Version Bump:** `bin/umo-install` and fallback defaults updated to v3.1.0.

### 🗑️ Removed
- **Comments:** All inline code comments removed across `lib/core-ansi.sh`, `lib/core-ui.sh`, `bin/umo-start`, `bin/umo-install`.

---

## [v3.0.0] - 2026-06-16

### 🚀 Added
- **ASCII Banner:** Refined Block banner + compact variant for narrow terminals.
- **Ubuntu 24.04:** Noble Numbat support.
- **Performance Flags:** `--perf=balanced|aggressive|off` — APT speed, swap, debloat, DNS hardening.
- **Desktop Themes:** `--theme=umo-dark|umo-light|minimal|none` — Orchis-Dark, Papirus icons, fonts.
- **Lean Mode:** `--lean` — strip docs/man/locales to save space.
- **Version Flag:** `--ubuntu=22.04|24.04` for explicit selection.
- **VERSION Source:** `UMO_VERSION` variable in `bin/umo-install` is the single source of truth.

### 🔄 Updated
- **Code Quality:** Removed duplicate block in `core-ansi.sh` (-40%), fixed `umo_box` format bug.
- **Version Separation:** Decoupled `UMO_VERSION` from `UMO_UBUNTU_VERSION`.
- **TUI Hardening:** Fixed format injection + numeric fallback in `umo_ui_checklist`.
- **Templates:** Heredocs replaced with script templates across all modules.
- **MESA Override:** Updated to `MESA_GL_VERSION_OVERRIDE=4.0` in bashrc.patch.

### 🐛 Fixed
- **U1:** RootFS integrity check after extraction (verifies `/bin/bash`).
- **U2:** Static `resolv.conf`, `ca-certificates` first, `apt` retry.
- **U3:** SSH helper creates `/run/sshd` + generates host keys.
- **U5:** `dbus-launch --exit-with-session` in xstartup (fixes black VNC).
- **C7:** Mirrors by Ubuntu version + SHA256 verification activated.

### 🗑️ Deprecated
- **Node.js 18:** EOL since April 2025.
- **Python 3.8:** EOL since October 2024.

---

## [v2.1.1] - 2026-06-16

### 📝 Documentation
- **README:** Complete redesign — badges, centered header, anchored sections, language switcher.
- **README_AR:** Added `README_AR.md` — full Arabic translation.
- **SECURITY:** Complete redesign with risk table and response timeline.
- **INSTALL:** Redesigned with language switcher, expanded install modes.
- **INSTALL_AR:** Added `docs/INSTALL_AR.md` — full Arabic translation.
- **TROUBLESHOOTING:** Redesigned with language switcher, expanded fix sections.
- **TROUBLESHOOTING_AR:** Added `docs/TROUBLESHOOTING_AR.md`.
- **LICENSE:** Updated formatting to match project style.

### 🔄 Updated
- **Version Bump:** `bin/umo-install` updated from v2.0.0 → v2.1.1.

---

## [v2.1.0] - 2024-06-16

### 🚀 Added
- **Open Source:** Re-licensed under MIT License — fully open source.
- **Community:** Open to contributions and community forks.

### 🔄 Updated
- **Branding:** Removed all proprietary/commercial branding.
- **Headers:** Clean open-source headers across all 13 source files.

---

## [v2.0.0] - 2024-06-16

### 🚀 Added
- **Core Engine:** `lib/core-ansi.sh` — ANSI color engine with 256-color support.
- **Core Engine:** `lib/core-ui.sh` — Interactive TUI: menus, checklists, prompts.
- **Core Engine:** `lib/core-system.sh` — Hardware detection, dependency management.
- **Core Engine:** `lib/core-net.sh` — Multi-mirror download with resume.
- **Core Engine:** `lib/core-fs.sh` — Safe file operations, atomic writes, backups.
- **Modules:** `umo-proot.sh` — Container preparation, login wrappers.
- **Modules:** `umo-vnc.sh` — TigerVNC installation, session control.
- **Modules:** `umo-audio.sh` — PulseAudio bridge configuration.
- **Modules:** `umo-systemctl.sh` — systemd emulator.
- **Modules:** `umo-desktop.sh` — DE installer (LXDE / XFCE4 / Openbox).
- **Modules:** `umo-apps.sh` — Application suite installer.
- **CLI:** `--no-gui` non-interactive mode.
- **CLI:** `--de=` / `--apps=` / `--dir=` flags.
- **UX:** Progress bars with percentage and spinners for background tasks.
- **Validation:** Configuration validation and health check system.
- **Logging:** Structured logging to `~/.umo/logs/`.

### 🔄 Updated
- **Architecture:** Complete rewrite with modular library system.
- **Compatibility:** Full POSIX sh compliance across all scripts.
- **Dependencies:** Zero external UI dependencies — no `dialog` / `whiptail`.

### 🐛 Fixed
- **VNC:** Screen lock kills VNC → `termux-wake-lock` integrated.
- **Audio:** No audio in proot → PulseAudio TCP bridge.
- **systemctl:** `systemctl` fails → Shell-compatible emulator.
- **TUI:** `dialog` broken → Pure POSIX TUI replacement.

---

## [v1.0.0] - 2024-01-15

### 🎉 Initial Release
- **Launch:** Initial release of UMO — Ubuntu Modded Optimized for Termux.
- **Support:**
  - Ubuntu 22.04 via proot-distro
  - VNC setup with TigerVNC
  - PulseAudio audio fix scripts
  - Manual proot configuration