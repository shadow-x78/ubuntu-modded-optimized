# Changelog

All notable changes to this project will be documented in this file.

## [v3.0.0] - 2026-06-16

### Code Quality
- core-ansi.sh: removed complete duplicate block (-40%), fixed umo_box format bug (`$UMO_title` → `$_title`)
- umo-install: separated UMO_VERSION from UMO_UBUNTU_VERSION
- core-ui.sh: hardened umo_ui_checklist (fixed format injection + numeric fallback)
- xstartup: single source template, removed duplicate heredoc from umo-vnc.sh
- config/templates/: script templates replace inline heredocs across all modules
- bashrc.patch: updated MESA_GL_VERSION_OVERRIDE to 4.0

### Features
- New ASCII banner: refined Block + compact variant for narrow terminals
- Ubuntu 24.04 Noble Numbat support
- `--perf=balanced|aggressive|off`: APT speed + swap + debloat + DNS hardening
- `--theme=umo-dark|umo-light|minimal|none`: Orchis-Dark + Papirus icons + fonts
- `--lean`: strip docs/man/locales to save space
- `--ubuntu=22.04|24.04`: explicit Ubuntu version selection
- `VERSION` file: single source of truth for version string

### Performance
- APT: 99umo-speed.conf (no recommends/suggests, retries, timeout) + eatmydata ready
- Swap: automatic 512MB (balanced) / 1GB (aggressive) swapfile creation
- DNS: Cloudflare + Google + Quad9 with immutable resolv.conf
- Debloat: removes snapd, unattended-upgrades, apport, cups, avahi
- GPU: MESA 4.0 override + virpipe + virglrenderer
- VNC: deferUpdate + alwaysshared + error logging + dynamic geometry
- XFCE: compositor/screensaver/animations disabled by default

### Bug Fixes
- U1: RootFS integrity check after extraction (verifies /bin/bash)
- U2: Static resolv.conf + ca-certificates first + apt retry
- U3: SSH helper creates /run/sshd + generates host keys
- U5: dbus-launch --exit-with-session in xstartup (fixes black VNC)
- C7: Mirrors by ubuntu version + SHA256 verification activated

### New Files
- `VERSION`
- `modules/umo-perf.sh`
- `modules/umo-theme.sh`
- `config/templates/` (7 template files)
- `config/theme/` (9 theme config files)

---

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
