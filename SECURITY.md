# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.1.x   | ✅        |
| < 2.1   | ❌        |

Only the latest minor release receives security updates. Please ensure you are running the most recent version before reporting an issue.

---

## Reporting a Vulnerability

If you discover a security vulnerability in UMO, please report it responsibly.

**Preferred method:**
- Open a **private security advisory** via GitHub: [Security Advisories](https://github.com/Shadow-x78/termux-ubuntu-umo/security/advisories/new)

**Alternative method:**
- Email: `security@shadow-x78.dev` (if available) or via GitHub direct message

**What to include:**
- A clear description of the vulnerability
- Steps to reproduce (minimal PoC if possible)
- Affected component and version
- Impact assessment (privilege escalation, data exposure, etc.)
- Suggested fix or mitigation (optional)

**Response timeline:**
| Phase | Timeframe |
|-------|-----------|
| Initial acknowledgment | Within 72 hours |
| Impact assessment | Within 7 days |
| Patch development | Within 30 days (critical) |
| Public disclosure | Coordinated after fix |

---

## Disclosure Policy

We follow a **coordinated disclosure** model:

1. Report received and acknowledged
2. Vulnerability validated and severity assessed
3. Fix developed and tested
4. Patch released to all supported versions
5. Public disclosure with credit to reporter (if desired)

**No premature disclosure.** Please do not open public issues or pull requests for security bugs until the fix is released.

---

## Security Considerations for UMO

### Scope
UMO is a POSIX shell installer that runs inside **Termux** on Android. It:
- Downloads and extracts Ubuntu rootfs images
- Configures proot containers
- Installs VNC, PulseAudio, and desktop environments
- Creates wrapper scripts in `$HOME` and `/usr/local/bin`

### Known Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| Rootfs download (HTTP mirror) | Supply-chain / man-in-the-middle | Only HTTPS mirrors are configured; checksums verified where available |
| Proot execution | Container escape to Termux host | Proot is user-space; does not require root. Bound mounts are limited to `dev`, `proc`, `sys`, `sdcard`, `termux` |
| VNC password | Weak default (`ubuntu`) | Installer sets default; user is responsible for changing via `vncpasswd` |
| Sudo access inside Ubuntu | `ubuntu` user has passwordless sudo | This is by design for convenience in a local, single-user Termux environment |
| `$HOME` scripts | Overwrite if re-installed | Scripts are created with `#!/bin/sh` and minimal logic; installer does not prompt before overwrite |

### Recommendations for Users

1. **Change the VNC password immediately** after first login:
   ```bash
   vncpasswd
   ```

2. **Only install from the official repository**:
   ```bash
   git clone https://github.com/Shadow-x78/termux-ubuntu-umo.git
   ```

3. **Keep Termux updated** via F-Droid or GitHub releases (not Play Store).

4. **Do not expose VNC port `5901` to untrusted networks** without a tunnel or VPN.

5. **Review `.vnc/xstartup` and `bashrc.patch`** before running if you cloned from a fork.

---

## Security Audit

UMO code is POSIX `sh` — no compiled binaries, no setuid/setgid, no kernel modules. A full install performs the following privileged-equivalent actions:
- `mkdir -p` under `$HOME`
- `proot` bind mounts
- `pkg install` inside Termux
- `apt-get install` inside the Ubuntu chroot
- `chmod +x` on generated wrapper scripts

All logic is readable in plain shell. If you perform an audit, please share findings via the private reporting channels above.

---

## Hall of Fame

We thank the following security researchers for responsible disclosure:

*(None yet — be the first!)*

---

© 2026 Shadow-x78
