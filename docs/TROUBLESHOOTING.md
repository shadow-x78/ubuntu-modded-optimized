<div align="center">

# Troubleshooting — UMO

[![Version](https://img.shields.io/badge/version-4.0.7-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/platform-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 Language

<a href="TROUBLESHOOTING.md">🇬🇧 English</a> · <a href="TROUBLESHOOTING_AR.md">🇸🇦 العربية</a>

---

## 📋 Table of Contents

- [VNC Disconnects on Screen Lock](#vnc-lock)
- [No Audio in Proot](#no-audio)
- [systemctl Fails](#systemctl)
- [Black Screen / VNC Not Connecting](#black-screen)
- [Low Storage During Install](#low-storage)
- [Install Fails on Dependency Step](#dep-fail)
- [Still Stuck?](#still-stuck)

---

<a id="vnc-lock"></a>
## 📱 VNC Disconnects on Screen Lock

**Cause:** Android kills background processes when the screen locks.

**Fix:** UMO runs `termux-wake-lock` automatically. If the issue persists:

```bash
termux-wake-lock
umo login
```

> Keep Termux open in the foreground or use a persistent notification to prevent Android from killing it.

---

<a id="no-audio"></a>
## 🔇 No Audio in Proot

**Cause:** PulseAudio is not running or the TCP bridge is not active.

**Fix:**

```bash
# Restart everything (recommended)
umo stop
umo login

# Or start PulseAudio manually inside Ubuntu
pulseaudio --start
```

---

<a id="systemctl"></a>
## ⚙️ systemctl Fails

**Cause:** Standard `systemd` does not run inside proot containers.

**Fix:** UMO installs a **generic** shell-compatible `systemctl` emulator usable with **any service**. Use it normally:

```bash
systemctl start <service>
systemctl stop <service>
systemctl restart <service>
systemctl status <service>
systemctl enable <service>
systemctl disable <service>
# example: systemctl start ssh
```

> If the emulator is missing, re-run the installer or copy `modules/umo-systemctl.sh` manually.

---

<a id="black-screen"></a>
## 🖥️ Black Screen / VNC Not Connecting

**Cause:** A stale VNC session or the desktop environment failed to start.

**Fix:**

```bash
# Stop all services and restart
umo stop
umo login
```

If the issue persists, kill any lingering VNC processes:

```bash
# Inside Ubuntu
vncserver -kill :1
vncserver :1
```

---

<a id="low-storage"></a>
## 💾 Low Storage During Install

**Cause:** Package cache or incomplete previous download consuming space.

**Fix:**

```bash
# Clear Termux package cache
pkg clean

# Clear UMO download cache
rm -rf ~/.umo/cache
```

Then re-run the installer.

---

<a id="dep-fail"></a>
## 📦 Install Fails on Dependency Step

**Cause:** Outdated Termux packages or broken repository mirrors.

**Fix:**

```bash
# Update Termux packages first
pkg update && pkg upgrade

# Then retry
bash install.sh
```

> Make sure you are using Termux from **F-Droid or GitHub** — the Play Store version is outdated and unsupported.

---

<a id="still-stuck"></a>
## 🆘 Still Stuck?

Check the UMO logs for detailed error output:

```bash
cat ~/.umo/logs/install.log
```

If the problem persists, open an issue with the log attached:

[→ Open an Issue](https://github.com/Shadow-x78/termux-ubuntu-umo/issues)

---

<div align="center">

Built by <a href="https://github.com/Shadow-x78">Shadow-x78</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Ubuntu Modded Optimized (UMO)</sub>

</div>
