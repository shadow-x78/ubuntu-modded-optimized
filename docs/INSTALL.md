<div align="center">

# Installation Guide — UMO

[![Version](https://img.shields.io/badge/version-2.1.0-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-dc2626?style=flat-square)](../LICENSE)
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
| Termux | F-Droid or GitHub — **not** Play Store |
| Storage | 2 GB+ free |
| Network | Internet connection required |

---

<a id="install"></a>
## 🚀 Install

```bash
# Clone the repository
git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git ~/UMO
cd ~/UMO

# Run the interactive installer
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
| `--de=xfce4` | XFCE4 | Daily use — balanced performance |
| `--de=lxde` | LXDE | Low-end and older devices |
| `--de=openbox` | Openbox | Advanced users, minimal footprint |
| `--de=minimal` | None (CLI only) | Servers and headless usage |

---

<a id="application-groups"></a>
## 📦 Application Groups

| Flag | Group | Includes |
|------|-------|----------|
| `--apps=basic` | Basic | Core utilities only |
| `--apps=dev` | Developer | git, vim, python3, nodejs, build-essential |
| `--apps=media` | Media | ffmpeg, vlc, gimp |
| `--apps=full` | Full | All of the above |

---

<a id="first-boot"></a>
## 🔐 First Boot

```bash
# Start Ubuntu (VNC + Audio)
~/umo-start.sh

# Connect via VNC viewer
# Address : localhost:5901
# Password: ubuntu  ← change this immediately!
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
| `~/umo-start.sh` | Start Ubuntu + VNC + Audio |
| `~/umo-stop.sh` | Stop all services |
| `~/umo-login.sh` | Login as root |
| `~/umo-user.sh` | Login as ubuntu user |
| `~/umo-vnc-start.sh` | Start VNC only |
| `~/umo-fix-audio.sh` | Fix audio routing |

### Inside Ubuntu

| Command | Description |
|---------|-------------|
| `umo-startvnc` | Start VNC server |
| `umo-stopvnc` | Stop VNC server |
| `umo-fix-audio` | Repair PulseAudio |
| `systemctl start ssh` | Start SSH (emulated) |
| `systemctl stop ssh` | Stop SSH (emulated) |
| `systemctl status ssh` | Check service status |

---

<a id="uninstall"></a>
## 🗑️ Uninstall

```bash
# Remove Ubuntu rootfs and all UMO files
rm -rf ~/umo-ubuntu ~/.umo ~/umo-*.sh
```

---

<div align="center">

Built by <a href="https://github.com/Shadow-x78">SHADOW_x78</a> ·
<a href="https://github.com/Shadow-x78/termux-ubuntu-umo">termux-ubuntu-umo</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Shadow-x78</sub>

</div>
