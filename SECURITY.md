<div align="center">

# Security Policy - UMO

[![Version](https://img.shields.io/badge/version-4.18.6-2563eb?style=flat-square&logo=semver)](../CHANGELOG.md)
[![License](https://img.shields.io/badge/license-GPL--3.0-dc2626?style=flat-square)](../LICENSE)
![Shell](https://img.shields.io/badge/shell-POSIX%20sh-16a34a?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/platform-Android%208%2B%20%7C%20ARM64-9333ea?style=flat-square&logo=android)

</div>

---

## 📋 Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting)
- [Security Considerations](#considerations)

---

<a id="supported-versions"></a>
## 🛡️ Supported Versions

| Version | Supported |
|---------|-----------|
| 4.17.x (latest) | ✅ Active |
| < 4.17 | ❌ End of Life |

Only the latest minor release receives security updates. Ensure you are on the most recent version (`umo version`) before reporting.

---

<a id="reporting"></a>
## 🚨 Reporting a Vulnerability

If you discover a security vulnerability in UMO, please report it **responsibly** and **privately** - never in a public issue or pull request.

| Channel | Where |
|---------|-------|
| Preferred | [Private security advisory](https://github.com/shadow-x78/ubuntu-modded-optimized/security/advisories/new) |
| Alternative | GitHub direct message to [@shadow-x78](https://github.com/shadow-x78) |

Include: a clear description, reproduction steps (minimal PoC if possible), the affected component and version, and the impact. Expect acknowledgment within 72 hours, an impact assessment within 7 days, and a critical patch within 30 days. Public disclosure is coordinated after the fix is released, with credit to the reporter if desired.

---

<a id="considerations"></a>
## 🔍 Security Considerations

UMO is a POSIX `sh` installer that runs inside Termux on Android: it downloads Ubuntu rootfs images, configures proot containers, installs VNC/PulseAudio/desktop environments, and writes wrapper scripts - all in plain, auditable shell (no compiled binaries, no setuid, no kernel modules).

| Area | Risk | Mitigation |
|------|------|------------|
| Rootfs download | Supply-chain / MITM | HTTPS mirrors only; release tarballs and rootfs archives verified via SHA-256 |
| Proot execution | Container escape to Termux host | User-space proot - no root required; mounts limited to `dev`, `proc`, `sys`, `sdcard`, `termux` |
| VNC exposure | Remote access to the desktop | Server always binds `127.0.0.1` (hardcoded); random per-install password at `~/.umo/vnc-pass` (0600) |
| Sudo inside Ubuntu | `umo` user has passwordless sudo | By design - local single-user Termux environment |

**Do these three things:** change the VNC password (`vncpasswd`) right after first login, install via the official one-liner (release-verified), and never expose port `5901` to untrusted networks without a tunnel. Keep Termux itself updated from F-Droid or GitHub - not Play Store.

---

<div align="center">

Built by <a href="https://github.com/shadow-x78">shadow-x78</a> ·
<a href="https://github.com/shadow-x78/ubuntu-modded-optimized">ubuntu-modded-optimized</a> ·
[Back to README](../README.md)

<sub>&copy; 2026 Ubuntu Modded Optimized (UMO)</sub>

</div>
