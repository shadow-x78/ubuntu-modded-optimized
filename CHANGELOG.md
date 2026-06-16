# Changelog

## [2.1.0] — 2024-06-16 — Open Source Release

### License & Governance
- Re-licensed under MIT License (fully open source)
- Removed all proprietary/commercial branding
- Open to contributions and community forks

### Maintenance
- No functional changes from v2.0.0
- All enterprise branding removed from headers, banners, and docs
- Clean open-source headers across all 13 source files

---

## [2.0.0] — 2024-06-16 — Codename: Obsidian

### Open Source Edition Release
- Complete architectural rewrite with modular library system
- POSIX sh compliance across all scripts
- Zero external UI dependencies (no dialog/whiptail)

### Core Engine
- `lib/core-ansi.sh` — ANSI color engine with 256-color support
- `lib/core-ui.sh` — Interactive TUI: menus, checklists, prompts
- `lib/core-system.sh` — Hardware detection, dependency management
- `lib/core-net.sh` — Multi-mirror download with resume
- `lib/core-fs.sh` — Safe file operations, atomic writes, backups

### Modules
- `modules/umo-proot.sh` — Container preparation, login wrappers
- `modules/umo-vnc.sh` — TigerVNC installation, session control
- `modules/umo-audio.sh` — PulseAudio bridge configuration
- `modules/umo-systemctl.sh` — systemd emulator
- `modules/umo-desktop.sh` — DE installer (LXDE/XFCE4/Openbox)
- `modules/umo-apps.sh` — Application suite installer

### New Features
- `--no-gui` non-interactive mode
- `--de=` / `--apps=` / `--dir=` CLI flags
- Progress bars with percentage
- Spinners for background tasks
- Configuration validation
- Health check system
- Logging to `~/.umo/logs/`

### Bug Fixes
- Screen lock kills VNC → `termux-wake-lock` integrated
- Audio not passing to proot → PulseAudio TCP bridge
- systemctl fails → Shell-compatible emulator
- dialog broken → Pure POSIX TUI replacement

---

## [1.0.0] — 2024-01-15

### Initial Release
- Basic Ubuntu installer for Termux
- VNC setup with TigerVNC
- Audio fix scripts
- Manual proot configuration
