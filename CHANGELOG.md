# Changelog

All notable changes to this project will be documented in this file.

## [v4.9.6] - 2026-08-23

### 🐛 Fixed
- **`umo update` never updated the in-container VNC scripts - the reason everything since v4.8.0 seemed broken on existing installs:** `/usr/local/bin/umo-startvnc` and `umo-stopvnc` were written only during the first install, so every VNC fix shipped in v4.9.0-v4.9.5 (lock cleanup, supervisor, direct Xtigervnc launch) never reached an already-installed device. This is why v4.7.0-and-below "just worked": the install-time script was fine and the container never changed. The scripts now live in `config/container/` and `umo update` redeploys them into the container on every run, together with a re-rendered `xstartup` (root and `umo` user) that carries the wallpaper/desktop-init fix to old installs.

### 🔧 Changed
- `umo-stopvnc` simplified to direct process termination + lock cleanup (no dependency on the tigervncserver wrapper).
- CI now syntax-checks `config/container/*`.

## [v4.9.5] - 2026-08-23

### 🐛 Fixed
- **VNC died every ~5 seconds, permanently:** the `tigervncserver` wrapper exits after spawning Xtigervnc, leaving it an orphan - and Android's phantom process killer terminates orphans on its ~5s scan. The start script now launches the `Xtigervnc` binary **directly as a child of its own live supervisor**, so it always has a living parent and is never an orphan; no ADB required.
- **Session lifecycle decoupled from server:** xstartup/desktop now runs as a supervised sibling process with per-process restarts (server up to 5 times, desktop session relaunches independently), so a crashed XFCE session no longer takes the VNC server down.
- **Precise liveness checks:** supervisor uses `kill -0` on exact PIDs instead of name-based `pgrep`, eliminating false dead/alive detections.
- **Real X authority handling:** the start script generates its own MIT-MAGIC-COOKIE `.Xauthority` (the previous `/usr/bin/xauth: file /root/.Xauthority does not exist` warning) and passes `-auth` to the server; xstartup failures are captured in `/root/.vnc/session.log`, server output in `/root/.vnc/xvnc.log`.

## [v4.9.4] - 2026-08-23

### 🐛 Fixed
- **VNC auto-close:** the in-container start script is now a supervisor that relaunches the VNC server up to 3 times if it dies, clearing stale X locks before each restart, instead of passively watching it exit.

### 🗑️ Removed
- **The VNC public/LAN exposure option (`UMO_VNC_PUBLIC`) was deleted outright:** the server now always binds `127.0.0.1` with no opt-out; the flag, its forwarding through every wrapper, and all "localhost-only / public" banner wording were removed from scripts, install summary, in-container README and docs. Security posture simplified to same-device-only access.

### 📖 Docs
- New troubleshooting section for Android 12+ phantom process killing (the real cause of sessions dying on their own) with the one-time ADB fix; `umo start` failures print the same guidance.

## [v4.9.3] - 2026-08-23

### 🐛 Fixed
- **`umo start` reported "Session Active" even when VNC died instantly:** the launch output was discarded to `/dev/null` and success was never verified. `umo start` now waits, checks the Xvnc process for real, and on failure prints the last log lines plus the fix hint instead of a false-positive banner.
- **Stale X locks blocked VNC relaunch:** after an unclean stop (`pkill -9`), leftover `/tmp/.X1-lock` / `.X1` sockets could make TigerVNC refuse to start. The in-container start script now clears stale locks and pid files for its display before launching.
- **VNC start output is now kept** at `~/.umo/logs/vnc-start.log` instead of being thrown away, so failures are diagnosable after the fact.

## [v4.9.2] - 2026-08-23

### 🐛 Fixed
- **`umo update` skipped in-container hooks** ("Container is not running, skipping in-container hooks"): the guard required an already-running proot session, but `umo-login.sh` starts its own proot instance per invocation. Hooks (dpkg-lock cleanup + group sync) now always run during update.
- **Group sync never reached existing installs:** it lived only in the installer and the update hook - neither of which runs on a device that just updated. `umo-login.sh` itself now syncs missing Android GIDs into `/etc/group` on every login/session start, so any install self-heals after one host-script refresh (`umo update`) plus the next `umo login` / `umo start`.
- **Stale version banner:** `umo update` refreshed everything except the `$PREFIX/usr/bin/umo` wrapper, so the banner kept showing the old version (e.g. "UMO v4.9.0" after updating to 4.9.1). The update flow now patches the wrapper's `_UMO_VERSION=` line to match the installed release.

## [v4.9.1] - 2026-08-23

### 🐛 Fixed
- **Black desktop - real root cause:** `xfdesktop` itself was never installed; the XFCE package set shipped panel/session/wm but no desktop renderer, so no wallpaper configuration could ever draw anything. Added `xfdesktop` to the XFCE install set - combined with the v4.9.0 backdrop fix and `umo-desktop-init`, the wallpaper now actually renders on VNC sessions.
- **`groups: cannot find name for group ID …` after `umo login`:** container `/etc/group` seeded a hardcoded Android GID list, but supplemental GIDs differ per device (e.g. 20510, 50510, 99909997). Seeding now merges every GID of the live Termux session (`id -G`) at install time, and the `umo update` in-container hook syncs still-missing groups onto existing installs without reinstalling.
- **Finalizing spinner:** heavy finalize/perf steps now stream live apt/dpkg output instead of hiding behind an animated spinner that looked frozen for minutes.

### 🔧 Changed
- xfwm4 decorations switched from `Greybird` to `Greybird-dark` to match the dark GTK/icon set.

## [v4.9.0] - 2026-08-23

### ✨ Added
- **Firefox ESR in the `basic` app set:** every app set (basic/dev/media/full) now ships a full browser; `umo_apps_browsers` remains for backward compatibility with the full set.
- **Rootfs SHA-256 verification:** downloads from release mirrors are now verified against known Ubuntu cdimage SHA-256 checksums (22.04.5 + 24.04.3/24.04.4, arm64/armhf); a mismatch deletes the archive and fails over to the next mirror. Mirrors without a published checksum (daily-current) log `SKIP checksum`.
- **Random VNC password:** first install generates a random 8-character VNC password (`UMO_VNC_PASSWORD` overrides), persists it to `~/.umo/vnc-pass` (chmod 600) and shows the real password in the install summary and the in-container README.txt.

### 🔧 Changed
- **Install summary:** removed the duplicate `umo --help` row from "Get Started" (the bottom hint stays); added `umo start`, `umo stop`, `umo vnc`, `umo status`, `umo run "<cmd>"`, `umo backup`, `umo uninstall`; widened the label column to fit `umo --user <name>`; embedded README.txt updated to the same command set.
- **XFCE wallpaper root-cause fix:** `xfce4-desktop.xml` now stores backdrop properties under `monitor0/workspace0` (previously directly under `monitor0`, which XFCE ignores → black desktop) with `image-show=true` and zoomed `image-style=5` plus a dark fallback color. New in-container helper `/usr/local/bin/umo-desktop-init` (launched ~4s into each XFCE session by xstartup) re-applies wallpaper to *every* monitor xfconf discovers (VNC monitors are not always named `monitor0`) and hides desktop icons for a clean professional look.
- **Window decorations:** `greybird-gtk-theme` added to theme packages; xfwm4 theme pinned to `Greybird` (Materia ships no xfwm4 style, so titlebars previously fell back to stock).
- **neofetch → fastfetch:** basic set installs `fastfetch` (falls back to `neofetch` on jammy); the login banner prefers fastfetch (`--logo none`) then neofetch. Fixes noble installs where neofetch no longer exists.
- **Wallpaper size:** shipped JPEG downscaled 3840x2160 → 1920x1080 (~6.4 MB → ~330 KB per release tarball/install).

### 🔒 Security
- **PulseAudio bridge is localhost-only:** `module-native-protocol-tcp` now binds `listen=127.0.0.1` instead of all interfaces (anonymous auth stays enabled for the container socket only). The appended block is also marked so re-runs no longer duplicate it.
- **VNC binds localhost by default:** TigerVNC starts with `-localhost yes`; set `UMO_VNC_PUBLIC=1` (host or in-container scripts honor it, including through proot via the start wrapper) to expose the server to LAN clients. Banner/docs wording updated accordingly.
- **Username validation:** `umo --user <name>` validates against `^[a-z_][a-z0-9_-]{0,31}$` before it is interpolated into any shell command run inside the container.
- **APT config typo fixed:** five `DPKg::`/mixed-case directives in `99-umo-sandbox` corrected to `DPkg::` — they were silently ignored by apt before.

