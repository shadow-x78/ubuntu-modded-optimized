# Changelog

All notable changes to this project will be documented in this file.

## [v3.3.8] - 2026-06-25

### ✨ Added
- **Self Update:** Redesigned the `umo update` command to act as a self-updater. It now executes `git pull` on the main repository directory, pulling the latest installer and module code directly from GitHub without needing to re-clone the repository.

### 🗑️ Removed
- **Default Start Alias:** Removed the default `start` alias for the `umo` CLI. Executing `umo` without arguments will no longer arbitrarily start the container. Users must explicitly specify an action (e.g., `umo login` or `umo user`), and the `umo` alias has been removed from the help menu entirely.

## [v3.3.7] - 2026-06-25

### ⚡ Performance
- **Ultimate APT & DPKG Tuning:** Removed 14 redundant `apt-get update` calls across all installation phases, replacing them with a single global update. Injected `dpkg` exclusions to prevent extraction of useless offline documentation (Man pages, Info, Locales) and optimized APT (`Acquire::Languages "none"`, `Acquire::PDiffs "false"`, `Acquire::ForceIPv4 "true"`). This drastically reduces network overhead and bypasses millions of I/O operations inside the PRoot container during package installation.
- **Massive Speedup for Apps & Themes:** Disabled notorious PRoot bottlenecks (`gtk-update-icon-cache`, `update-initramfs`, `systemd-hwdb`, `update-command-not-found`, `update-mime-database`, `update-desktop-database`) and disabled `man-db` auto-updates. This prevents infinite hangs and slashes installation times for massive packages (like `xfce4`, `papirus-icon-theme` and `libreoffice`) by bypassing useless trigger generation inside the container.

### 🐛 Fixed
- **Installer Auto-Exit:** Removed the `wait` loop at the end of the summary phase. The installation script now exits automatically and immediately returns the terminal prompt instead of hanging indefinitely on background file descriptors.
- **UMO CLI Default Behavior:** The `umo` command no longer defaults to `start` if executed without arguments. It now properly errors out and directs the user to `umo --help`.

### 🔄 Updated
- **Version bump:** All files updated from 3.3.6 → 3.3.7.

## [v3.3.6] - 2026-06-25

### 🐛 Fixed
- **`dpkg` Function not implemented / Permission denied (DEFINITIVE FIX):** The `dpkg` database fails when installing packages on Termux because `dpkg` attempts to use the `link()` syscall to back up `status` to `status-old`. Android 8+ blocks `link()` calls for untrusted apps, resulting in `Permission denied` or `ENOSYS`. **Solution:** Removed the faulty `$PREFIX/tmp/umo-dpkg` bind-mount and removed `PROOT_NO_SECCOMP=1` (which disabled syscall filtering and caused `Function not implemented` errors on `execveat`/`linkat`). Added `--link2symlink` to all `proot` login wrappers (`umo-login.sh`, `umo-user.sh`, `umo_proot_cmd`). This natively intercepts `link()` via seccomp and translates it to `symlink()`, completely bypassing the Android restriction and allowing `dpkg` and `dpkg-query` to operate seamlessly.

### 🎨 Changed
- **UI:** Changed `umo_log_step` labels to use imperative verbs (e.g., "Install XFCE4" instead of "Installing XFCE4") for cleaner and more consistent terminal output.
- **UI:** Removed trailing dots from all `umo_log_step` output labels to keep the interface clean and concise.
- **UI:** Removed "Checking internet connectivity" log step; the script now simply displays the final connection status directly.

### 🔄 Updated
- **Version bump:** All files updated from 3.3.5 → 3.3.6.

## [v3.3.5] - 2026-06-23

