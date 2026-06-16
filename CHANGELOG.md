# Changelog

All notable changes to this project will be documented in this file.

## [v2.1.1] - 2026-06-16

### 📝 Documentation
- **README:** Complete redesign — badges, centered header, anchored sections, language switcher.
- **README_AR:** Added `README_AR.md` — full Arabic translation of the main readme.
- **SECURITY:** Complete redesign with structured format, risk table, and response timeline.
- **INSTALL:** Complete redesign — badges, language switcher, expanded sections for all install modes.
- **INSTALL_AR:** Added `docs/INSTALL_AR.md` — full Arabic translation of the installation guide.
- **TROUBLESHOOTING:** Complete redesign — badges, language switcher, expanded fix sections.
- **TROUBLESHOOTING_AR:** Added `docs/TROUBLESHOOTING_AR.md` — full Arabic translation of the troubleshooting guide.
- **LICENSE:** Updated formatting to match project style.

### 🔄 Updated
- **Version Bump:** `bin/umo-install` version updated from `2.0.0` → `2.1.1`.

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
- **Modules:** `modules/umo-proot.sh` — Container preparation, login wrappers.
- **Modules:** `modules/umo-vnc.sh` — TigerVNC installation, session control.
- **Modules:** `modules/umo-audio.sh` — PulseAudio bridge configuration.
- **Modules:** `modules/umo-systemctl.sh` — systemd emulator.
- **Modules:** `modules/umo-desktop.sh` — DE installer (LXDE / XFCE4 / Openbox).
- **Modules:** `modules/umo-apps.sh` — Application suite installer.
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