### 🐛 Fixed
- **Dead 24.04 mirror URLs:** Ubuntu removed the `ubuntu-base-24.04.1-*` archives from cdimage (HTTP 404), so noble installs silently fell through to the unverified daily-current build; the mirror list now uses the currently published 24.04.4/24.04.3 release archives (checksummed).
- **README.txt alignment:** fixed misaligned `umo user` entry and missing commands in the generated in-container README.
- **Rootfs cache keyed by Ubuntu version:** the download cache ignored `--ubuntu=`, so a cached 22.04 archive could be extracted for a 24.04 install (and vice versa); cache filenames now include the version (`umo-rootfs-<version>-<arch>.tar.gz`).
- **`umo start` honors `UMO_VNC_PUBLIC`:** the session controller now forwards the flag into the container like `umo vnc` does.
- **Wallpaper monitor detection widened:** `umo-desktop-init` also enumerates connected monitors via `xrandr` (when present) in addition to xfconf discovery, covering TigerVNC builds that report non-`monitor0` names before any backdrop property exists.

## [v4.8.0] - 2026-08-16

### 🔧 Changed
- **Rename `bash.sh` → `umo.sh`:** the one-liner release installer is now fetched from `main/umo.sh`, giving the project a single recognizable entry-point name:
  ```
  curl -fsSL https://raw.githubusercontent.com/shadow-x78/ubuntu-modded-optimized/main/umo.sh | bash
  ```
  READMEs (EN/AR), `docs/INSTALL.md`, `docs/INSTALL_AR.md`, `SECURITY.md`, the tarball layout, `scripts/release.sh`, and both GitHub workflows updated accordingly.
- **SECURITY.md version badge** now synced to 4.7.0 (the badge was missed in the v4.7.0 docs pass).
- **Commit convention enforced retroactively:** the v4.7.0 feature commit was reworded to the documented `umo | v4.7.0 | feat: ...` style (it had shipped as `umo | feat: ...` without the version segment); the v4.7.0 tag/release was republished from the corrected history with identical contents.

### ⚠️ Migration
- Switch any saved one-liner to `main/umo.sh` (`get.sh` / `bash.sh` URLs served older releases only).
- Existing installs need no action: `umo update` downloads the new tarball wholesale, and the one-liner is only used for fresh installs.

## [v4.7.0] - 2026-08-16

### ✨ Added
- **`umo uninstall`:** full removal — Ubuntu rootfs, `~/.umo` host scripts/cache/logs, the `umo` command in `$PREFIX/usr/bin`, and the aliases block in `.bashrc`/`.zshrc`. Shows exactly what will be removed and asks for confirmation (`UMO_UNINSTALL_YES=1` skips the prompt). `umo-uninstall` is also listed in `umo --help`.
- **Host aliases file:** the installer writes `~/.umo/aliases.sh` (`umo-start`, `umo-stop`, `umo-startvnc`, `umo-stopvnc`, `umo-login`, `umo-user`) and sources it from `.bashrc`/`.zshrc`, so the shell exposes plain commands instead of loose files.
- **`umo run` / `umo backup` documented** in both READMEs' command tables.