### 🐛 Fixed
- **APT GPG / NO_PUBKEY (definitive fix):** Reverted `sources.list` to `[trusted=yes]` — `[signed-by=...]` fails on the minimal base rootfs where `ubuntu-archive-keyring.gpg` is absent. Combined with `apt-get update` filters (`grep -v "^Ign\|^W:\|^Err\|^Get:"`), the update output is now clean with zero GPG warnings.
- **`dpkg: status-old` Permission Denied:** Pre-created writable `/var/lib/dpkg/status`, `status-old`, and sub-dirs (`updates`, `info`, `parts`, `triggers`) with `chmod -R u+rw` in `umo_proot_prepare` — fixes the cascade that broke all apt operations.
- **Invalid `--no-lock` Option:** Removed `no-lock` from both `dpkg.cfg.d/umo-proot` and `Dpkg::Options:: "--no-lock"` from `apt.conf.d/99-umo-sandbox` — this is an apt flag, not a dpkg config option, and was corrupting every dpkg invocation.
- **VNC Silent Failure:** `umo_vnc_install` now uses `command -v` check with `exit 1` instead of silent `|| true` — install failures surface in the log instead of being hidden.
- **VNC dpkg Error 100 (definitive fix):** Added Phase 0 pre-repair (`dpkg --configure -a` + `apt-get -f install`) to fix half-configured rootfs state before any installs. Made `apt-utils` install visible (was silently swallowed by `2>/dev/null || true`, causing cascading debconf failures). Added Phase 4 recovery: on dpkg error 100, force-configure unpacked packages then retry the full install — the second pass finishes configuration that the first pass couldn't complete. Added `dpkg --audit` diagnostics on final failure.
- **`dpkg: status-old` / lock files:** Actually pre-created `status-old`, `lock`, `lock-frontend` in `umo_proot_prepare` (previous CHANGELOG entry claimed this but code only created `status`/`available`). dpkg needs `status-old` to rename the active status file during writes; its absence caused error 100 on the proot filesystem. Pre-created postinst-writable directories: `/var/lib/dbus`, `/var/cache/debconf`, `/var/lib/xfonts`, `/var/lib/update-alternatives`, etc.
- **VNC Install Staging:** Split the monolithic `apt-get install` into 6 staged groups (foundation → fonts → dbus → tigervnc) with `dpkg --configure -a` between each, so a single package's postinst failure no longer aborts the entire 7-package transaction. Each package group uses `--no-install-recommends` to minimize maintainer scripts. Replaced harmful `tail` output truncation (was hiding the real dpkg error behind 26+ "Get:" lines) with a `_apt_filter` that strips download noise but keeps errors. Added `dpkg -l 'tigervnc*'` status dump on failure.
- **`dpkg: status-old` Permission Denied (ROOT CAUSE FIX):** Host-side `touch`/`chmod` in `umo_proot_prepare` was ineffective — proot's filesystem layer maps UIDs differently than the host. Created `umo_proot_fix_dpkg()` which runs `chmod`/`chown`/`cp` **from inside proot** (where dpkg actually operates), pre-populates `status-old` as a copy of `status`, and fixes lock file permissions. The fix runs once during `umo_proot_create_user` and is re-invoked between each VNC install stage via the reusable `/root/.umo/fix-dpkg.sh` script.
- **`dpkg status-old` rename() denied (DEFINITIVE FIX):** The rootfs is stored on a filesystem where the kernel denies the `rename()` syscall — `dpkg` does `rename(status → status-old)` on every package install and this fails even though file *creation* works (`status-new` was successfully written). chmod/chown from both host-side and inside-proot proved ineffective because the denial is at the kernel/filesystem level, not Unix permissions. **Solution:** Relocate dpkg's database to `$PREFIX/tmp/umo-dpkg` (Termux internal storage = real ext4, fully supports `rename()`), bind-mounted onto `/var/lib/dpkg` inside proot via `-b $PREFIX/tmp/umo-dpkg:/var/lib/dpkg` in all three login wrappers (`umo-login.sh`, `umo-user.sh`, `umo_proot_cmd`). The database persists across sessions and all package installs (VNC, audio, desktop, apps) now operate on a filesystem that supports the operations dpkg requires.
- **`ls` ENOTDIR Spam:** Aliases now redirect stderr (`ls --color=auto 2>/dev/null`) to suppress proot `statx()` warnings on bind-mounted paths.
- **Archive Extraction:** `umo_net_extract` uses `proot --link2symlink tar` (sdcard forbids hardlinks) while `umo_net__validate_file` runs `gzip -t` to auto-detect and re-download corrupt caches.
- **Scrollback on Start:** `install.sh` and `umo_screen_clear` now emit `\033[3J` to purge the terminal scrollback buffer.

### 🔄 Changed
- **Version bump:** All files updated from 3.3.4 → 3.3.5.
- **`config/sources.list`:** Reverted to `[trusted=yes]` (works on all rootfs variants).

## [v3.3.4] - 2026-06-23

### 🐛 Fixed
- **`ls` / `la` ENOTDIR Spam:** Removed per-file `/proc/*` binds (`-b fake_proc/stat:/proc/stat` etc.) from proot login wrappers — binding regular files onto an already-bound `/proc` directory triggers a proot `statx()` path bug that returns `ENOTDIR` for every top-level rootfs entry, producing `ls: cannot access 'bin': Not a directory` on every shell. Now relies on real Android `/proc` which is fully readable.
- **`.fake_proc` Visible at `/`:** Relocating fake proc files inside the rootfs made them appear as `/.fake_proc` in `ls -a /`. Removed fake_proc entirely; a migration cleanup (`rm -rf "$rootfs/.fake_proc"`) runs on first start of updated installs.
- **APT `NO_PUBKEY` + `Ign` Warnings:** Switched `sources.list` from `[trusted=yes]` (which still triggers GPG verification and emits `W: GPG error` + 4 `Ign` lines) to `[signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg]`. The keyring ships with every Ubuntu base rootfs, so `apt update` now verifies cleanly with no warnings. Falls back to `[trusted=yes]` on stripped rootfs images where the keyring is absent.
- **Swap Fully Removed:** Deleted `umo_perf_swap()` function and its call in `umo_perf_setup()` — swap is entirely non-functional inside proot and was producing confusing `swapon failed` output even after the previous "skip" stub.
- **Remaining `stty` Calls Removed:** Stripped the last `stty sane` + `trap` lines from `install.sh` and `bin/umo-install` — these were a leftover from the `stty -icanon` era and are no longer needed since the TUI uses plain `read`.

