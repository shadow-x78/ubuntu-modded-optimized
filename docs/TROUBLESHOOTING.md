<div align="center">

# Troubleshooting - UMO

[![Version](https://img.shields.io/badge/version-4.16.2-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-GPL--3.0-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/platform-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 🌐 Language

<a href="TROUBLESHOOTING.md">🇬🇧 English</a> · <a href="TROUBLESHOOTING_AR.md">🇸🇦 العربية</a>

---

## 📋 Table of Contents

- [VNC Disconnects on Screen Lock](#vnc-lock)
- [VNC Stops By Itself (Android 12+)](#phantom-process)
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

<a id="phantom-process"></a>
## 🛑 VNC Stops By Itself (Android 12+)

**Cause:** Android's **phantom process killer** terminates deep background process chains (proot → bash → Xtigervnc) a few seconds/minutes after launch, even with a wake lock. Direct daemons (PulseAudio) survive, which is why `umo status` shows Audio running but VNC stopped.

**Fix (one-time, from a PC with USB debugging):**

```bash
adb shell device_config put activity_manager max_phantom_processes 2147483647
adb shell settings put global settings_enable_monitor_phantom_procs false
```

> The `settings` command is rejected on some Android 14+ builds - the `device_config` line alone is usually enough. UMO also auto-restarts the VNC server up to 3 times if it dies.

**Check:** `umo start`, wait a minute, then run `umo status`. If VNC still stops, inspect `~/.umo/logs/vnc-start.log`.

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

> Make sure you are using Termux from **F-Droid or GitHub** - the Play Store version is outdated and unsupported.

---

<a id="still-stuck"></a>
## 🆘 Still Stuck?

Check the UMO logs for detailed error output:

```bash
cat ~/.umo/logs/install.log
```

If the problem persists, open an issue with the log attached:

[Open an Issue](https://github.com/shadow-x78/ubuntu-modded-optimized/issues)

---

<div align="center">

Built by <a href="https://github.com/shadow-x78">shadow-x78</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Ubuntu Modded Optimized (UMO)</sub>

</div>
