<div align="center">

# Security Policy — UMO

[![Version](https://img.shields.io/badge/version-3.0.0-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/platform-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 📋 Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting)
- [Disclosure Policy](#disclosure)
- [Security Considerations](#considerations)
- [Security Audit](#audit)
- [Hall of Fame](#hall-of-fame)

---

<a id="supported-versions"></a>
## 🛡️ Supported Versions

| Version | Supported |
|---------|-----------|
| 2.1.x | ✅ Active |
| < 2.1 | ❌ End of Life |

Only the latest minor release receives security updates. Ensure you are on the most recent version before reporting.

---

<a id="reporting"></a>
## 🚨 Reporting a Vulnerability

If you discover a security vulnerability in UMO, please report it **responsibly** and **privately**.

**Preferred method:**
- Open a private security advisory on GitHub:
  [Security Advisories →](https://github.com/Shadow-x78/termux-ubuntu-umo/security/advisories/new)

**Alternative method:**
- GitHub direct message to [@Shadow-x78](https://github.com/Shadow-x78)

**What to include:**

| Field | Details |
|-------|---------|
| Description | Clear explanation of the vulnerability |
| Reproduction | Steps to reproduce — minimal PoC if possible |
| Component | Affected file / module and version |
| Impact | Privilege escalation, data exposure, etc. |
| Fix | Suggested mitigation (optional) |

**Response timeline:**

| Phase | Timeframe |
|-------|-----------|
| Initial acknowledgment | Within 72 hours |
| Impact assessment | Within 7 days |
| Patch development | Within 30 days (critical) |
| Public disclosure | Coordinated after fix is released |

---

<a id="disclosure"></a>
## 📢 Disclosure Policy

We follow a **coordinated disclosure** model:

1. Report received and acknowledged
2. Vulnerability validated and severity assessed
3. Fix developed and tested
4. Patch released to all supported versions
5. Public disclosure with credit to reporter (if desired)

> **No premature disclosure.** Do not open public issues or pull requests for security bugs until the fix is released.

---

<a id="considerations"></a>
## 🔍 Security Considerations

### Scope

UMO is a POSIX `sh` installer that runs inside **Termux** on Android. It:
- Downloads and extracts Ubuntu rootfs images
- Configures proot containers
- Installs VNC, PulseAudio, and desktop environments
- Creates wrapper scripts in `$HOME` and `/usr/local/bin`

### Known Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| Rootfs download | Supply-chain / MITM | Only HTTPS mirrors; checksums verified where available |
| Proot execution | Container escape to Termux host | User-space proot — no root required; mounts limited to `dev`, `proc`, `sys`, `sdcard`, `termux` |
| VNC password | Weak default (`ubuntu`) | User must change via `vncpasswd` after first login |
| Sudo inside Ubuntu | `ubuntu` user has passwordless sudo | By design — local single-user Termux environment |
| `$HOME` scripts | Overwritten on re-install | Scripts use `#!/bin/sh` minimal logic; no prompt before overwrite |

### Recommendations

1. **Change the VNC password immediately** after first login:
   ```bash
   vncpasswd
   ```

2. **Only install from the official repository:**
   ```bash
   git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git
   ```

3. **Keep Termux updated** via F-Droid or GitHub — not Play Store.

4. **Never expose VNC port `5901`** to untrusted networks without a tunnel or VPN.

5. **Review `.vnc/xstartup` and `bashrc.patch`** before running if cloned from a fork.

---

<a id="audit"></a>
## 🔬 Security Audit

UMO is written entirely in POSIX `sh` — no compiled binaries, no setuid/setgid, no kernel modules. A full install performs:

- `mkdir -p` under `$HOME`
- `proot` bind mounts
- `pkg install` inside Termux
- `apt-get install` inside the Ubuntu chroot
- `chmod +x` on generated wrapper scripts

All logic is readable in plain shell. If you perform an audit, please share findings via the private reporting channels above.

---

<a id="hall-of-fame"></a>
## 🏆 Hall of Fame

We thank the following security researchers for responsible disclosure:

*(None yet — be the first!)*

---

<div align="center">

Built by <a href="https://github.com/Shadow-x78">Shadow-x78</a> ·
<a href="https://github.com/Shadow-x78/termux-ubuntu-umo">termux-ubuntu-umo</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Shadow-x78</sub>

</div>