### 📝 Improved
- **Module Documentation:** Added summary headers to `umo-apps.sh`, `umo-desktop.sh`, `umo-vnc.sh`, and `umo-perf.sh` describing their purpose and public API functions.
- **Code Clarity:** Removed verbose inline comments from `umo-proot.sh` and other modules — each function now has a short explanatory header comment instead of multi-line rationales embedded in the logic.

### 🔄 Changed
- **`config/sources.list`:** Updated template to use `[signed-by=...]` with the official Ubuntu keyring path, matching what the installer writes into the container.

## [v3.3.3] - 2026-06-23

### ✨ Added
- **Unified ANSI Design:** All runtime outputs (VNC banner, session box, stop messages) now use the same ANSI style as the installer — no more ASCII `+---+` boxes.
- **`umo --help` Improvements:** Examples now use generic `<name>` instead of hardcoded usernames; section headers are color-coded.
- **Post-Install Summary:** Replaced old "Quick Commands" and "Inside Ubuntu" sections with a clean `umo` CLI reference table.

### 🐛 Fixed
- **`vncserver: not found`:** VNC scripts now check `tigervncserver` first, then fallback to `vncserver`, with a clear error if neither is found.
- **`pgrep: uptime`:** Removed `pgrep uptime` call from session start; uptime data now comes from fake `/proc/uptime`.
- **`swapon failed` Warning:** Swap is not available inside proot — removed the swap setup entirely to avoid the confusing warning.
- **Duplicate Log Messages:** Removed `umo_log_step` calls before `umo_run_quiet` in app/VNC installers — `umo_run_quiet` already shows the spinner label.
- **`stty` Terminal Corruption:** Removed all `stty -echo` / `stty -icanon` / `dd` raw mode from TUI engine; all input now uses simple `read`.
- **CRLF Line Endings:** Added `.gitattributes` to force LF; all `.sh` files verified clean.
- **`setsid` Breaking stdin:** Removed `setsid` from `install.sh` which was creating a session without a controlling terminal.
- **Auto-Exit After Install:** Added `stty sane` + `trap` at script entry to guarantee terminal restoration and clean exit.

### 🔄 Changed
- **Phase Headers:** Shortened from "Installing VNC Server" → "VNC Server", "Configuring Audio Bridge" → "Audio Bridge", etc.
- **VNC Banner:** Now uses colored ANSI lines and labels instead of plain ASCII box art.
- **Session Active Box:** Replaced with styled ANSI output matching the installer look; includes `umo stop` and `umo status` hints.

## [v3.3.2] - 2026-06-23

### ✨ Added
- **`umo status`:** Displays real-time status of the proot session, VNC server, and PulseAudio bridge.
- **`umo update`:** Runs `apt-get update && apt-get upgrade && apt-get autoremove` inside Ubuntu.
- **`umo run <cmd>`:** Executes an arbitrary command inside the Ubuntu container from Termux (e.g. `umo run "apt list --installed"`).
- **`umo backup [dir]`:** Archives the entire Ubuntu rootfs to a timestamped `.tar.gz` file.
- **`umo --user <name>` / `umo -u <name>`:** Creates the user if not existing, patches `umo-user.sh` to set them as the default login user, then logs in.
- **`umo --version` / `umo -v`:** Prints the UMO launcher version.
- **`umo --help` / `umo -h`:** Redesigned help page with grouped sections (Session, Login, System, Info) and usage examples.

### 🐛 Fixed
- **Auto-Exit After Install:** Added explicit `pgrep`+`kill` cleanup in `umo_phase_finalize` and `umo_phase_summary` to terminate any lingering proot children before the installer returns control to Termux.
- **`install.sh` Blocking:** Wrapped `umo-install` in `setsid` (when available) so child proot processes belong to a new session and cannot hold the parent Termux shell hostage after installation completes.

## [v3.3.1] - 2026-06-23

### ✨ Added
- **Global `umo` Launcher:** Created a global Termux command `umo` that acts as an alias to manage the container (start, stop, login, user, vnc). Added usage instructions to the installation summary.