### 🔧 Changed
- **Clean Termux home:** all host-side scripts (`umo-login.sh`, `umo-user.sh`, `umo-start.sh`, `umo-stop.sh`, `umo-vnc-start.sh`, `umo-vnc-stop.sh`, `aliases.sh`) now live in `~/.umo/` instead of `$HOME`. Legacy home copies are removed automatically on install and by `umo update`. The `umo` CLI, session controllers (`umo start/stop/vnc/login/user`) and all modules locate scripts in `~/.umo/` with a fallback to `$HOME` for pre-4.7 installs.
- **Rename `get.sh` → `bash.sh`:** the one-liner release installer is now fetched from `main/bash.sh` (`curl ... main/bash.sh | bash`); READMEs, INSTALL docs, SECURITY.md, CI, release workflow and the tarball contents all follow.
- **Finalizing phase can no longer hang:** every in-container finalize step (`apt-get install sudo`, `dpkg --configure -a`, `usermod`, service restore, VNC password) now runs with `DEBIAN_FRONTEND=noninteractive`, stdin from `/dev/null`, and a hard `timeout` (120–900s per step), so a stuck dpkg/proot session is killed instead of spinning forever.
- **Installer config is exported before modules load:** `--dir=`, `--de=`, `--apps=`, `--perf=`, `--theme=` now propagate reliably to every module (they were previously read by modules before CLI parsing could override them).
- **`umo-login.sh` audio socket detection** now also checks `$PREFIX/tmp/pulse-<uid>/native` (Termux's default socket location) in addition to `$PREFIX/root/...`.

### 🐛 Fixed
- **Finalizing spinner hang:** `Installing dependencies...` / `Configuring packages...` could spin forever waiting on interactive dpkg prompts inside proot; all such calls are now timed and non-interactive.
- **`umo user`/`umo vnc` resilience:** subcommands fall back to the legacy `$HOME` locations when `~/.umo` scripts are missing (pre-4.7 installs keep working until reinstalled).

## [v4.6.0] - 2026-08-16

### ✨ Added
- **Full Desktop Design System:** Every graphical desktop now gets a complete bespoke theme, built exclusively from packages available in the official Ubuntu repositories — Materia GTK theme, Papirus icons, DMZ cursors, Inter + JetBrains Mono fonts, and the UMO wallpaper.
- **Real Light Mode:** `--theme=umo-light` is now a genuine light theme (Materia-light + Papirus-Light) with per-DE panel and wallpaper colors; `umo-dark` remains the default.
- **LXDE Design:** Themed `lxpanel` bottom panel (menu, launchers, taskbar, tray, clock), `lxsession` desktop config, and `pcmanfm` wallpaper — applied to both root and the `umo` user.
- **Openbox Design:** `rc.xml` with Clearlooks windows and Inter titlebar fonts, a custom tint2 panel (launcher/taskbar/clock), a generated root menu, and `feh` wallpaper via autostart.
- **One-Liner Installer:** `curl -fsSL https://raw.githubusercontent.com/shadow-x78/ubuntu-modded-optimized/main/get.sh | sh` — downloads the latest GitHub release, verifies its SHA-256 checksum, installs to `~/.local/share/umo`, and launches the installer (interactive or `--no-gui`).
- **Release-Based Updates:** `umo update` now auto-detects the install mode — git-clone installs keep the existing fetch/reset flow, release installs download the newest tagged tarball with SHA-256 verification and swap the install atomically.
- `get.sh` is shipped inside every release tarball and passes all checks (shellcheck + `sh -n`) in CI.

### 🐛 Fixed
- **Broken GTK Theme:** configs referenced `Orchis-Dark` + `Bibata-Modern-Ice`, which were never installed (not available via apt) — everything silently fell back to GTK defaults. All configs now use apt-installable packages that are actually installed.
- **Theme Not Applied to Default User:** XFCE panel/window-manager/desktop configs were written only under root's home; they are now applied to both root and the `umo` user for every DE.
- **Dead Theme Mode:** `--theme=umo-light` previously applied the exact same files as `umo-dark` with no visual difference.
- **xstartup Fallback:** the VNC session fallback ended with `exec twm`, which is not installed anywhere — replaced with `exec xterm`.
- **Docs Inaccuracies:** install docs showed a wrong VNC password and missing `umo start` step; both READMEs' theme descriptions now match reality.
- **Installer Aborts Mid-VNC (`set -e` kills):** the installer exited entirely at the very start of the VNC phase. Root cause: `umo_log_debug` was written as `[ test ] && printf ...` and returned exit code 1 when `UMO_DEBUG` was unset, which under `set -e` terminated the whole installer. Rewritten as `if`/`return 0`.
- **Fatal `cmd; _rc=$?` pattern under `set -e`:** the desktop, apps, theme and download paths captured exit codes with an unguarded trailing `$?`; any non-zero return aborted the installer before the capture. All converted to `cmd || _rc=$?`.
- **`umo_run_quiet` destroyed the global cleanup trap:** it set and later cleared `trap - EXIT INT TERM`, silently disabling the installer's proot/apt/dpkg cleanup after the first spinner run. It now saves and restores the previous INT/TERM traps and never touches EXIT.
- **Hard `umo_die` in filesystem helpers:** `umo_fs_mkdir`, `umo_fs_write`, `umo_fs_render` and `umo_fs_patch` called `umo_die` (un-catchable `exit 1`) on any write failure; they now log a warning and return an error code, letting the install continue.
- **xstartup fallback rewritten:** the VNC session startup now falls back to a complete script (dbus-launch if available, then xfce4 → lxde → openbox → xterm → keep-alive shell) when `config/xstartup` is missing, and sets `XDG_RUNTIME_DIR`; `chmod +x` and user copies are guarded.
- **VNC phase made non-fatal:** `umo_vnc_install` no longer returns 1 when `umo-login.sh` is absent; every VNC step degrades to a warning (missing template, missing `/usr/local/bin`, `vncpasswd` unavailable) and the phase always completes, matching the other phases.
- **Proot prepare touched the HOST `/usr/sbin`:** the `invoke-rc.d`/`service`/`systemctl` divert loop used absolute `/usr/sbin` paths — a no-op on Termux but would corrupt a GNU/Linux host's service binaries if ever run as root; it now operates on `$UMO_PROOT_DIR/usr/sbin` and is fully guarded.
- **Exit-trap bug:** `_umo_sigint_cleanup` invoked the undefined `umo_cursor_show` inside `sh -c`; replaced with a raw cursor escape sequence.
- **Empty-arithmetic crash:** `umo_sys_disk_free_mb` now guards against non-numeric `df` output before arithmetic.
- **Guarded finalize:** `umo` CLI wrapper install, start/stop script copies, cache creation and all finalize sub-steps can no longer abort the installer when Termux's `usr/bin` or a target directory is unavailable.

### 🔧 Changed
- **Theme Engine Rewrite:** `modules/umo-theme.sh` rebuilt around a mode map (dark/light) with template rendering (`umo_fs_render`) instead of static config files; `config/theme/` reorganized into `gtk-2.0/`, `gtk-3.0/`, `xfce4/`, `lxde/`, `openbox/`, `fontconfig/`, `wallpaper/`.
- **Openbox Package Set:** added `exo-utils` (menu browser launch) alongside the existing set; XFCE keeps its dedicated install path.
- **Security Model:** release tarballs are now SHA-256 verified by both `get.sh` and `umo update`; SECURITY.md reflects checksum verification and points users to the one-liner.

## [v4.5.0] - 2026-08-16

### 🐛 Fixed
- **Stop Banner Colors:** `bin/umo-stop` used `$_UMO_BOLD` / `$_UMO_GRN` without defining them; both are now declared so the "Session Stopped" banner renders correctly.
- **VNC Install False Success:** `modules/umo-vnc.sh` captured the exit code of the dev-mode guard instead of the installer itself; `_rc` is now captured around the actual install run, so `UMO_DEV_MODE=1` can no longer report success for a skipped install.
- **Container README Text:** the generated in-container `README.txt` now states that `umo update` updates the UMO tool (it previously claimed it updates packages).

### 🗑️ Removed
- **Dead Code:** 25 unreferenced functions dropped from `lib/` and `modules/umo-proot.sh` (`umo_progress`, `umo_ui_password`, `umo_net_speedtest`, `umo_proot_cmd`, `umo_banner_compact`, ...), plus ~30 unused ANSI palette variables from `lib/core-ansi.sh`.
- **Unused Config Files:** `config/sources.list` and `config/bashrc.patch` deleted — no script consumed them; both contents are generated inline at install time.
- **Mid-code Comments:** stripped from every shell script and the CI workflow; the 3-line file headers (shebang / license / repo URL) are retained.

### 🔧 Changed
- **Docs Sync:** README / README_AR project-structure trees and SECURITY.md no longer reference the deleted config files; fixed tree-drawing indentation for `umo-systemctl.sh` in README.md.

## [v4.4.0] - 2026-08-16

### 🔧 Changed
- **Re-licensed to GPL-3.0-or-later:** The project license moves from MIT to GPL-3.0-or-later, aligning with the author's other projects (e.g. Orbiscreen). `LICENSE` now contains the standard GPL-3.0 text; all script headers use `(GPL-3.0-or-later)`; README/README_AR/docs/SECURITY badges and license sections now reference GPL-3.0; `CONTRIBUTING.md` and the PR template header checklist updated to the new convention. Previously published release assets (v4.3.0 and earlier) remain under MIT; all future releases are GPL-3.0-or-later.

## [v4.3.0] - 2026-08-10

### ✨ Added
- **Professional XFCE4 Theme Engine:** Complete desktop visual overhaul with Orchis-Dark GTK theme, Papirus-Dark icons, Bibata cursor, Inter/JetBrains Mono fonts, and a fully configured XFCE4 panel (Whiskermenu + tasklist + systray + clock).
- **Desktop Essentials Always Included:** `xfce4-terminal`, `thunar`, `xfce4-screenshooter`, `xfce4-taskmanager`, and `mousepad` are now installed with every XFCE4 deployment regardless of `--apps` selection.
- **Deterministic Panel Layout:** `xfce4-panel.xml` rewritten with proper plugin IDs (1-5), separator with expand=true, and application menu properties.

### 🐛 Fixed
- **Theme Package Source:** Replaced fragile GitHub Orchis theme download with Ubuntu `apt` packages (`papirus-icon-theme`, `fonts-inter`, `fonts-jetbrains-mono`).
- **XFCE4 Panel Missing Clock:** Fixed incomplete `plugin-ids` array that caused the clock plugin to never appear.
- **Wallpaper Never Applied:** `xfce4-desktop.xml` is now generated with the correct structure instead of relying on `sed` after first-run creation.
- **`UMO_THEME` Validation:** Invalid theme identifiers are now sanitized to `umo-dark` instead of silently failing; `--apps=full` no longer forces a non-existent theme.
- **Theme Defaults:** `UMO_THEME` now defaults to `umo-dark` (was empty), ensuring XFCE4 always gets the professional theme unless explicitly set to `none`.

### 🔧 Changed
- **Theme Command:** `umo_theme_apply_icons` and `umo_theme_apply_wallpaper` removed; replaced by `umo_theme_apply_desktop_config` which generates the full desktop XML directly.
- **CLI Documentation:** All docs updated to reflect XFCE4 professional theme defaults.

## [v4.2.0] - 2026-08-10

### 🐛 Fixed
- **Dynamic APT Sources for 24.04:** `umo-proot.sh` now generates `sources.list` with the correct codename (`noble` for 24.04, `jammy` otherwise) instead of hardcoding jammy and patching it later with `sed` in finalize. The finalize step uses the same dynamic generation, so both paths agree.
- **Broken `install-vnc.sh` Generation Risk:** The VNC module now builds the inner installer via block-grouped heredocs with a syntax self-check (`sh -n`) before execution, and refuses to run when `umo-login.sh` is missing or non-executable (was: silent failure leaving a corrupt script).
- **Half-Open dpkg Repair:** The 3-round `dpkg --configure -a` loops in the VNC and DE installers are replaced by a single shared `_um_apt_repair` body: configure once, remove broken packages only if any exist, then `apt-get -f install` and re-configure. Same behaviour, one round less, and identical logic in all installers.
- **VNC Binary Detection Drift:** `config/templates/umo-startvnc.sh` / `umo-stopvnc.sh` now detect `tigervncserver` first and fall back to `vncserver`, matching the runtime scripts in `modules/umo-vnc.sh` (was: templates assumed plain `vncserver`).
- **Hidden Password Input:** `umo_ui_password` now actually suppresses echo via `stty -echo` (with non-TTY fallback) instead of just printing "(input hidden)".
- **Flaky Internet Check:** `umo_sys_has_internet` probes DNS (`ports.ubuntu.com`) and the Ubuntu mirror over HTTPS instead of `http://google.com`, which fails on captive portals and DNS-filtered networks.
- **Update Throttle Precision:** `umo status` update fetch cache reduced from 1 hour to 10 minutes; the opt-in flag `UMO_CHECK_UPDATES=1` still applies.
- **Configurable VNC Password:** `UMO_VNC_PASSWORD` env var overrides the default VNC password during install (default unchanged).
- **Guarded divert-triggers:** `umo_proot_setup` runs the in-container divert script only after `umo-login.sh` exists and is executable (was: relied on `|| true` masking the failure).
- **Signal-Safe Password Prompt:** `umo_ui_password` restores terminal echo via a `trap` on INT/TERM so Ctrl+C can no longer leave the terminal in a no-echo state; empty/EOF input is handled explicitly.

### 🔧 Changed
- **Centralized Exports:** `UMO_INSTALL_DIR`, `UMO_UBUNTU_VERSION`, `UMO_DE`, `UMO_APP_SET`, `UMO_PERF_MODE`, `UMO_THEME`, `UMO_LEAN` are exported once in the installer top level instead of inside every phase function.
- **Terminal Width Cache:** `umo_term_cols()` caches `tput cols` once per process; `umo_rule`, `umo_banner*`, and `umo_badge` reuse it instead of spawning `tput` repeatedly.
- **Template Render Safety:** `umo_fs_render` warns on leftover `{{PLACEHOLDER}}` tokens so a missed substitution surfaces during install instead of producing a broken file.
- **Finalize Alias Cleanup:** The 6 separate `sed -i` calls on `.bashrc`/`.zshrc` collapse into one `sed -i -e ... -e ...` per file.

### 🧹 Removed
- **tests/ Directory:** Deleted (contained only an empty, ignored `run.sh`); references dropped from `.gitignore` and the release tarball exclusions.

## [v4.1.1] - 2026-08-09

### 🐛 Fixed
- **Template Drift in Update Refresh:** Unified `config/templates/umo-login.sh` and `config/templates/umo-user.sh` with the runtime heredocs from `modules/umo-proot.sh`. The refresh now uses the same flags (`--sysvipc`, `-b "$PREFIX/tmp:/dev/shm"`, `unset LD_PRELOAD/LD_LIBRARY_PATH`, correct pulse socket path) - previously `umo update` would silently downgrade the login wrapper.
- **User Detection in Update:** `_umo_refresh_host` now detects the current default user from the existing `umo-user.sh` (parses `/bin/su - <user>`) and preserves it through re-rendering, fixing a bug where custom-named users would be reset to `ubuntu` after update.
- **Status Fetch Stall:** `umo status` no longer fetches from origin on every invocation. The update check is now opt-in via `UMO_CHECK_UPDATES=1` and caches results for 1 hour via `.git/FETCH_HEAD` mtime.
- **CI Permissions:** Shellcheck exclusions are now scoped and documented in the workflow; the `$AUDIO_SOCK` unquoted expansion in templates remains intentional (needs splitting for proot args) and is excluded from lint.

## [v4.1.0] - 2026-08-09

### ✨ Added
- **Smart Update Flow (`umo update`):** Rewritten from a bare `git fetch + reset --hard` into a full pipeline: fetch, commit count diff (`HEAD..origin/main`), changelog preview in the terminal, automatic stash of any local modifications (restored after reset, kept as named stash on conflict), then host-side refresh + in-container hooks.
- **Update Awareness in `umo status`:** New `Updates` line fetches `origin/main` (best-effort, non-blocking) and reports `N new commits on main (umo update)` or `up to date`.
- **Host Script Refresh:** `_umo_refresh_host` re-renders `umo-login.sh`, `umo-user.sh`, `umo-vnc-start.sh`, `umo-vnc-stop.sh`, `umo-start.sh`, `umo-stop.sh` from the updated `config/templates/` placeholders (`{{INSTALL_DIR}}`, `{{TERMUX_PREFIX}}`, `{{DISPLAY}}`, `{{VNC_DEPTH}}`, `{{VNC_PORT}}`).
- **Container Hooks:** `_umo_refresh_container` drops dpkg lock cleanup and apt-speed reapplied inside the running proot (only when a session is active).

### 🔧 Changed
- **CLI Layout:** `umo help` and `umo status` now use a compact header (`UMO vX.Y.Z · section` inside a `─` rule) instead of the full ASCII banner; the banner only shows on `umo version` and `umo start`.
- **Status Format:** Migrated to a key-value grid (`Container`, `Session`, `VNC`, `Audio`, `Updates`) with consistent padding and lowercase status tokens (installed / running / active / stopped), matching the installer's `_umo_kv` helper.
- **Help Categorisation:** Commands regrouped as `Session Lifecycle` / `Terminal Access` / `Maintenance` / `General` with per-group subtitles, plus a `Common Tasks` block reflecting real workflows (backup before update, connect at :5901 after start, etc.).
- **Update Messaging:** Aligns with the rest of the tool: `[OK]`, `[..]`, `[ERR]`, `[!!]` badges and dim/cyan hints, replacing the previous glyph mix of `✔`, `✖`, `➜`, `!`.

## [v4.0.9] - 2026-08-09

### ✨ Added
- **CI Pipeline:** `.github/workflows/ci.yml` with three jobs - POSIX `shellcheck` over every script, `sh -n` syntax validation, and a hardcoded-secret scan that fails the build on any private key or credential pattern.
- **Release Workflow:** `.github/workflows/release.yml` triggers on `v*.*.*` tags, verifies the tag matches `UMO_VERSION` in `bin/umo-install`, runs syntax checks, and attaches a tarball + SHA256 checksum to the GitHub release.
- **Release Helper:** `scripts/release.sh` bumps the version across `bin/umo-install`, README badges (EN/AR), `SECURITY.md`, and the fallback versions in `lib/core-ansi.sh` / `modules/umo-vnc.sh`, inserts a new `CHANGELOG.md` block, commits, and tags in one step.
- **Community Health Files:** `CONTRIBUTING.md` (branch naming, `UMO | vX.Y.Z | type:` commit convention, POSIX sh style rules, PR and release process), GitHub issue forms (`bug.yml`, `feature.yml`), and a PR template with shellcheck/CHANGELOG checklists.

### 🔧 Changed
- **Repository URLs:** All links, clone commands, file headers, and shields badges migrated from `Shadow-x78/termux-ubuntu-umo` to `shadow-x78/ubuntu-modded-optimized` across 24 files; author name normalized to lowercase everywhere including `LICENSE` and the runtime banner (`lib/core-ansi.sh`).
- **Docs Linking:** `README_AR.md` docs table now points at the Arabic guides (`INSTALL_AR.md`, `TROUBLESHOOTING_AR.md`); English README keeps the English variants.
- **Punctuation Normalization:** Em dashes, Unicode arrows, and ellipses replaced with plain ASCII (`-`, `->`, `...`) across prose, comments, and user-facing strings; box-drawing and emoji glyphs guarded by the TUI remain untouched.
- **Dotfile Comments:** `.gitignore`, `.gitattributes`, and `.editorconfig` now use visual group separators; `.editorconfig` retains the `[*.{sh,yml,yaml}]` and `[*.md]` overrides.

### 🔒 Security
- Nothing user-facing changed; the new secret-scan CI job guards future commits.

## [v4.0.8] - 2026-07-04

### ⚡ Optimized
- **APT Single-Mirror Parallelism:** Removed `Acquire::Queue-Mode "host"` from `config/templates/apt-umo-speed.conf` and the fallback heredoc in `modules/umo-perf.sh`. Replaced with `Acquire::http::Pipeline-Depth "10"`, `Acquire::https::Pipeline-Depth "10"`, and `Acquire::http::No-Cache "true"`. The Ubuntu mirror is a single host (`ports.ubuntu.com`), so the previous `host` mode serialized every package download; the new pipeline mode opens up to 10 parallel HTTP requests on the same host, dramatically cutting wall time on slow connections.
- **Redundant `apt-get update` Eliminated:** Removed three of the four `apt-get update` calls per install. `modules/umo-perf.sh:73` is now the single canonical refresh before the install pipeline; the redundant updates inside `debloat.sh`, `cleanup.sh`, and `bin/umo-install:190` are gone. Only the post-`rm -rf` refresh inside `cleanup.sh` is retained so later phases (`umo_phase_desktop`, `umo_phase_apps`, `umo_phase_finalize`) still see a valid package index.
- **dpkg fsync Disabled Inside Proot:** `modules/umo-proot.sh:99-umo-sandbox` now sets `DPKg::NoTriggers "true"`, `DPKg::TriggersPending "false"`, and `Dpkg::Options:: "--force-unsafe-io"`. The proot also gets its own `/etc/dpkg/dpkg.cfg.d/force-unsafe-io`. The dominant remaining cost - dpkg's `fsync()` per-file writes during `apt-get install` on Android storage - is now removed.
- **Trigger Hooks Diverted at Proot Creation:** The `divert-triggers.sh` block (gtk-update-icon-cache, update-initramfs, systemd-hwdb, update-command-not-found, update-mime-database, update-desktop-database, plus man-db auto-update) now runs from `umo_proot_prepare` - once, before any `apt-get install` fires - rather than from `umo_perf_apt`. Duplicate execution path removed from `modules/umo-perf.sh`.
- **Theme Phase Speedup:** `modules/umo-theme.sh` now installs `fonts-inter fonts-jetbrains-mono fonts-dejavu-core gnome-icon-theme` instead of the old `papirus-icon-theme` + `fonts-noto` + `fonts-noto-core` + `xfonts-terminus` set. Total theme-package footprint drops from ~600 MB compressed to ~16 MB; visual identity is preserved because the GTK theme colors in `config/theme/gtk-3.0/settings.ini` and the font preferences in `01-umo-fonts.conf` override the underlying icon and font families.
- **VNC Install Fix (single transaction):** `modules/umo-vnc.sh` collapses five separate `apt-get install` calls (`apt-utils dialog tzdata`, `xfonts-base/encodings/utils`, `xfonts-75dpi/100dpi`, `dbus-x11`, `tigervnc-*`) into a single `apt-get install -y --no-install-recommends` invocation so the dependency resolver plans ahead and avoids the `xfonts-100dpi Depends: xfonts-utils but it is not going to be installed` cycle. Also drops the legacy `xfonts-75dpi`/`xfonts-100dpi` bitmap fonts that TigerVNC does not need.
- **XFCE4 Slim Install:** `modules/umo-desktop.sh:umo_de_xfce4` now installs `xfce4-panel xfce4-session xfce4-settings xfwm4 xfce4-terminal thunar dbus-x11 x11-xserver-utils gnome-icon-theme` in a single `--no-install-recommends` transaction. Replaces the old `xfce4` + `xfce4-goodies` meta-package (which pulled ~40 extra apps including orage, ristretto, xfburn, mousepad, parole) and the heavy `xubuntu-icon-theme`. `xfce4-whiskermenu-plugin` is now opt-in via `UMO_XFCE4_WHISKERMENU=1`. All four DE installers (`lxde`, `xfce4`, `openbox`, `minimal`) also gain the explicit `--no-install-recommends` flag for consistency.
- **Explicit fontconfig/x11 Bootstrap:** `modules/umo-vnc.sh` now lists `fontconfig fontconfig-config libfontconfig1 libfreetype6 libexpat1 libpng16-16 libbrotli1 fonts-dejavu-core x11-common xkb-data x11-xkb-utils xauth libbsd0 libxfont2 libfile-readbackwards-perl libfltk1.3 libfltk-images1.3` explicitly so apt's resolver cannot pick a half-installed rootfs state. `apt-get -f install -y` now runs **first** in both `install-vnc.sh` and the XFCE4 installer so any partial dpkg state from a previous failed run is repaired before the real install.
- **Half-Configured Package Auto-Removal:** Both `install-vnc.sh` and the XFCE4 installer now open with a 3-round pre-repair loop: `dpkg --configure -a`, then inspect `dpkg -l` for `iU`/`iF`/`hF` flags, then `dpkg --remove --force-depends` every broken package. After the loop, `apt-get -f install -y` and a final `dpkg --configure -a` leave the system clean. This breaks the `fontconfig depends on libfontconfig1 not installed` cycle that previously forced the user to run `apt --fix-broken install` manually.
- **tzdata Hang Fix:** Both `install-vnc.sh` and the XFCE4 installer now pre-seed tzdata's debconf (`tzdata/Areas=Etc`, `tzdata/Zones/Etc=UTC`) and redirect stdin away from the tty (`exec </dev/null` if interactive). This unblocks the `tzdata` postinst that was stalling on a debconf prompt even with `DEBIAN_FRONTEND=noninteractive`.
- **tzdata/Service Postinst Hang Killed:** `modules/umo-proot.sh:umo_proot_prepare` now moves `/usr/sbin/invoke-rc.d`, `/usr/sbin/service`, and `/usr/sbin/systemctl` to `*.real` backups and replaces them with `/bin/true` symlinks for the duration of the install. The `99-umo-sandbox` apt.conf adds `Dpkg::Post-Invoke {}` and `Dpkg::Pre-Invoke {}` so apt never runs service-start hooks. All four DE installers + VNC + theme wrap every `apt-get install` and `apt-get -f install` with a `timeout 600` guard. `umo_phase_finalize` restores the real binaries in a new `Restoring service binaries` step after every apt call has finished, so VNC start uses the genuine service files once the install completes.
- **Hardened Exit + Global dpkg Configuration Pass:** `bin/umo-install:umo_main` exit trap now wraps the pkill cleanup in a `timeout 5 sh -c '...'` so the script itself is bounded - even if a child wedges, the script returns within 5 seconds. The cleanup pkill list also covers `apt-get`, `dpkg`, and every heredoc installer script (`install-vnc.sh`, `install-de.sh`, `install-theme.sh`, `debloat.sh`, `cleanup.sh`, `perf-desktop.sh`, `divert-triggers.sh`). `bin/umo-install:umo_phase_finalize` adds a final `Configuring any remaining packages` pass that walks any package still in `iU`/`iF`/`hF` state to `ii` (or removes + re-installs via `apt-get -f install`), then a `Cleaning dpkg locks` step that removes any stale `dpkg` lock files. `modules/umo-proot.sh:umo_proot_prepare` pre-touches `var/lib/dpkg/lock` and `var/lib/dpkg/lock-frontend` so the first apt-get never sees a missing lock that could wedge the parent's `wait`.
- **Summary Phase README Hang Fixed:** `bin/umo-install:umo_phase_summary` README.txt write is now wrapped in `timeout 5 sh -c 'cat > ...' << README_EOF || true`. The previous `cat > file 2>/dev/null || true << README_EOF` parsing confused some shells (mksh/busybox on Termux) and could hang after printing "Get Started". The timeout caps any stall at 5 seconds.
- **Explicit X11/freetype/libbsd Bootstrap Expanded:** `modules/umo-vnc.sh` install list grew to include `ucf`, `x11-xkb-utils xauth`, `libx11-6 libx11-data libxau6 libxcb1 libxdmcp6`, `libbsd0 libmd0 libxfont2 libfontenc1 libxcursor1 libxext6 libxfixes3 libxft2 libxinerama1 libxrender1 libxi6 libxrandr2 libxt6 libxaw7 libxkbfile1 libxmuu1 libpixman-1-0 libjpeg8 libgl1` so apt resolves the full X11/freetype/libbsd dep chain in one transaction, including the libs that previously required a separate `apt --fix-broken install` pass.

### 🐛 Fixed
- **Installer Hang on Exit (SIGKILL trap):** `lib/core-ansi.sh:umo_run_quiet` now installs a per-call `trap _umo_spinner_cleanup EXIT INT TERM` that forcibly `kill -KILL`s the backgrounded spinner. The inline kill was also upgraded from SIGTERM to SIGKILL, ensuring the spinner is fully dead before the function returns. The trap is released on every return path so it never leaks into the caller. This eliminates the "script never exits, must press Ctrl+C" condition caused by half-dead spinner processes still holding the tty.
- **Orphaned `termux-wake-unlock`:** `bin/umo-install:432` - removed the trailing `&` from `termux-wake-unlock` so the call no longer leaves an orphan at the end of `umo_phase_summary`. Added `|| true` to keep `set -e` safe.
- **Final Exit Trap Cleanup:** `bin/umo-install:573` - `exit 0` is now preceded by `trap - EXIT INT TERM HUP` to drop any lingering trap before the script terminates.
- **Installer Hang on Ctrl+C:** `bin/umo-install:umo_main` now installs a top-level `trap _umo_sigint_cleanup EXIT INT TERM HUP`. On any exit (including Ctrl+C), every `proot` rooted at `$UMO_INSTALL_DIR` and every `umo-login.sh` helper still attached to the tty is `kill -KILL`'d, the cursor is restored, and the script exits with the saved exit code (130 for SIGINT). Replaces the older condition where partial-failure runs could leave orphaned proot children holding the terminal open until the user pressed Ctrl+C a second time.

### 🔄 Updated
- **Version Bump:** All version sources (`UMO_VERSION` in `bin/umo-install`, fallback defaults in `lib/core-ansi.sh` and `modules/umo-vnc.sh`, the embedded version inside the generated `umo` wrapper script, `config/bashrc.patch`, and every README/INSTALL/TROUBLESHOOTING/SECURITY badge) bumped from 4.0.7 -> 4.0.8.

## [v4.0.7] - 2026-06-25

### 🐛 Fixed
- **VNC Status Detection:** Updated `umo status` and session control scripts to correctly detect and kill `Xtigervnc` in addition to `Xvnc`, preventing false "Stopped" reports and fixing "already running" errors when restarting VNC.
- **VNC Password:** Changed the default VNC password from `umo` (which was silently rejected for being under 6 characters) to `ubuntu`. Updated all documentation and UI summaries to clarify the VNC password.
- **VNC Server Output:** Removed the background `&` execution from the VNC server startup command. The script now correctly checks the exit status of `vncserver` and prevents the success logo from displaying if the server fails to start.


### 👁️ Visibility & UX
- **Global Installation Transparency:** Removed the silent `umo_run_quiet` wrapper from all major installation phases, including Desktop Environment (XFCE4/Openbox), Applications, VNC Server, and Themes. Additionally removed `quiet "2"` from the global `apt.conf`. Because XFCE4 and its icon themes contain over 80,000 files, PRoot must intercept hundreds of thousands of system calls, which fundamentally takes several minutes on Android storage. Previously, hiding this process behind a silent "Loading" spinner caused psychological time dilation and made it appear as if the installer had frozen. Now, the native `apt` progress output is fully visible across all heavy operations so users can monitor the exact extraction progress in real-time.

### ⚡ Optimized
- **Spinner Fork Bomb:** Rewrote the `umo_spinner` to entirely eliminate subshell forking (`cut` and `printf`). The previous implementation spawned new processes 4 times per second to animate the spinner, which unintentionally created a "fork bomb" effect on Android Termux, aggressively starving the CPU and slowing down the entire `install.sh` pipeline (especially extraction and configuration). The spinner now uses pure POSIX shell parameter expansion, resulting in zero overhead.
- **Browser Installation Hangs:** Removed Snap-dependent browser packages (`firefox` and `chromium-browser`) from the default App Suite. In Ubuntu 24.04, these packages attempt to invoke `snapd` and `systemd`, which are fundamentally incompatible with Android PRoot. This caused the installer to silently hang for 10-20 minutes waiting for Snap socket timeouts. The installer now exclusively targets `firefox-esr` (a native `.deb` package) to ensure a lightning-fast browser installation phase.

## [v4.0.6] - 2026-06-25

### 🐛 Fixed
- **DPKG I/O Bypass:** Reverted `eatmydata` in favor of the native `force-unsafe-io` configuration. The previous `eatmydata` wrapper strategy failed because `apt-get` internally executes the absolute path `/usr/bin/dpkg`, bypassing the `/usr/local/bin` wrapper. This caused `dpkg` to silently fall back to slow, synchronous `fsync()` system calls, resulting in extreme slowness during XFCE4 and Theme extraction on Android flash storage. The native `force-unsafe-io` approach definitively eliminates `fsync` overhead at the package manager level.

### ⚡ Optimized
- **Massive I/O Speedup (eatmydata):** Integrated `eatmydata` natively into the installation pipeline. `apt-get` and `dpkg` are now globally wrapped with `libeatmydata`, safely bypassing synchronous `fsync()` syscalls without risking Android kernel dirty page freezes. This drastically accelerates the extraction of Desktop Environments and Themes.
- **Console I/O Bottleneck:** Added `quiet "2"` and `DPkg::Use-Pty "0"` to the PRoot `apt.conf` to completely suppress thousands of lines of progress bar updates from `apt` and `dpkg` that were creating severe `ptrace` context-switch bottlenecks via the stdout pipe during installation.

## [v4.0.4] - 2026-06-25

### ⚡ Optimized
- **Installation Speed:** Fixed extreme CPU starvation caused by `umo_spinner` creating too many `sleep` process forks per second on Android (`sleep 0.08` to `sleep 0.25`). This drastically improves the execution speed of heavy `apt-get` tasks during installation.

## [v4.0.3] - 2026-06-25

### 🐛 Fixed
- **DPKG Fatal Error:** Fixed `dpkg` aborting with `unknown system group 'messagebus'` during finalization. This was caused by an Ubuntu packaging bug leaving orphaned `dpkg-statoverride` entries after debloating `dbus`. The override is now forcefully cleaned.
- **Colors:** Fixed the missing orange theme color `_UMO_PRI` when running `umo stop`.

## [v4.0.3] - 2026-06-25

### 🐛 Fixed
- **VNC Server Crash:** Disabled the `GLX` extension natively via environment variables (`MESA_NO_SHM=1`, `GALLIUM_DRIVER=llvmpipe`, `LIBGL_ALWAYS_SOFTWARE=1`) to prevent Signal 6 crashes when parsing arguments in newer TigerVNC wrapper scripts.
- **Installer Exit Hang:** Prevented the `termux-wake-unlock` API call from hanging the finalization phase by running it fully in the background.
- **UI Consistency:** Wrapped remaining initialization and setup headers in `umo_run_quiet` to ensure uniform loading messages throughout the installation.

## [v4.0.1] - 2026-06-25

### 🐛 Fixed
- **Terminal Hang on Exit:** Prevented background daemons (like `gpg-agent`) from inheriting terminal file descriptors during installation by properly redirecting stdout, allowing the installer to exit cleanly without freezing Termux.
- **VNC Server Stability:** Fixed an issue where the VNC server would stop immediately by removing the unsupported `-deferUpdate` parameter from TigerVNC, disabling the GLX extension to prevent Signal 6 (Aborted) crashes, and replacing `wait` with a continuous polling loop for `Xvnc`.
- **CLI Output:** Fixed a bug in `umo update` where the success message was repeated twice and lacked the correct color formatting.

### 🗑️ Removed
- **Obsolete SSH Script:** Removed the obsolete `umo-start-ssh` helper script from the codebase as it is no longer used or necessary.

## [v4.0.0] - 2026-06-25

### ✨ Added
- **Version Command:** Added `umo version` command to display current installed version.
- **Improved Updater:** Improved `umo update` to forcefully reset local changes (`git reset --hard origin/main`), preventing abort errors during updates.
- **Refined CLI:** Logically categorized help menu commands and updated command descriptions.

### 🐛 Fixed
- **Legacy Alias Cleanup:** Cleaned only `alias umo=` from bash/zsh profiles to avoid unintended side effects while ensuring the CLI wrapper functions correctly.
- **DPKG Install Hang:** Removed aggressive `dpkg fsync` disables (`force-unsafe-io`) that were causing APT and DPKG to hang indefinitely during package installations (e.g., Theme packages) inside PRoot.
- **Background Processes Hang:** Added aggressive cleanup (`pkill -9`) for all UMO-related daemons (`dbus-daemon`, `pulseaudio`, `Xvnc`, `termux-x11`) at the end of the installer to ensure the installer exits gracefully without hanging the terminal.
- **VNC Password Error:** Added `tigervnc-tools` dependency to fix the `tigervncpasswd: command not found` error during `umo start`.
- **UMO Start Refactor:** Refactored the `umo start` command to strictly act as a service starter. It now elegantly displays the UMO logo, Session status, VNC details, and Audio status, then returns to the Termux prompt without forcefully dropping the user into the Ubuntu bash shell.

## [v3.3.9] - 2026-06-25

### ✨ Added
- **Start Command:** Reintroduced `umo start` to the CLI wrapper. It behaves similarly to the old default behavior, explicitly starting the Ubuntu session alongside VNC and Audio servers.
- **Login Separation:** Clarified that `umo login` and `umo user` perform a clean standard login without initiating background VNC or Audio servers.
- **Legacy Alias Cleanup:** Added an automatic cleanup routine during installation that safely removes legacy `umo` and `startubuntu` aliases from the user's `~/.bashrc` and `~/.zshrc`, ensuring the new CLI wrapper works perfectly without interference.

### 🐛 Fixed
- **Installer Hang:** Resolved an issue where the installer would hang at the "Installation Complete" screen because background daemons (like `dbus-daemon`) spawned during installation were keeping the terminal's file descriptors open.

## [v3.3.8] - 2026-06-25

### ✨ Added
- **Login Banner:** Injected the UMO ASCII logo and a separator line into `.bashrc`, displaying it right before `neofetch` upon login for a more branded and polished experience.
- **Self Update:** Redesigned the `umo update` command to act as a self-updater. It now executes `git pull` on the main repository directory, pulling the latest installer and module code directly from GitHub without needing to re-clone the repository.

### 💄 UI/UX
- **Professional Help Menus:** Completely redesigned the `--help` output for both the `umo` CLI wrapper and `umo-install` installer. The new output mimics global professional packages (like `docker` or `apt`), featuring bold headers, categorized options, colorized CLI flags, and clear contextual examples.

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
- **Version bump:** All files updated from 3.3.6 -> 3.3.7.

## [v3.3.6] - 2026-06-25

### 🐛 Fixed
- **`dpkg` Function not implemented / Permission denied (DEFINITIVE FIX):** The `dpkg` database fails when installing packages on Termux because `dpkg` attempts to use the `link()` syscall to back up `status` to `status-old`. Android 8+ blocks `link()` calls for untrusted apps, resulting in `Permission denied` or `ENOSYS`. **Solution:** Removed the faulty `$PREFIX/tmp/umo-dpkg` bind-mount and removed `PROOT_NO_SECCOMP=1` (which disabled syscall filtering and caused `Function not implemented` errors on `execveat`/`linkat`). Added `--link2symlink` to all `proot` login wrappers (`umo-login.sh`, `umo-user.sh`, `umo_proot_cmd`). This natively intercepts `link()` via seccomp and translates it to `symlink()`, completely bypassing the Android restriction and allowing `dpkg` and `dpkg-query` to operate seamlessly.

### 🎨 Changed
- **UI:** Changed `umo_log_step` labels to use imperative verbs (e.g., "Install XFCE4" instead of "Installing XFCE4") for cleaner and more consistent terminal output.
- **UI:** Removed trailing dots from all `umo_log_step` output labels to keep the interface clean and concise.
- **UI:** Removed "Checking internet connectivity" log step; the script now simply displays the final connection status directly.

### 🔄 Updated
- **Version bump:** All files updated from 3.3.5 -> 3.3.6.

## [v3.3.5] - 2026-06-23

### 🐛 Fixed
- **APT GPG / NO_PUBKEY (definitive fix):** Reverted `sources.list` to `[trusted=yes]` - `[signed-by=...]` fails on the minimal base rootfs where `ubuntu-archive-keyring.gpg` is absent. Combined with `apt-get update` filters (`grep -v "^Ign\|^W:\|^Err\|^Get:"`), the update output is now clean with zero GPG warnings.
- **`dpkg: status-old` Permission Denied:** Pre-created writable `/var/lib/dpkg/status`, `status-old`, and sub-dirs (`updates`, `info`, `parts`, `triggers`) with `chmod -R u+rw` in `umo_proot_prepare` - fixes the cascade that broke all apt operations.
- **Invalid `--no-lock` Option:** Removed `no-lock` from both `dpkg.cfg.d/umo-proot` and `Dpkg::Options:: "--no-lock"` from `apt.conf.d/99-umo-sandbox` - this is an apt flag, not a dpkg config option, and was corrupting every dpkg invocation.
- **VNC Silent Failure:** `umo_vnc_install` now uses `command -v` check with `exit 1` instead of silent `|| true` - install failures surface in the log instead of being hidden.
- **VNC dpkg Error 100 (definitive fix):** Added Phase 0 pre-repair (`dpkg --configure -a` + `apt-get -f install`) to fix half-configured rootfs state before any installs. Made `apt-utils` install visible (was silently swallowed by `2>/dev/null || true`, causing cascading debconf failures). Added Phase 4 recovery: on dpkg error 100, force-configure unpacked packages then retry the full install - the second pass finishes configuration that the first pass couldn't complete. Added `dpkg --audit` diagnostics on final failure.
- **`dpkg: status-old` / lock files:** Actually pre-created `status-old`, `lock`, `lock-frontend` in `umo_proot_prepare` (previous CHANGELOG entry claimed this but code only created `status`/`available`). dpkg needs `status-old` to rename the active status file during writes; its absence caused error 100 on the proot filesystem. Pre-created postinst-writable directories: `/var/lib/dbus`, `/var/cache/debconf`, `/var/lib/xfonts`, `/var/lib/update-alternatives`, etc.
- **VNC Install Staging:** Split the monolithic `apt-get install` into 6 staged groups (foundation -> fonts -> dbus -> tigervnc) with `dpkg --configure -a` between each, so a single package's postinst failure no longer aborts the entire 7-package transaction. Each package group uses `--no-install-recommends` to minimize maintainer scripts. Replaced harmful `tail` output truncation (was hiding the real dpkg error behind 26+ "Get:" lines) with a `_apt_filter` that strips download noise but keeps errors. Added `dpkg -l 'tigervnc*'` status dump on failure.
- **`dpkg: status-old` Permission Denied (ROOT CAUSE FIX):** Host-side `touch`/`chmod` in `umo_proot_prepare` was ineffective - proot's filesystem layer maps UIDs differently than the host. Created `umo_proot_fix_dpkg()` which runs `chmod`/`chown`/`cp` **from inside proot** (where dpkg actually operates), pre-populates `status-old` as a copy of `status`, and fixes lock file permissions. The fix runs once during `umo_proot_create_user` and is re-invoked between each VNC install stage via the reusable `/root/.umo/fix-dpkg.sh` script.
- **`dpkg status-old` rename() denied (DEFINITIVE FIX):** The rootfs is stored on a filesystem where the kernel denies the `rename()` syscall - `dpkg` does `rename(status -> status-old)` on every package install and this fails even though file *creation* works (`status-new` was successfully written). chmod/chown from both host-side and inside-proot proved ineffective because the denial is at the kernel/filesystem level, not Unix permissions. **Solution:** Relocate dpkg's database to `$PREFIX/tmp/umo-dpkg` (Termux internal storage = real ext4, fully supports `rename()`), bind-mounted onto `/var/lib/dpkg` inside proot via `-b $PREFIX/tmp/umo-dpkg:/var/lib/dpkg` in all three login wrappers (`umo-login.sh`, `umo-user.sh`, `umo_proot_cmd`). The database persists across sessions and all package installs (VNC, audio, desktop, apps) now operate on a filesystem that supports the operations dpkg requires.
- **`ls` ENOTDIR Spam:** Aliases now redirect stderr (`ls --color=auto 2>/dev/null`) to suppress proot `statx()` warnings on bind-mounted paths.
- **Archive Extraction:** `umo_net_extract` uses `proot --link2symlink tar` (sdcard forbids hardlinks) while `umo_net__validate_file` runs `gzip -t` to auto-detect and re-download corrupt caches.
- **Scrollback on Start:** `install.sh` and `umo_screen_clear` now emit `\033[3J` to purge the terminal scrollback buffer.

### 🔄 Changed
- **Version bump:** All files updated from 3.3.4 -> 3.3.5.
- **`config/sources.list`:** Reverted to `[trusted=yes]` (works on all rootfs variants).

## [v3.3.4] - 2026-06-23

### 🐛 Fixed
- **`ls` / `la` ENOTDIR Spam:** Removed per-file `/proc/*` binds (`-b fake_proc/stat:/proc/stat` etc.) from proot login wrappers - binding regular files onto an already-bound `/proc` directory triggers a proot `statx()` path bug that returns `ENOTDIR` for every top-level rootfs entry, producing `ls: cannot access 'bin': Not a directory` on every shell. Now relies on real Android `/proc` which is fully readable.
- **`.fake_proc` Visible at `/`:** Relocating fake proc files inside the rootfs made them appear as `/.fake_proc` in `ls -a /`. Removed fake_proc entirely; a migration cleanup (`rm -rf "$rootfs/.fake_proc"`) runs on first start of updated installs.
- **APT `NO_PUBKEY` + `Ign` Warnings:** Switched `sources.list` from `[trusted=yes]` (which still triggers GPG verification and emits `W: GPG error` + 4 `Ign` lines) to `[signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg]`. The keyring ships with every Ubuntu base rootfs, so `apt update` now verifies cleanly with no warnings. Falls back to `[trusted=yes]` on stripped rootfs images where the keyring is absent.
- **Swap Fully Removed:** Deleted `umo_perf_swap()` function and its call in `umo_perf_setup()` - swap is entirely non-functional inside proot and was producing confusing `swapon failed` output even after the previous "skip" stub.
- **Remaining `stty` Calls Removed:** Stripped the last `stty sane` + `trap` lines from `install.sh` and `bin/umo-install` - these were a leftover from the `stty -icanon` era and are no longer needed since the TUI uses plain `read`.

### 📝 Improved
- **Module Documentation:** Added summary headers to `umo-apps.sh`, `umo-desktop.sh`, `umo-vnc.sh`, and `umo-perf.sh` describing their purpose and public API functions.
- **Code Clarity:** Removed verbose inline comments from `umo-proot.sh` and other modules - each function now has a short explanatory header comment instead of multi-line rationales embedded in the logic.

### 🔄 Changed
- **`config/sources.list`:** Updated template to use `[signed-by=...]` with the official Ubuntu keyring path, matching what the installer writes into the container.

## [v3.3.3] - 2026-06-23

### ✨ Added
- **Unified ANSI Design:** All runtime outputs (VNC banner, session box, stop messages) now use the same ANSI style as the installer - no more ASCII `+---+` boxes.
- **`umo --help` Improvements:** Examples now use generic `<name>` instead of hardcoded usernames; section headers are color-coded.
- **Post-Install Summary:** Replaced old "Quick Commands" and "Inside Ubuntu" sections with a clean `umo` CLI reference table.

### 🐛 Fixed
- **`vncserver: not found`:** VNC scripts now check `tigervncserver` first, then fallback to `vncserver`, with a clear error if neither is found.
- **`pgrep: uptime`:** Removed `pgrep uptime` call from session start; uptime data now comes from fake `/proc/uptime`.
- **`swapon failed` Warning:** Swap is not available inside proot - removed the swap setup entirely to avoid the confusing warning.
- **Duplicate Log Messages:** Removed `umo_log_step` calls before `umo_run_quiet` in app/VNC installers - `umo_run_quiet` already shows the spinner label.
- **`stty` Terminal Corruption:** Removed all `stty -echo` / `stty -icanon` / `dd` raw mode from TUI engine; all input now uses simple `read`.
- **CRLF Line Endings:** Added `.gitattributes` to force LF; all `.sh` files verified clean.
- **`setsid` Breaking stdin:** Removed `setsid` from `install.sh` which was creating a session without a controlling terminal.
- **Auto-Exit After Install:** Added `stty sane` + `trap` at script entry to guarantee terminal restoration and clean exit.

### 🔄 Changed
- **Phase Headers:** Shortened from "Installing VNC Server" -> "VNC Server", "Configuring Audio Bridge" -> "Audio Bridge", etc.
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
- **User Creation - Entirely Rewritten:** Replaced all proot-based user creation (adduser, groupadd, chpasswd) with direct host-side file manipulation. The new approach writes to `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`, and `/etc/sudoers.d` directly from Termux, bypassing all PRoot `fcntl()` lock and ENOSYS syscall failures permanently.
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
- **Quiet Runner (`umo_run_quiet`):** `lib/core-ansi.sh` - wraps long-running commands with a Braille/ASCII spinner, captures output to a temp log, and on failure prints the last 30 lines. Replaces silent `2>/dev/null || true` swallowing across all modules.
- **Download Validation:** `lib/core-net.sh` - minimum file-size guard (`_UMO_NET_MIN_SIZE=1 MB`) and `umo_net__validate_file()` prevent corrupted or truncated rootfs archives from being accepted.
- **Timestamp Logging:** `lib/core-ansi.sh` - optional `UMO_LOG_TIME=1` prefix for every log line.
- **Warn Color:** `lib/core-ansi.sh` - dedicated `UMO_COLOR_WARN` (ANSI 220 / bold yellow) replaces the previous reuse of `UMO_B_YELLOW`.

### 🎨 Changed
- **Glyph Refresh:** `lib/core-ansi.sh` - step indicator changed to `▌`/`❯`, progress bar to `█/░`, spinner to Braille cycle `⠋⠙⠹...`, and added `UMO_G_RUN` glyph.
- **Menu Polish:** `lib/core-ui.sh` - `umo_ui_header` now draws an under-rule with `─`; menus show `[Space]=Toggle [Enter]=Confirm` hint.
- **Log Indentation:** All log helpers (`umo_log_ok`, `umo_log_err`, `umo_log_warn`, etc.) now use 2-space indentation for consistent hierarchy.
- **Extraction Hardening:** `lib/core-net.sh` - archive extraction no longer silently ignores `tar`/`unzip` errors; non-zero exit codes now `umo_die` with the actual status.
- **App/Desktop Installers:** `_run_installer` and `_run_de_installer` now pass human-readable labels into `umo_run_quiet` so every install phase is visible and traceable.

### 🐛 Fixed
- **Pkg Install Quiet:** `lib/core-system.sh` - `umo_sys_pkg_install` now wraps all package installs under a single `umo_run_quiet` spinner instead of printing raw `pkg`/`apt` stdout per package. Eliminates the #1 visual source of layout corruption.
- **Download Output Leak:** `lib/core-net.sh` - `umo_net_download` switched from `--show-progress` to `--quiet` (wget) and `-s` (curl). The old `--show-progress` + `--progress=bar:force:noscroll` printed raw terminal control sequences that destroyed the TUI layout. On failure, the last 30 lines are available via `umo_run_quiet`.
- **Archive Copy Robustness:** `lib/core-net.sh` - both cached-copy and post-download copy paths now guard `cp` failures with `{ ... } || { warn; rm; continue; }` instead of silently failing and leaving a missing file.
- **Box-Drawing Fallback:** `lib/core-ansi.sh` + `lib/core-ui.sh` - new `UMO_LINE_H` variable guarded by `UMO_GLYPH_SUPPORT`. Draws `─` in UTF-8 environments and `-` in ASCII/non-UTF-8 locales, replacing the hardcoded Unicode rule that rendered as ``.
- **Banner Line Bug:** `lib/core-ansi.sh` - corrected `_l7` line 7 of the UMO banner: format string `%b %*s %s %b` was consuming the color code as the width argument due to `%*s` eating two args. Now passes a valid color (`UMO_GRAD_1`) as the first `%b`.
- **System Check Spacing:** `bin/umo-install` + `lib/core-system.sh` - `umo_phase_check` now opens with `umo_ui_header "System Check"`, and `umo_sys_require_internet` uses `umo_log_info` instead of `umo_log_step`. Prevents the overlapping `▌ Checking... ✔` visual clash.
- **UTF-8 Detection:** `lib/core-ansi.sh` - glyph detection now falls back to `locale charmap` when `LANG`/`LC_ALL` variables do not contain "UTF-8". Respects `UMO_ASCII=1` for forced ASCII mode.
- **Readme Whitespace:** `README.md` & `README_AR.md` - fixed stray extra space in ASCII logo bottom line.

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
- **Same-File Copy Guard:** `lib/core-net.sh` - `cp` no longer fails with `are the same file` when cache path equals output path.

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
- **Banner Author:** Label changed from `shadow-x78` to `By shadow-x78`.
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
- **Tagline:** Reformatted to centered `Ubuntu Modded Optimized · v3.1.3` with `shadow-x78` below.

### 🔄 Updated
- **Validation Panel:** `umo_ui_panel()` auto-fits any terminal width (minimum clamped to fit).
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.3.

---

## [v3.1.2] - 2026-06-17

### 🔄 Updated
- **systemctl Emulator:** `umo-systemctl.sh` - now presented and documented as a
  generic service manager (`start|stop|restart|status|enable|disable <service>`)
  instead of SSH-centric; clearer usage and status output.
- **Docs:** README, INSTALL, TROUBLESHOOTING (EN+AR) examples use a generic
  `<service>` token; SSH shown only as an example. SSH start helper retained.
- **Version Bump:** All badges, fallback defaults, and `bin/umo-install` bumped to v3.1.2.

---

## [v3.1.1] - 2026-06-17

### 🚀 Added
- **ASCII Banner:** Restored large block-letter UMO logo (7-line) with orange gradient centering.
- **Panel Overflow Guard:** `umo_ui_panel()` now trims lines wider than the box and appends `...`.

### 🔄 Updated
- **Architecture Warning:** `core-system.sh` - clearer message for x86_64 users; indicates primary target is ARM64.
- **Summary Panel:** Compact key labels (`Platform`, `Arch`, `Path`) to prevent overflow.
- **Version Bump:** All badges, inline defaults, and `bin/umo-install` bumped to v3.1.1.

### 🐛 Fixed
- **Table Width:** `umo_ui_panel()` minimum raised to 52 and clamped to terminal width; eliminates off-screen boxes.

---

## [v3.1.0] - 2026-06-17

### 🚀 Added
- **256-Color Detection:** Auto-fallback between 256 / 16 / no-color modes via `tput colors`, `NO_COLOR`, `UMO_NO_256`.
- **Brand Palette:** Ubuntu orange identity - `UMO_COLOR_PRIMARY` = `38;5;208m`.

### 🔄 Updated
- **Logo Banner:** 6-line orange gradient (top light -> bottom dark), centered via terminal width.
- **TUI Panel:** `umo_ui_panel()` now auto-fits width to content instead of hardcoded 60.
- **Session Box:** `bin/umo-start` - fixed misaligned VNC line, dynamic box width, inline color fallback.
- **Summary Colors:** `bin/umo-install` - Quick Commands and Inside Ubuntu now use brand palette.
- **Changelog:** Formatted with emoji categories matching reference standard.
- **Version Bump:** `bin/umo-install` and fallback defaults updated to v3.1.0.

### 🗑️ Removed
- **Comments:** All inline code comments removed across `lib/core-ansi.sh`, `lib/core-ui.sh`, `bin/umo-start`, `bin/umo-install`.

---

## [v3.0.0] - 2026-06-16

### 🚀 Added
- **ASCII Banner:** Refined Block banner + compact variant for narrow terminals.
- **Ubuntu 24.04:** Noble Numbat support.
- **Performance Flags:** `--perf=balanced|aggressive|off` - APT speed, swap, debloat, DNS hardening.
- **Desktop Themes:** `--theme=umo-dark|umo-light|minimal|none` - Orchis-Dark, Papirus icons, fonts.
- **Lean Mode:** `--lean` - strip docs/man/locales to save space.
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
- **README:** Complete redesign - badges, centered header, anchored sections, language switcher.
- **README_AR:** Added `README_AR.md` - full Arabic translation.
- **SECURITY:** Complete redesign with risk table and response timeline.
- **INSTALL:** Redesigned with language switcher, expanded install modes.
- **INSTALL_AR:** Added `docs/INSTALL_AR.md` - full Arabic translation.
- **TROUBLESHOOTING:** Redesigned with language switcher, expanded fix sections.
- **TROUBLESHOOTING_AR:** Added `docs/TROUBLESHOOTING_AR.md`.
- **LICENSE:** Updated formatting to match project style.

### 🔄 Updated
- **Version Bump:** `bin/umo-install` updated from v2.0.0 -> v2.1.1.

---

## [v2.1.0] - 2024-06-16

### 🚀 Added
- **Open Source:** Re-licensed under MIT License - fully open source.
- **Community:** Open to contributions and community forks.

### 🔄 Updated
- **Branding:** Removed all proprietary/commercial branding.
- **Headers:** Clean open-source headers across all 13 source files.

---

## [v2.0.0] - 2024-06-16

### 🚀 Added
- **Core Engine:** `lib/core-ansi.sh` - ANSI color engine with 256-color support.
- **Core Engine:** `lib/core-ui.sh` - Interactive TUI: menus, checklists, prompts.
- **Core Engine:** `lib/core-system.sh` - Hardware detection, dependency management.
- **Core Engine:** `lib/core-net.sh` - Multi-mirror download with resume.
- **Core Engine:** `lib/core-fs.sh` - Safe file operations, atomic writes, backups.
- **Modules:** `umo-proot.sh` - Container preparation, login wrappers.
- **Modules:** `umo-vnc.sh` - TigerVNC installation, session control.
- **Modules:** `umo-audio.sh` - PulseAudio bridge configuration.
- **Modules:** `umo-systemctl.sh` - systemd emulator.
- **Modules:** `umo-desktop.sh` - DE installer (LXDE / XFCE4 / Openbox).
- **Modules:** `umo-apps.sh` - Application suite installer.
- **CLI:** `--no-gui` non-interactive mode.
- **CLI:** `--de=` / `--apps=` / `--dir=` flags.
- **UX:** Progress bars with percentage and spinners for background tasks.
- **Validation:** Configuration validation and health check system.
- **Logging:** Structured logging to `~/.umo/logs/`.

### 🔄 Updated
- **Architecture:** Complete rewrite with modular library system.
- **Compatibility:** Full POSIX sh compliance across all scripts.
- **Dependencies:** Zero external UI dependencies - no `dialog` / `whiptail`.

### 🐛 Fixed
- **VNC:** Screen lock kills VNC -> `termux-wake-lock` integrated.
- **Audio:** No audio in proot -> PulseAudio TCP bridge.
- **systemctl:** `systemctl` fails -> Shell-compatible emulator.
- **TUI:** `dialog` broken -> Pure POSIX TUI replacement.

---

## [v1.0.0] - 2024-01-15

### 🎉 Initial Release
- **Launch:** Initial release of UMO - Ubuntu Modded Optimized for Termux.
- **Support:**
  - Ubuntu 22.04 via proot-distro
  - VNC setup with TigerVNC
  - PulseAudio audio fix scripts
  - Manual proot configuration
