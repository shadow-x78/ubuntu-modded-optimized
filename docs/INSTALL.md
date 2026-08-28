<div align="center">

# Installation Guide - UMO

[![Version](https://img.shields.io/badge/version-4.16.13-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-GPL--3.0-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/platform-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 Language

<a href="INSTALL.md">🇬🇧 English</a> · <a href="INSTALL_AR.md">🇸🇦 العربية</a>

---

## 📋 Table of Contents

- [Requirements](#requirements)
- [Install](#install)
- [Silent Install](#silent-install)
- [Desktop Environments](#desktop-environments)
- [Application Groups](#application-groups)
- [Other Options](#other-options)
- [First Boot](#first-boot)
- [Commands Reference](#commands)
- [Uninstall](#uninstall)

---

<a id="requirements"></a>
## 📋 Requirements

| Requirement | Details |
|-------------|---------|
| Android | 8.0+ |
| Architecture | ARM64 (aarch64) |
| Termux | F-Droid or GitHub - **not** Play Store |
| Storage | 2 GB+ free |
| Network | Internet connection required |

---

<a id="install"></a>
## 🚀 Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shadow-x78/ubuntu-modded-optimized/main/umo.sh)
```

Downloads the latest GitHub release (SHA-256 verified) and launches the installer. For contributors, install from source instead:

```bash
git clone https://github.com/shadow-x78/ubuntu-modded-optimized.git ~/UMO
cd ~/UMO
bash install.sh
```

The installer will guide you through:
1. Environment validation
2. Dependency installation
3. Desktop environment selection
4. Application group selection
5. Ubuntu rootfs download and setup

---

<a id="silent-install"></a>
## ⚙️ Silent Install

Skip all menus and run with predefined options:

```bash
bash install.sh --no-gui --de=xfce4 --apps=full
```

You can also use environment variables:

```bash
UMO_DE=lxde UMO_APP_SET=dev UMO_NON_INTERACTIVE=1 bash install.sh
```

---

<a id="desktop-environments"></a>
## 🖥️ Desktop Environments

| Flag | Environment | Best For |
|------|-------------|----------|
| `--de=xfce4` | XFCE4 | Daily use - balanced performance |
| `--de=lxde` | LXDE | Low-end and older devices |
| `--de=openbox` | Openbox | Advanced users, minimal footprint |
| `--de=minimal` | None (CLI only) | Servers and headless usage |

---

<a id="application-groups"></a>
## 📦 Application Groups

| Flag | Group | Includes |
|------|-------|----------|
| `--apps=basic` | Basic | Core utilities + Falkon web browser (lightweight, proot-friendly) |
| `--apps=dev` | Developer | git, vim, python3, nodejs, build-essential, VS Code, Geany |
| `--apps=media` | Media | ffmpeg, vlc, gimp |
| `--apps=full` | Full | All of the above |

---

<a id="other-options"></a>
## ⚙️ Other Options

| Flag | Description |
|------|-------------|
| `--perf=<mode>` | Set performance level (`balanced`: depth 24, 30 fps, fast hextile - `aggressive`: depth 16, 20 fps, fast hextile for slower devices - `off`). The tuning lives in `/etc/umo/vnc.conf` inside the container, the xfwm4 compositor is always disabled for VNC, and `umo update` applies both to existing containers |
| `--theme=<theme>` | Set desktop theme (`umo-dark`, `umo-light`, `none`) - default is `umo-dark` (Orchis-Dark-Compact GTK + Tela-black-dark icons + DMZ cursor, falling back to Materia-dark + gnome icons when the designer extras are missing) |
| `--lean` | Remove docs/man/locales to save space |

---

<a id="first-boot"></a>
## 🔐 First Boot

```bash
# Start Ubuntu session (VNC + Audio)
umo start

# Or login directly in your terminal
umo login

# Connect via VNC viewer
# Address: 127.0.0.1:5901
# Password: shown at the end of install (stored in ~/.umo/vnc-pass)
```

> **Change the VNC password right after first login:**
> ```bash
> vncpasswd
> ```

---

<a id="commands"></a>
## ⌨️ Commands Reference

### In Termux

| Command | Description |
|---------|-------------|
| `umo start` | Start session with VNC & Audio |
| `umo stop` | Stop all services |
| `umo status` | Show running status of services |
| `umo login` | Login as root |
| `umo user` | Login as default user |
| `umo update` | Full update: pull latest UMO, re-apply saved settings (theme, apps, desktop), upgrade Ubuntu packages. `--scripts-only` for a fast refresh, `--no-upgrade` to skip the Ubuntu system upgrade |
| `umo refresh` | Re-render the `umo` CLI, host and container scripts from the local tool copy (no git pull) |
| `umo version` | Display current UMO version |

### Inside Ubuntu

| Command | Description |
|---------|-------------|
| `umo-startvnc` | Start VNC server |
| `umo-stopvnc` | Stop VNC server |
| `systemctl start <service>` | Start a service (emulated) |
| `systemctl status <service>` | Check service status |
| `systemctl restart <service>` | Restart a service |
| `systemctl stop <service>` | Stop a service (emulated) |
| `systemctl enable <service>` | Enable a service |
| `systemctl disable <service>` | Disable a service |
| _(example: `systemctl start ssh`)_ | _Start SSH server_ |

---

<a id="uninstall"></a>
## 🗑️ Uninstall

```bash
# Remove Ubuntu rootfs and all UMO files
rm -rf ~/umo-ubuntu ~/.umo ~/umo-*.sh
```

---

<div align="center">

Built by <a href="https://github.com/shadow-x78">shadow-x78</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Ubuntu Modded Optimized (UMO)</sub>

</div>