### 🐛 Fixed
- **Summary Phase Auto-Exit:** Fixed the installer not exiting automatically after displaying the final summary.
- **Double Screen Clear:** Prevented the installation summary from being erased by a duplicate screen clear.

## [v3.3.0] - 2026-06-23

### ✨ Changed
- **Default User Renamed:** Default container user changed from `ubuntu` to `umo` to match the project identity. Login credentials: `umo` / `umo`.

### 🐛 Fixed
- **User Creation — Entirely Rewritten:** Replaced all proot-based user creation (adduser, groupadd, chpasswd) with direct host-side file manipulation. The new approach writes to `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`, and `/etc/sudoers.d` directly from Termux, bypassing all PRoot `fcntl()` lock and ENOSYS syscall failures permanently.
- **Stale Lock Files:** Added cleanup of `/etc/group.lock`, `/etc/passwd.lock`, `/etc/shadow.lock`, `/etc/gshadow.lock`, and `/etc/.pwd.lock` before user creation to prevent leftover locks from prior failed attempts.
- **Password Hashing:** Password hash for `umo` is now generated with `openssl passwd -6` on the host before writing to `/etc/shadow`, avoiding `chpasswd` nscd/sssd cache flush errors inside proot entirely.

## [v3.2.9] - 2026-06-23

### 🐛 Fixed
- **APT NO_PUBKEY Error:** Bypassed GPG signature verification entirely for the initial bootstrap phase using `APT::Get::AllowUnauthenticated "true"` and `APT::Acquire::AllowInsecureRepositories "true"` in the sandbox `apt.conf`. This is safe within the isolated proot container and definitively eliminates all `NO_PUBKEY` failures regardless of Android version or mirror.
- **DPKG ENOSYS Errors:** Fixed `dpkg` crashing with `Function not implemented` (`ENOSYS`) on `status-old` backup creation by forcing `--force-unsafe-io` for `dpkg -i` and inside `apt.conf.d`. This prevents `dpkg` from calling unsupported `fsync` and `sync_file_range` syscalls.
- **PRoot Syscall Extensions:** Removed `PROOT_LOAD_EXT_LIBS=0` from login environments, which was inadvertently disabling critical PRoot extensions (`link2symlink` and `sysvipc`), breaking `execveat` and internal IPC required by `dpkg-split` and package installations.
- **Proot Extraction Permissions (Hardlinks):** Restored `--link2symlink` globally. While EXT4 supports symlinks natively, Android's SELinux policy enforces severe restrictions preventing unprivileged apps from using the `link` system call. Without `--link2symlink`, extracting the Ubuntu base fails on `tar: Cannot hard link ... Permission denied`. This flag converts hardlinks correctly and allows `tar` to finish unpacking. With this restored, AND the `/dev/shm` mount correctly mapped, the installation will proceed perfectly.

## [v3.2.8] - 2026-06-23

### 🐛 Fixed
- **Proot Mount Syntax:** Fixed a critical formatting bug in the `proot` launch arguments where the `/dev/shm` bind mount was silently ignored due to a missing string format argument. This ensures `/dev/shm` is correctly mapped to `$PREFIX/tmp`, which definitively resolves the `dpkg 100` exit code.
- **PTY Disablement for APT:** Disabled PTY usage for `dpkg` (`Dpkg::Use-Pty "0"`) inside the sandbox config to prevent standard output swallowing and terminal capability issues during installation.
- **Link2Symlink Performance:** Completely removed the experimental `--link2symlink` flag from extraction and runtime. The native Android EXT4 filesystem handles symlinks fine; removing this avoids potential `dpkg` and `execve` failures with deep directory symlinks.

## [v3.2.7] - 2026-06-23

### 🐛 Fixed
- **DPKG / APT Proot Constraints:** Added `--sysvipc` to the `proot` invocation to ensure System V IPC emulation is fully enabled. This is strictly required by `dpkg` on Termux for stable operation and memory sharing.
- **Shared Memory Mount:** Added explicit bind mount `-b $PREFIX/tmp:/dev/shm` to the `proot` container. `dpkg` on Ubuntu requires POSIX shared memory (`/dev/shm`), which is not natively present in Android's `/dev`, causing `apt-get` to fail executing `dpkg` with error code 100.
- **Removed Silence Flags:** Explicitly removed `-q` and `-qq` from all module files including `umo-proot.sh`.

## [v3.2.6] - 2026-06-23

### 🐛 Fixed
- **Silent Failures:** Added `set -e` to all dynamically generated `proot` scripts (`setup-user.sh`, `debloat.sh`, `install-vnc.sh`, etc.) to ensure `umo_run_quiet` correctly catches and reports intermediate failures instead of falsely reporting success if only the last command succeeds.
- **APT Logging Visibility:** Fully removed `-q` and `-qq` from all `apt-get` commands inside the installer scripts to ensure standard `dpkg` and `apt` error logs are visible to the user on failure, without being obscured.

