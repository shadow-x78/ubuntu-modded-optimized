# Installation Guide

## Prerequisites

- Android 8.0+ with ARM64 (aarch64)
- Termux from **F-Droid** or GitHub (not Play Store)
- 2GB+ free storage
- Internet connection

## Install

```bash
cd ~
git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git UMO
cd UMO
bash install.sh
```

## Silent Install

```bash
bash install.sh --no-gui --de=xfce4 --apps=full
```

## Start Ubuntu

```bash
~/umo-start.sh       # Start Ubuntu + VNC + Audio
~/umo-stop.sh        # Stop everything
~/umo-login.sh       # Login as root
~/umo-user.sh        # Login as ubuntu
```

## Inside Ubuntu

| Command | Description |
|---------|-------------|
| `umo-startvnc` | Start VNC server |
| `umo-stopvnc` | Stop VNC server |
| `systemctl start ssh` | Start SSH (emulated) |

## Uninstall

```bash
rm -rf ~/umo-ubuntu ~/.umo ~/umo-*.sh
```
