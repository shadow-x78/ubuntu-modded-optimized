# UMO — Ubuntu Modded Optimized for Termux

<p align="center">
  <b>Production-ready Ubuntu environment for Android via Termux</b><br>
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#docs">Docs</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**UMO (Ubuntu Modded Optimized)** is a free, open-source Ubuntu installer for Termux that solves every known issue in similar projects. Designed for developers, power users, and anyone who wants a stable Ubuntu environment on Android without manual configuration headaches.

### Why UMO?

| Problem | Other Projects | UMO Solution |
|---------|---------------|--------------|
| `dialog` breaks UI | ❌ Still uses it | ✅ Pure POSIX TUI |
| VNC dies on lock | ❌ No fix | ✅ `termux-wake-lock` integrated |
| No audio in proot | ❌ Manual fix | ✅ PulseAudio TCP bridge |
| `systemctl` fails | ❌ Confusing errors | ✅ Shell emulator included |
| Complex setup | ❌ 20+ manual steps | ✅ One-command install |

---

## Features

### Core
- **POSIX sh compatible** — Works with `bash`, `dash`, `ash`
- **Zero UI dependencies** — No `dialog`, `whiptail`, or `ncurses` required
- **Modular architecture** — 5 core libraries + 6 functional modules
- **Structured logging** — Organized logs to `~/.umo/logs/`
- **Health checks** — Pre-flight validation of all requirements

### Desktop
- **XFCE4** — Recommended (balanced)
- **LXDE** — Ultra-lightweight for low-end devices
- **Openbox** — Minimal for advanced users
- **Minimal** — CLI-only mode

### Connectivity
- **VNC Server** — TigerVNC with session persistence
- **Audio Bridge** — PulseAudio passthrough to Android
- **Termux:X11** — Native display support (optional)

### Management
- **Fake systemctl** — Start/stop/restart/status/enable/disable
- **Session control** — `umo-start` / `umo-stop` unified commands
- **User isolation** — `ubuntu` user with sudo access

---

## Quick Start

```bash
# Download & extract
cd ~
git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git UMO
cd UMO

# Interactive install (recommended)
bash install.sh

# Or non-interactive with flags
bash install.sh --no-gui --de=xfce4 --apps=full

# Start Ubuntu
~/umo-start.sh
```

---

## Commands

### In Termux

| Command | Description |
|---------|-------------|
| `~/umo-start.sh` | Start Ubuntu + VNC + Audio |
| `~/umo-stop.sh` | Stop all services |
| `~/umo-login.sh` | Login as root |
| `~/umo-user.sh` | Login as ubuntu |
| `~/umo-vnc-start.sh` | Start VNC only |
| `~/umo-fix-audio.sh` | Fix audio routing |

### Inside Ubuntu

| Command | Description |
|---------|-------------|
| `umo-startvnc` | Start VNC server |
| `umo-stopvnc` | Stop VNC server |
| `umo-fix-audio` | Repair PulseAudio |
| `systemctl start ssh` | Start SSH (emulated) |

---

## CLI Options

```bash
bash install.sh [OPTIONS]

  --no-gui, --non-interactive   Skip menus (use defaults/env)
  --de=xfce4|lxde|openbox      Desktop environment
  --apps=basic|dev|media|full   Application group
  --dir=PATH                   Custom install directory
  --version=22.04|24.04        Ubuntu version
```

---

## Requirements

- Android 8.0+ with ARM64 (aarch64)
- Termux from F-Droid or GitHub (not Play Store)
- 2GB+ free storage
- Internet connection

---

## Architecture

```
UMO/
├── bin/
│   ├── umo-install          # Main installer
│   ├── umo-start            # Session starter
│   └── umo-stop             # Session stopper
├── lib/
│   ├── core-ansi.sh         # ANSI engine
│   ├── core-ui.sh           # TUI engine
│   ├── core-system.sh       # Platform utils
│   ├── core-net.sh          # Download engine
│   └── core-fs.sh           # File operations
├── modules/
│   ├── umo-proot.sh         # Container manager
│   ├── umo-vnc.sh           # VNC server
│   ├── umo-audio.sh         # Audio bridge
│   ├── umo-systemctl.sh     # Systemctl emulator
│   ├── umo-desktop.sh       # DE installer
│   └── umo-apps.sh          # App installer
├── config/
│   ├── xstartup             # VNC session template
│   ├── bashrc.patch         # Shell enhancements
│   └── sources.list         # Ubuntu mirrors
├── docs/
│   ├── INSTALL.md           # Installation guide
│   └── TROUBLESHOOTING.md   # Common issues
├── tests/
│   └── run.sh               # Validation suite
├── install.sh               # Quick-start wrapper
├── CHANGELOG.md             # Release history
├── LICENSE                  # MIT License
└── README.md                # This file
```

---

## Docs

- [Installation Guide](docs/INSTALL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## License

Distributed under the [MIT License](LICENSE).

---

Built by [SHADOW_x78](https://github.com/Shadow-x78) · [Changelog](CHANGELOG.md)

© 2026 Shadow-x78