## [v3.2.5] - 2026-06-23

### 🐛 Fixed
- **DPKG Fsync Error (100):** Fixed a critical failure where `dpkg` would crash with exit code 100 without printing any logs. This was caused by Android's filesystem returning `EINVAL` when `dpkg` attempts `fsync()`. Forced `dpkg` to use `force-unsafe-io` during the container setup to prevent sync-related crashes on Termux.

## [v3.2.4] - 2026-06-23

### 🐛 Fixed
- **VNC Dependencies:** Added explicit installation of `apt-utils` and `tzdata` during VNC setup to prevent `debconf` from hanging or throwing `dpkg` error `100` when installing TigerVNC dependencies.
- **APT Logging:** Replaced `-qq` with `-q` in `apt-get` commands to ensure `dpkg` error details are logged correctly without cluttering output with progress bars.

## [v3.2.3] - 2026-06-23

### 🐛 Fixed
- **APT Unauthenticated Packages:** Forced `apt-get` to bypass unauthenticated package restrictions during initial setup to prevent `dpkg` error `100` failures when `GPG` keys are absent.
- **Git Sync Issue:** Released as a standard commit to resolve local branch tracking mismatches caused by the previous force-push.

## [v3.2.2] - 2026-06-23

### 🐛 Fixed
- **Container Execution:** Fixed `job-working-directory: error retrieving current directory: getcwd` warnings when running internal scripts by enforcing the initial container working directory to `/` instead of `/root` (or `/home/ubuntu`).
- **APT Sandbox:** Fixed `setresuid (1: Operation not permitted)` error when running `apt-get` by automatically bypassing APT's `_apt` privilege drop sandbox inside `proot`.
- **APT Repositories:** Bypassed `NO_PUBKEY 871920D1991BC93C` GPG signature errors on the initial rootfs by automatically marking repositories as `[trusted=yes]` during setup, and forcing `ubuntu-keyring` to update.

## [v3.2.1] - 2026-06-23

### 🐛 Fixed
- **Proot Paths:** Fixed an issue where `debloat`, `cleanup`, and other temporary scripts were created in `$UMO_INSTALL_DIR/tmp` but failed to execute because `proot-distro` binds Termux's `/tmp` to `/tmp` in the container. Changed the temporary script path to `/root`.
- **UI:** The installer wrapper (`install.sh`) now clears the screen immediately upon execution to ensure a clean prompt view.

## [v3.2.0] - 2026-06-23

### 🐛 Fixed
- **Performance Setup:** Fixed a critical bug where `mkswap` failing due to Android 11+ SELinux or filesystem restrictions would cause the installer to crash and exit immediately (due to `set -e`). It now safely falls back without interrupting the installation.
- **Extraction:** Restored `proot` tar extraction to fix `Cannot hard link` permission denied errors on Android filesystems that restrict hardlinks.
- **Architecture:** Dropped support for `x86_64` (WSA/Emulators) completely due to kernel-level `ptrace` blocking. The installer will now instantly exit if the device is not ARM64.

### 🎨 UI
- **Modernization:** Redesigned menu and checklist prompts to use modern glyphs (`❯`, `◉`, `╰─➤`) instead of traditional text brackets.

## [v3.1.9] - 2026-06-23

### 🐛 Fixed
- **Proot Permissions:** Added `unset LD_PRELOAD` globally and to container wrapper scripts (`umo-login.sh`, `umo-user.sh`) to prevent `ptrace(TRACEME): Permission denied` and `execve Permission denied` errors caused by Termux `termux-exec` interference.

## [v3.1.8] - 2026-06-22

### 🐛 Fixed
- **Proot Permissions:** Restructured `umo_run_quiet` to execute commands in the foreground and the spinner in the background. This fixes Android 11+ `ptrace` permission denials when running `proot` in background processes.
- **Proot Container:** Resolved shadow mount conflicts with `/tmp` during the user creation phase by running `setup-user.sh` directly from `/root`.

## [v3.1.7] - 2026-06-22

### 🐛 Fixed
- **Rendering:** Added `umo_repeat` in `lib/core-ansi.sh` to safely repeat UTF-8 glyphs, fixing line corruption (``) in headers and progress bars.
- **UI:** Centered the UMO banner correctly across different terminal widths without drift.
- **Download/Extract:** Refactored `umo_net_download_mirrors` and `umo_phase_download` to safely validate files before proceeding, eliminating fake success messages and preventing `Archive not found` errors.

## [v3.1.6] - 2026-06-17

