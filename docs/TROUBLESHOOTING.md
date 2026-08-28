<div align="center">

# Troubleshooting - UMO

[![Version](https://img.shields.io/badge/version-4.16.13-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
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
- [VNC Feels Slow or Freezes](#vnc-slow)
- [Default Web Browser Fails With "Input/Output Error"](#default-browser)
- [htop Opens and Closes Instantly](#htop-instant-close)
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

<a id="vnc-slow"></a>
## 🐢 VNC Feels Slow or Freezes

**Cause:** TigerVNC's stock settings spend phone CPU on encoding work that is pointless for a viewer connected over loopback (60 updates per second, ImprovedHextile compression), and the xfwm4 compositor re-renders every frame before VNC encodes it - the heaviest per-frame cost on a phone CPU. When two apps open at once, that CPU tax is what makes the desktop freeze until it responds.

**Fix:** since v4.16.13, `umo update` writes the tuning into the container (`/etc/umo/vnc.conf` - balanced: depth 24, 30 fps, fast hextile; aggressive mode: depth 16, 20 fps), disables the compositor in every existing XFCE session, and the VNC start script passes the tuned parameters to `Xtigervnc`. One update on the device is enough:

```bash
umo update
umo stop
umo start
```

**Check:** the start banner prints a `Tuning:` line (e.g. `depth 24 - 30 fps - hextile fast`). If the desktop still feels heavy, lower the resolution before connecting:

```bash
# inside the container (umo login)
echo 'VNC_GEOMETRY="1024x576"' >> /etc/umo/vnc.conf
```

---

<a id="default-browser"></a>
## 🌐 Default Web Browser Fails With "Input/Output Error"

**Cause:** the "Failed to execute default Web Browser. Input/output error." dialog is not a kernel fault. XFCE hands every browser launch to `xfce4-mime-helper`, which read the system default (`sensible-browser` → bare `/usr/bin/falkon` with no sandbox switches). QtWebEngine refuses to run without its proot-safe switches and dies within a second, and `xfce4-mime-helper` reports that failed spawn as a synthesized I/O error.

**Fix:** since v4.16.13, `umo update` wires Falkon as the real default browser (XFCE helper definition, `helpers.rc`, `mimeapps.list` defaults and the `x-www-browser` alternative, all pointing at the hardened `/usr/local/bin/umo-browser` wrapper):

```bash
umo update
```

**Check:** inside the container (`umo login`), this must open Falkon with no dialog:

```bash
xfce4-mime-helper --launch WebBrowser https://example.com
cat /tmp/umo-browser.log   # should end with "Sandboxing disabled by user"
```

If it still fails, re-run the installer with the browser set so the wiring runs inside the app installer: `bash umo.sh --no-gui --apps=browser`.

---

<a id="htop-instant-close"></a>
## 📊 htop Opens and Closes Instantly

**Cause:** htop is an ncurses app - when `TERM` reaches the container blank or unresolvable, ncurses cannot initialize the screen and htop exits before the first frame. The root cause was fixed in v4.16.8, and since v4.16.13 `umo update` repairs every existing container (re-rendered login wrappers with a `TERM` default plus a guard block in both users' `~/.bashrc`).

**Fix:**

```bash
umo update
umo login
htop
```

**Check:** inside the container, `echo $TERM` must print `xterm-256color`. If it prints anything else, `infocmp $TERM` must succeed - otherwise the guard falls back automatically. Inside the desktop, launch htop from `xfce4-terminal` (the menu entry does this for you), never from a terminal emulator that exports no `TERM`.

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