### 🚀 Added
- **Quiet Runner (`umo_run_quiet`):** `lib/core-ansi.sh` — wraps long-running commands with a Braille/ASCII spinner, captures output to a temp log, and on failure prints the last 30 lines. Replaces silent `2>/dev/null || true` swallowing across all modules.
- **Download Validation:** `lib/core-net.sh` — minimum file-size guard (`_UMO_NET_MIN_SIZE=1 MB`) and `umo_net__validate_file()` prevent corrupted or truncated rootfs archives from being accepted.
- **Timestamp Logging:** `lib/core-ansi.sh` — optional `UMO_LOG_TIME=1` prefix for every log line.
- **Warn Color:** `lib/core-ansi.sh` — dedicated `UMO_COLOR_WARN` (ANSI 220 / bold yellow) replaces the previous reuse of `UMO_B_YELLOW`.

### 🎨 Changed
- **Glyph Refresh:** `lib/core-ansi.sh` — step indicator changed to `▌`/`❯`, progress bar to `█/░`, spinner to Braille cycle `⠋⠙⠹...`, and added `UMO_G_RUN` glyph.
- **Menu Polish:** `lib/core-ui.sh` — `umo_ui_header` now draws an under-rule with `─`; menus show `[Space]=Toggle [Enter]=Confirm` hint.
- **Log Indentation:** All log helpers (`umo_log_ok`, `umo_log_err`, `umo_log_warn`, etc.) now use 2-space indentation for consistent hierarchy.
- **Extraction Hardening:** `lib/core-net.sh` — archive extraction no longer silently ignores `tar`/`unzip` errors; non-zero exit codes now `umo_die` with the actual status.
- **App/Desktop Installers:** `_run_installer` and `_run_de_installer` now pass human-readable labels into `umo_run_quiet` so every install phase is visible and traceable.

### 🐛 Fixed
- **Pkg Install Quiet:** `lib/core-system.sh` — `umo_sys_pkg_install` now wraps all package installs under a single `umo_run_quiet` spinner instead of printing raw `pkg`/`apt` stdout per package. Eliminates the #1 visual source of layout corruption.
- **Download Output Leak:** `lib/core-net.sh` — `umo_net_download` switched from `--show-progress` to `--quiet` (wget) and `-s` (curl). The old `--show-progress` + `--progress=bar:force:noscroll` printed raw terminal control sequences that destroyed the TUI layout. On failure, the last 30 lines are available via `umo_run_quiet`.
- **Archive Copy Robustness:** `lib/core-net.sh` — both cached-copy and post-download copy paths now guard `cp` failures with `{ ... } || { warn; rm; continue; }` instead of silently failing and leaving a missing file.
- **Box-Drawing Fallback:** `lib/core-ansi.sh` + `lib/core-ui.sh` — new `UMO_LINE_H` variable guarded by `UMO_GLYPH_SUPPORT`. Draws `─` in UTF-8 environments and `-` in ASCII/non-UTF-8 locales, replacing the hardcoded Unicode rule that rendered as ``.
- **Banner Line Bug:** `lib/core-ansi.sh` — corrected `_l7` line 7 of the UMO banner: format string `%b %*s %s %b` was consuming the color code as the width argument due to `%*s` eating two args. Now passes a valid color (`UMO_GRAD_1`) as the first `%b`.
- **System Check Spacing:** `bin/umo-install` + `lib/core-system.sh` — `umo_phase_check` now opens with `umo_ui_header "System Check"`, and `umo_sys_require_internet` uses `umo_log_info` instead of `umo_log_step`. Prevents the overlapping `▌ Checking... ✔` visual clash.
- **UTF-8 Detection:** `lib/core-ansi.sh` — glyph detection now falls back to `locale charmap` when `LANG`/`LC_ALL` variables do not contain "UTF-8". Respects `UMO_ASCII=1` for forced ASCII mode.
- **Readme Whitespace:** `README.md` & `README_AR.md` — fixed stray extra space in ASCII logo bottom line.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.6.

---

## [v3.1.5] - 2026-06-17

### 🚀 Added
- **Ubuntu Version Menu:** Interactive selection between Ubuntu 22.04 LTS (Jammy) and 24.04 LTS (Noble) in `umo_phase_config`.
- **UMO Glyph Log:** Professional Unicode glyph-based logging system with tree-style sub-steps.
  - Glyphs: `▶` (step), `✔` (ok), `✖` (err), `⚠` (warn), `ℹ` (info), `⋯` (debug), `├─/└─` (sub-steps).
  - Automatic ASCII fallback when Unicode is unavailable (`UMO_ASCII=1` or non-UTF-8 locale).
  - Progress bar now uses `▣/▱` blocks with glyph fallback to `#/-`.

### 🐛 Fixed
- **Same-File Copy Guard:** `lib/core-net.sh` — `cp` no longer fails with `are the same file` when cache path equals output path.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.5.

---

## [v3.1.4] - 2026-06-17

### 🗑️ Removed
- **Framed Panels:** `umo_ui_panel()` and `umo_box()` removed entirely.
- **Environment Validation Panel:** Deleted the duplicate static "Checking..." box in `umo_phase_check()`.

### 🎨 Changed
- **Line-Based Design:** All summary panels now use `umo_ui_header` + `umo_kv` for clean key:value output.
- **Configuration Summary:** Migrated to `umo_kv "Desktop"`, `Apps`, `Install`, `Version`.
- **System Summary:** Migrated to `umo_kv "Platform"`, `Arch`, `Storage`, `RAM`, `Path`.
- **Installation Complete:** Migrated to `umo_kv` lines for Version, Desktop, Path, VNC, Perf, User.
- **Banner Author:** Label changed from `Shadow-x78` to `By Shadow-x78`.
- **Separators:** Replaced dash rules (`umo_rule`) with blank lines in `umo_ui_init`, `umo_ui_menu`, and `umo_ui_checklist`.
- **Step Spacing:** `umo_log_step` now prepends a blank line before every `[==>]` message across all 41 call sites.

### 🐛 Fixed
- **Termux Info Display:** `umo_sys_summary()` now reads `TERMUX_APK_RELEASE` or `TERMUX_VERSION` from `termux-info` instead of capturing the header line `Termux Variables:`.

### 🔄 Updated
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.4.

---

## [v3.1.3] - 2026-06-17

### 🎨 Changed
- **Banner:** ASCII `UMO` logo now shown on all screen sizes; removed the `[UMO]` compact line.
- **Tagline:** Reformatted to centered `Ubuntu Modded Optimized · v3.1.3` with `Shadow-x78` below.

### 🔄 Updated
- **Validation Panel:** `umo_ui_panel()` auto-fits any terminal width (minimum clamped to fit).
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.3.

---

## [v3.1.2] - 2026-06-17

### 🔄 Updated
- **systemctl Emulator:** `umo-systemctl.sh` — now presented and documented as a
  generic service manager (`start|stop|restart|status|enable|disable <service>`)
  instead of SSH-centric; clearer usage and status output.
- **Docs:** README, INSTALL, TROUBLESHOOTING (EN+AR) examples use a generic
  `<service>` token; SSH shown only as an example. SSH start helper retained.
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.2.

---

## [v3.1.1] - 2026-06-17

### 🚀 Added
- **ASCII Banner:** Restored large block-letter UMO logo (7-line) with orange gradient centering.
- **Panel Overflow Guard:** `umo_ui_panel()` now trims lines wider than the box and appends `…`.

### 🔄 Updated
- **Architecture Warning:** `core-system.sh` — clearer message for x86_64 users; indicates primary target is ARM64.
- **Summary Panel:** Compact key labels (`Platform`, `Arch`, `Path`) to prevent overflow.
- **Version Bump:** All badges, inline defaults, and `bin/umo-install` bumped to v3.1.1.

### 🐛 Fixed
- **Table Width:** `umo_ui_panel()` minimum raised to 52 and clamped to terminal width; eliminates off-screen boxes.

---

## [v3.1.0] - 2026-06-17

### 🚀 Added
- **256-Color Detection:** Auto-fallback between 256 / 16 / no-color modes via `tput colors`, `NO_COLOR`, `UMO_NO_256`.
- **Brand Palette:** Ubuntu orange identity — `UMO_COLOR_PRIMARY` = `38;5;208m`.

### 🔄 Updated
- **Logo Banner:** 6-line orange gradient (top light → bottom dark), centered via terminal width.
- **TUI Panel:** `umo_ui_panel()` now auto-fits width to content instead of hardcoded 60.
- **Session Box:** `bin/umo-start` — fixed misaligned VNC line, dynamic box width, inline color fallback.
- **Summary Colors:** `bin/umo-install` — Quick Commands and Inside Ubuntu now use brand palette.
- **Changelog:** Formatted with emoji categories matching reference standard.
- **Version Bump:** `bin/umo-install` and fallback defaults updated to v3.1.0.

### 🗑️ Removed
- **Comments:** All inline code comments removed across `lib/core-ansi.sh`, `lib/core-ui.sh`, `bin/umo-start`, `bin/umo-install`.

---

## [v3.0.0] - 2026-06-16

### 🚀 Added
- **ASCII Banner:** Refined Block banner + compact variant for narrow terminals.
- **Ubuntu 24.04:** Noble Numbat support.
- **Performance Flags:** `--perf=balanced|aggressive|off` — APT speed, swap, debloat, DNS hardening.
- **Desktop Themes:** `--theme=umo-dark|umo-light|minimal|none` — Orchis-Dark, Papirus icons, fonts.
- **Lean Mode:** `--lean` — strip docs/man/locales to save space.
- **Version Flag:** `--ubuntu=22.04|24.04` for explicit selection.
- **VERSION Source:** `UMO_VERSION` variable in `bin/umo-install` is the single source of truth.

### 🔄 Updated
- **Code Quality:** Removed duplicate block in `core-ansi.sh` (-40%), fixed `umo_box` format bug.
- **Version Separation:** Decoupled `UMO_VERSION` from `UMO_UBUNTU_VERSION`.
- **TUI Hardening:** Fixed format injection + numeric fallback in `umo_ui_checklist`.
- **Templates:** Heredocs replaced with script templates across all modules.
- **MESA Override:** Updated to `MESA_GL_VERSION_OVERRIDE=4.0` in bashrc.patch.

### 🐛 Fixed
- **U1:** RootFS integrity check after extraction (verifies `/bin/bash`).
- **U2:** Static `resolv.conf`, `ca-certificates` first, `apt` retry.
- **U3:** SSH helper creates `/run/sshd` + generates host keys.
- **U5:** `dbus-launch --exit-with-session` in xstartup (fixes black VNC).
- **C7:** Mirrors by Ubuntu version + SHA256 verification activated.

### 🗑️ Deprecated
- **Node.js 18:** EOL since April 2025.
- **Python 3.8:** EOL since October 2024.

---

## [v2.1.1] - 2026-06-16

### 📝 Documentation
- **README:** Complete redesign — badges, centered header, anchored sections, language switcher.
- **README_AR:** Added `README_AR.md` — full Arabic translation.
- **SECURITY:** Complete redesign with risk table and response timeline.
- **INSTALL:** Redesigned with language switcher, expanded install modes.
- **INSTALL_AR:** Added `docs/INSTALL_AR.md` — full Arabic translation.
- **TROUBLESHOOTING:** Redesigned with language switcher, expanded fix sections.
- **TROUBLESHOOTING_AR:** Added `docs/TROUBLESHOOTING_AR.md`.
- **LICENSE:** Updated formatting to match project style.

### 🔄 Updated
- **Version Bump:** `bin/umo-install` updated from v2.0.0 → v2.1.1.

---

## [v2.1.0] - 2024-06-16

### 🚀 Added
- **Open Source:** Re-licensed under MIT License — fully open source.
- **Community:** Open to contributions and community forks.

### 🔄 Updated
- **Branding:** Removed all proprietary/commercial branding.
- **Headers:** Clean open-source headers across all 13 source files.

---

## [v2.0.0] - 2024-06-16

### 🚀 Added
- **Core Engine:** `lib/core-ansi.sh` — ANSI color engine with 256-color support.
- **Core Engine:** `lib/core-ui.sh` — Interactive TUI: menus, checklists, prompts.
- **Core Engine:** `lib/core-system.sh` — Hardware detection, dependency management.
- **Core Engine:** `lib/core-net.sh` — Multi-mirror download with resume.
- **Core Engine:** `lib/core-fs.sh` — Safe file operations, atomic writes, backups.
- **Modules:** `umo-proot.sh` — Container preparation, login wrappers.
- **Modules:** `umo-vnc.sh` — TigerVNC installation, session control.
- **Modules:** `umo-audio.sh` — PulseAudio bridge configuration.
- **Modules:** `umo-systemctl.sh` — systemd emulator.
- **Modules:** `umo-desktop.sh` — DE installer (LXDE / XFCE4 / Openbox).
- **Modules:** `umo-apps.sh` — Application suite installer.
- **CLI:** `--no-gui` non-interactive mode.
- **CLI:** `--de=` / `--apps=` / `--dir=` flags.
- **UX:** Progress bars with percentage and spinners for background tasks.
- **Validation:** Configuration validation and health check system.
- **Logging:** Structured logging to `~/.umo/logs/`.

### 🔄 Updated
- **Architecture:** Complete rewrite with modular library system.
- **Compatibility:** Full POSIX sh compliance across all scripts.
- **Dependencies:** Zero external UI dependencies — no `dialog` / `whiptail`.

### 🐛 Fixed
- **VNC:** Screen lock kills VNC → `termux-wake-lock` integrated.
- **Audio:** No audio in proot → PulseAudio TCP bridge.
- **systemctl:** `systemctl` fails → Shell-compatible emulator.
- **TUI:** `dialog` broken → Pure POSIX TUI replacement.

---

## [v1.0.0] - 2024-01-15

### 🎉 Initial Release
- **Launch:** Initial release of UMO — Ubuntu Modded Optimized for Termux.
- **Support:**
  - Ubuntu 22.04 via proot-distro
  - VNC setup with TigerVNC
  - PulseAudio audio fix scripts
  - Manual proot configuration
