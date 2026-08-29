# Changelog

All notable changes to this project will be documented in this file.

## [v4.18.5] - 2026-08-30

### 🐛 Fixed

- **`umo start` reported VNC failure while the server was still starting - the wait loop was racing a capability probe:** the container-side start script probes `Xtigervnc -help` twice before launching the server (FrameRate/ImprovedHextile tuning), and the host-side wait loop in `umo start` checked for the server with a bare `pgrep -f Xtigervnc` - which matches the transient `-help` process. The loop broke out after ~2 seconds on that false positive, found no real server yet, and printed the failure screen (the "(no X server appeared in 2s)" signature) while the starter was alive and the real server still booting. Both the wait loop and the final verdict in `umo start`, and the `umo status` VNC probe, now match the server specifically (`Xtigervnc :<display>` / `Xvnc :<display>` patterns) - the `-help` probe can never satisfy them. This is the actual root cause of the recurring "VNC Failed To Start" screen on phones where startup takes longer than the broken loop's effective 2-second window.

- **The mark is the beloved original again:** v4.18.4's solid-block redrawing of the mark read as a smudged ring - the analytic resample lost the circle's outline vocabulary. The banner's mark is restored to the original v4.17.3 half-block art verbatim (the 22-column ring of friends that shipped through four releases), paired with the classic `UMO` wordmark dead-center (3 blank rows above, 3 below) and the spaced vertical rule - 55 columns, 12 rows, every line exactly 55 chars, verified programmatically in all six banner sites in both modes. The v4.18.4 container-banner refresh machinery (idempotent strip-and-redeploy on `umo update`) keeps deploying this art; existing installs pick it up on the next `umo update`.

## [v4.18.4] - 2026-08-29

### 🎨 Changed

- **The mark is drawn in the wordmark's own vocabulary - solid blocks, not scattered half-blocks:** the v4.18.3 mark was rendered with `▀`/`▄` half-blocks, giving it a fuzzier, lower-contrast look next to the crisp solid `██╗ ██║` letters. The mark is now drawn from the same SVG geometry (ring + three heads + chevron) but rendered as **solid `█` cells on the same 24x12 cell grid as the letters** - one cell, one block, the exact binary crispness of the classic wordmark - so the mark and the letters finally read as one family. The ASCII fallback uses the same geometry with `#` cells. All six banner sites rebuilt together in both modes (57 columns, 12 rows, every line exactly 57 chars - verified programmatically).

### 🗑️ Removed

- **Legacy container-banner blocker:** the in-container bashrc banner used to be written only once - at container creation - and never refreshed, leaving every existing install showing the old art forever (the "old logo in my terminal" report). `umo update` now strips the legacy banner block from both `/root/.bashrc` and `/home/umo/.bashrc` (an awk state machine that removes the `if [ -n "$PS1" ]` banner block through its fastfetch/neofetch tail) and deploys the current banner under a `# ===== UMO TERM BANNER =====` marker that makes the refresh idempotent; the deploy-and-strip cycle was verified against a real old-style bashrc: the old art disappears, the new banner renders in both UTF-8 and ASCII modes, and a second run changes nothing.

## [v4.18.3] - 2026-08-29

### 🐛 Fixed

- **The banner is truly centered now - and the wordmark, rule and mark all share the exact same height:** with 6 rows of letters inside an 11-row banner the letters sat 2-above/3-below optical center and the vertical rule ran taller than the wordmark block, visibly off-center next to the mark. The banner is now 12 rows (57 columns, every line exactly 57 chars): the mark is regenerated as a uniform 24x24-pixel circle (the v4.17.2-style analytic scale - 3x3 subsamples per output pixel from the 22x22 bitmap, so the ring stays round), packed into 12 half-block rows, and the classic `UMO` letters now have exactly 3 blank rows above and 3 below - dead-center vertically - with the spaced rule `mark │ UMO` spanning the same 12 rows as the mark. All six banner sites rebuilt together in both modes (half-block UTF-8 and `#` ASCII).

- **`umo start`'s VNC failure hint pointed at a command that no longer exists:** since v4.18.0 `umo login` is interactive-only and commands go through `umo run`, but the VNC failure screen still said `umo login -c "apt install -y tigervnc-standalone-server"` - a hint that now exits with a usage error instead of installing anything. It says `umo run "apt install -y tigervnc-standalone-server"`. Six more stale `umo login -c` hints across the CLI, the apps/desktop modules and the in-container extras installer all move to `umo run` the same way (a repo-wide grep finds zero `umo login -c` left outside the historical changelog). The failure diagnostics also got sharper: the one-line-log case (starter printed only the step line, then died - the phantom-killer signature) is detected explicitly and named, and the log tail shown grows from 8 to 15 lines.

## [v4.18.2] - 2026-08-29

### 🎨 Changed

- **The banner wordmark is the classic block-font `UMO` letters:** the v4.18.1 wordmark was drawn as solid half-block shapes spanning all 11 rows - a different, stenciled look that was never what the project wore; the wordmark beside the mark is now the exact classic `██╗ ██║` art from the pre-logo era (restored verbatim from v4.16.13), vertically centered on its six rows within the 11-row banner, split from the 22-column circle-of-friends mark by the spaced vertical rule (`mark │ UMO`) - 55 columns, 11 lines, every line exactly 55 chars. The ASCII fallback renders the same layout with a `#`-outline `UMO` on the same centered rows. All six banner sites (the lib banner, both `umo start` paths, `umo stop`, the CLI header, the in-container bashrc) rebuilt together in both modes.

## [v4.18.1] - 2026-08-29

### 🎨 Changed

- **The banner is `mark │ UMO` with all three elements the same height and on the same rows:** the v4.18.0 layout paired the mark with a scattered block-glyph wordmark; the banner is now the 22-column circle-of-friends mark, a space, the vertical rule, a space, and a 30-column `UMO` wordmark - 55 columns, 11 lines, every line exactly 55 chars, and the mark, rule and wordmark all span the full 11 rows together. The wordmark is drawn analytically (a 30x22 pixel grid packed into 11 half-block rows - no more 6-row letters floating mid-height); the ASCII fallback is the same layout with `#` outlines and a plain `|` rule. All six banner sites (the lib banner, both `umo start` paths, `umo stop`, the CLI header, the in-container bashrc) rebuilt together in both modes.

### 🗑️ Removed

- **The marketing-style logo sections from the documentation:** the "The UMO Mark" section and its surface table (repository header / terminal banners / desktop menu button) are gone from both READMEs along with their ToC entries, the "Brand Assets" section is gone from CONTRIBUTING.md (the PR template's functional banner-check checklist line stays), and `umo credit` drops its trailing design-story line - the docs now say what the tool does, not where its logo lives.

- **One unused function:** `umo_log_run` in `lib/core-ansi.sh` - defined, never called anywhere; dropped in the dead-code reference pass. Zero other unused functions, variables or files found.

### 🐛 Fixed

- **The last mid-code comment:** `bin/umo-cli`'s login guard carried a stray comment - the only comment left inside any code file after the v4.16.13 strip; removed. Config files (`.conf`, `.ini`, XML, JSONC, `.tmpl`) keep their box-style comments untouched.

## [v4.18.0] - 2026-08-29

### ✨ Added
- **`umo credit` - the project and developer introduction:** a new command (`credit`, aliases `credits`/`about`) that prints the version banner followed by the project line (what UMO is, in one sentence), the developer block (shadow-x78 - design, engineering, everything - with GitHub and repo links), the built-with stack, the license, and the mark's design story (the circle of friends, whole - every broken arc repaired - with the installer chevron at its center). Listed in `umo help` under General and in both README command tables.
- **The banner is now the logo mark beside the UMO wordmark - `mark │ UMO`:** every banner site previously showed the logo alone; the layout is now the 22-column circle-of-friends mark on the left, a vertical rule, and a 15-column five-row `UMO` wordmark vertically centered beside it (40 columns total, 11 lines, every line exactly 40 chars so the whole banner centers as one block at any terminal width - the pipe column verified aligned under a PTY). The ASCII fallback renders the same layout with `#` blocks and a plain `|` rule. The lib banner carries it; the standalone sites keep their compact mark.

### 🔒 Changed
- **`umo login` is an interactive root shell only - commands move to `umo run`:** login used to pass any arguments through to bash (`umo login -c "apt upgrade"` worked), blurring the line between "open a shell" and "run a command". Login now takes no arguments: calling it with any argument exits with a usage error that points at the intended path (`umo run "<command>"`). `umo run` remains the one-command path (it already runs via the wrapper's `-c`). Both READMEs and both INSTALL guides document the split.

### 🗑️ Removed (documentation)
- **The docs lost their dead weight - everything that duplicated, padded or said nothing is gone:** SECURITY.md drops the empty Hall of Fame ("None yet - be the first!"), the academic Security Audit section (a restatement of the scope paragraph as bullet lists) and the separate Disclosure Policy section (5-step list + timeline tables duplicating the reporting section) - reporting, timeline and disclosure merge into one tight section, and the recommendations collapse from five numbered items to a single paragraph. The supported-versions table now reads 4.18.x. CONTRIBUTING.md merges the three generic sections (Branch Naming, Commit Convention, Code Style, Pull Requests - four headings of universally-known conventions) into one "Day-to-Day Work" block, keeping the release process and Brand Assets sections that are actually UMO-specific. Both INSTALL guides drop their full command tables (which had become a stale copy of the README's) in favor of a five-line essentials block plus a link to the README's authoritative table. Every remaining section earns its place; all anchors re-verified programmatically after the trim (zero broken ToC links across all seven documents).

## [v4.17.3] - 2026-08-29

### 🎨 Changed
- **The terminal banner is compact again - same mark, 27% smaller:** the v4.17.2 redraw filled the full 30-column grid, and at 15 lines the banner dominated `umo start/stop` output on a phone. The art is regenerated at 22 columns / 11 lines from the same analytic geometry (same ring, heads and chevron constants, same measured circle - the taper sequence 8-4-3-2-1-1-1-1-1-4-8 verifies under a PTY), giving back 27% of width and height while every element still reads clearly. All six banner sites (the lib banner, both `umo start` paths, `umo stop`, the CLI header and the in-container bashrc) were rebuilt to the compact set in both modes - half-block UTF-8 and the pure-ASCII `#` fallback - and verified live in each mode.
- **Every documentation file now reflects the current project - versions, commands and the new brand reality:** the docs lagged the code by several releases. All five stale version badges (docs/INSTALL, docs/INSTALL_AR, docs/TROUBLESHOOTING, docs/TROUBLESHOOTING_AR, SECURITY - all frozen at 4.16.13) rotate with the release from now on, and CONTRIBUTING's release process is rewritten to list the real five version homes (installer source of truth, banner fallback, both README badges and the five doc badges - `modules/umo-vnc.sh` never held one) plus the tag message convention and the minor/patch bump rule by CHANGELOG type. Both READMEs gain a **The UMO Mark** section with its own ToC anchor documenting the logo's design story (the whole ring of friends + the installer chevron) and its three surfaces - README headers, every terminal banner with the ASCII fallback, and the XFCE menu button - and the project-structure trees now include `assets/` and `config/theme/icons/`. INSTALL.md/INSTALL_AR.md gain the missing commands (`umo run`, `umo backup`, `umo uninstall`, `--x11`), the missing app groups (`office`, `browser`), the full media set, the `umo uninstall` clean path and the UMO-mark note on `--theme`; SECURITY.md's supported-versions table moves from the ancient `2.1.x` to the current `4.17.x` with a `umo version` check hint. TROUBLESHOOTING (both languages) gains two new sections - **Terminal Banner Shows # Art** (locale/UTF-8 guidance and `UMO_ASCII=1`) and **Menu Button Shows the Wrong Icon** (brand re-deploy via `umo update`, enforced at session start) - and the plank section notes the honest log line shipped in v4.17.0. The PR template now has a brand-assets checklist line (five version homes agree, both modes verified, uniform art-line width) so visual PRs stop shearing the circle.

## [v4.17.2] - 2026-08-29

### 🐛 Fixed
- **The terminal logo art is properly sized at last - full width, exact aspect, real edges:** three concrete defects made the v4.17.1 art look off. First, the mark only spanned 23 of 30 columns (77% width) because the ring geometry left a 46-unit margin on each side of the viewBox - the new geometry fills the grid completely (head outer edge at the canvas edge, ring band 176..232 of 0..512), so the mark now occupies 27.2 of 30 columns and 27.2 display-widths of height: a measured, aspect-exact circle on any 1:2-character terminal. Second, the ASCII fallback was squashed +25% wide - its cells were 17 units across but 42 units tall (2.5:1), so the circle rendered as a wide oval; the ASCII grid is now 30x15 with 2:1 cells, the same measured-round proportions as the UTF-8 half-block grid. Third, the installer's lib banner destroyed the circle's taper: every art line was lstrip-ed and then given one identical pad, which shifted each line's content to the same starting column and turned the left rim into a straight edge; the lines now carry uniform 30-char widths with their leading spaces intact, and the banner pads the whole block once - verified visually under a PTY, the left-edge sequence reads 12-8-5-4-3-2-1-1-1-2-2-2-5-8-13, a true circle taper. The chevron also grows to fill the void properly (reach 158 vs a 176-unit void at stroke 56, still optically centered on 256) and the head/ring/void relationships keep their SVG values (heads merge into the ring by 24 units vs the SVG's 23). Both renderings regenerated from the same tuned geometry and swapped into all six banner sites (lib, both `umo start` paths, `umo stop`, the CLI header, the in-container bashrc) - the inline sites grew from 12 to 15 lines for the fuller mark - and every path was re-verified live in both UTF-8 and ASCII modes: 15 lines, measured round, block-centered, zero leftovers of the old art.

## [v4.17.1] - 2026-08-29

### 🐛 Fixed
- **The redundant "Installing Base utilities..." line under every install step heading is gone:** the apps, desktop and VNC installers all printed a chevron run-line (`❯ Installing Base utilities...`) that said the same thing as the step heading right above it (`▌ Install Base Utilities`) and then streamed the container's own sub-steps below (`❯ Installing Core Utilities...`, `❯ Preparing XFCE4 Package Database...`) - one duplicated line of noise per installer with zero information. The line is removed from all three flow owners: the apps set installer (`modules/umo-apps.sh`), the DE installer (`modules/umo-desktop.sh`) and TigerVNC (`modules/umo-vnc.sh`); the heading is now immediately followed by the container's real sub-steps, exactly like the fastfetch/browser steps that never had a filler line.

### 🎨 Changed
- **The terminal logo art is redrawn at real resolution - the same mark, properly rasterized:** the v4.17.0 half-block art was sampled from a small render and read muddy at 30 columns - the ring wobbled, the three heads blurred into the rim and the chevron was a two-cell smear. The art is now generated analytically (exact per-cell coverage of the ring, the three head circles and the chevron segments, 4x4 subsamples per cell) with stroke weights tuned for the 30-column block grid: ring 56 units, heads 52, chevron 44 - proportions that keep the SVG's exact relationships (heads merge into the ring by 24 units vs the SVG's 23; chevron reach 127 vs a 142-unit void) while making every element read clearly. The result is a bolder, rounder mark (26x24 cells vs the old 22x22, 12 lines): crisp rim, three visible heads, a chevron with an actual point. Both renderings (half-block UTF-8 and the pure-ASCII `#` fallback) were regenerated from the same tuned geometry and swapped into all six banner sites (the lib banner, both `umo start` paths, `umo stop`, the CLI header and the in-container bashrc), and every path was re-verified live in both modes.
- **The desktop menu button now wears the UMO logo - the Ubuntu mark is fully retired:** the whiskermenu button icon (the panel's leftmost button) pointed at the Ubuntu circle-of-friends raster (`/usr/share/umo/brand/ubuntu.png`) since v4.16.4. The brand asset set in `config/theme/icons/` is replaced wholesale - `umo.svg` + `umo-{48,64,96,128,256}.png`, the UMO mark rendered from the project logo geometry - and every consumer now installs and points at the UMO names: the theme module's hicolor/brand deployment and its `defaults.rc` write, the `umo update`/`refresh` deployment in the CLI, the VNC session-start icon enforcement (`config/container/umo-startvnc`), the session-boot desktop init and the shipped `xfce4-panel.xml` template all use `umo.svg`/`umo.png`/`/usr/share/umo/brand/umo.png`, with the log lines renamed to match (`UMO Brand Icon Installed/Deployed`). No Ubuntu-branded asset remains anywhere in the tree.

## [v4.17.0] - 2026-08-29

### ✨ Added
- **The project has its own logo:** `assets/logo/umo-logo.svg` - a flat, single-color mark in the exact visual language of the shipped `ubuntu.svg` brand icon (#e9500e, the same Ubuntu orange). The design: the Ubuntu circle-of-friends ring, but **whole** - the stock mark is three broken arcs, and this one is a complete circle with the three heads (270/30/150 degrees, the Ubuntu arrangement), because "every broken arc repaired" is the project's own story; and at the center, in the void, the installer chevron `❯` - the glyph every UMO install step prints - as the hero. The logo ships as a full set (SVG + PNG at 512/256/128/96/64/48 plus a white-background preview) in `assets/logo/`, and both READMEs (EN/AR) now open with the mark at 180px **replacing the old ASCII banner entirely** - the logo is the banner now. The SVG uses two role classes (`.umo-f` fill, `.umo-s` stroke) sharing one color to retheme, and the geometry is verified (46px clear margin, the chevron fits the center void at 126px reach vs 149px void radius, 0.00px chord spread on the head triangle, the chevron bbox optically centered on 256).
- **The logo is now also the terminal banner - everywhere the old `UMO` wordmark blocks used to print:** the same logo geometry is rasterized to half-block terminal art (`▄█▀` cells, 30x30 logic grid packed into 12 physical lines) and replaces the ASCII `UMO` letter-banner in all six places it lived - the installer's central `umo_banner_full` in `lib/core-ansi.sh` (which `bin/umo-install`, `lib/core-ui.sh` menus and headers all render), the `umo start` banner on both the VNC and Termux:X11 paths, `umo stop`, the `umo --version`/CLI header, and the in-container root bashrc login banner from `modules/umo-proot.sh`. The art is generated from the real `assets/logo/umo-logo.svg` geometry (same ring/head/chevron constants), not hand-drawn, so terminal and brand stay identical by construction; and every site keeps the project's glyph-fallback discipline - half-block art on UTF-8 terminals, a pure-ASCII `#` rendering of the same shape on non-UTF-8 terminals (driven by each script's existing UTF-8 detection, plus `UMO_ASCII=1` to force it). Verified live under a PTY in both modes for every path: the lib banner, the CLI header, both `umo start` blocks and the bashrc block each render the ring, the three heads and the center chevron in UTF-8, and the clean `#` shape with zero box-drawing leftovers in ASCII.

### 🐛 Fixed
- **The "Plank Dock Theme Installed (Rounded)" line claimed rounding that can never appear - the claim is now honest:** plank's own renderer hard-codes every corner radius to 0 whenever no compositor is running (`draw_rounded_rect` in plank's `lib/Drawing/Theme.vala` does `if (!Gdk.Screen.get_default().is_composited()) top_radius = bottom_radius = 0.0;`), and since v4.16.13 UMO deliberately runs the xfwm4 compositor off in every session (fresh installs via the `use_compositing=false` xfwm4 template, existing containers via the refresh that flips the channel and the perf module's `xfconf-query -s false`) because compositing every frame is the heaviest per-frame cost on a phone CPU under VNC. The theme file itself was fine - it loads, and its colors, paddings and indicator style apply - but `TopRoundness=18` is architecturally dead in a compositor-less session, so the dock rendered square while the log said "(Rounded)". The success line now says plain `Plank Dock Theme Installed`, and the `dock.theme` header documents the truth: the 18 is kept so a compositor-enabled session gets the rounding for free, while UMO sessions are square-edged by design. No behavior changed - the theme installs exactly as before, the message simply stops advertising what the renderer will not draw.

## [v4.16.13] - 2026-08-28

### 🐛 Fixed
- **The default web browser no longer dies with "Failed to execute default Web Browser. Input/output error." - Falkon is now really the default browser:** since v4.16.6 the Falkon *desktop entry* is hardened to the proot-safe wrapper (`/usr/local/bin/umo-browser` with `QTWEBENGINE_DISABLE_SANDBOX` and the `--no-sandbox`/`--disable-gpu`/`--disable-dev-shm-usage` Chromium switches), but every other launch path bypassed it: XFCE's "Web Browser" menu entry (`xfce4-web-browser.desktop`, `Exec=exo-open --launch WebBrowser %u`) and every URL hand-off from inside the desktop funnel into `xfce4-mime-helper --launch WebBrowser`, which resolves the preferred helper from `~/.config/xfce4/helpers.rc` - and UMO never wrote one, so the system default `/etc/xdg/xfce4/helpers.rc` answered `WebBrowser=debian-sensible-browser`, i.e. it spawned `sensible-browser` → the `x-www-browser` alternative → bare `/usr/bin/falkon` with no sandbox switches. QtWebEngine's Chromium zygote refuses that instantly (as the session root: "Running as root without --no-sandbox is not supported"; as a regular user under proot: the bubblewrap sandbox needs user namespaces proot cannot provide), and the "Input/output error" text is not a kernel fault at all - `xfce_mime_helper_execute()` spawns the command, then polls `waitpid(WNOHANG)` for up to five seconds and, when the command exits non-zero inside that window, reports a synthesized `G_FILE_ERROR_IO` (the exact dialog reproduced live in a container: spawn `sensible-browser` as root, Falkon dies on the sandbox check within a second, the EIO dialog appears). The wiring now happens in both the generated in-container app installer and host-side during `umo update`/`umo refresh`: a `/usr/share/xfce4/helpers/umo-falkon.desktop` X-XFCE-Helper definition whose binary is the wrapper itself (`X-XFCE-Binaries=/usr/local/bin/umo-browser`), a merge-safe `WebBrowser=umo-falkon` entry in `helpers.rc` for both `root` and `umo` (an existing `WebBrowser=` line is replaced, every other key survives), a section-aware awk merge of `x-scheme-handler/http`, `x-scheme-handler/https` and `text/html` → `org.kde.falkon.desktop` into each user's `~/.config/mimeapps.list` `[Default Applications]` (existing handlers replaced in place, unrelated entries and the `[Added Associations]` section kept byte-for-byte), and the wrapper registered as the `x-www-browser` alternative at priority 200 so even direct `sensible-browser` callers take the hardened path. Verified end-to-end in live containers: before the wiring, `xfce4-mime-helper --launch WebBrowser https://…` exits 1 with the EIO dialog and no browser window; after the wiring, the same command exits 0 and Falkon renders through the wrapper (`Sandboxing disabled by user` in `/tmp/umo-browser.log`), `exo-open --launch WebBrowser`, `exo-open <url>` and `xdg-open <url>` all land in the wrapper too, and a pre-populated `mimeapps.list` with foreign handlers and an `[Added Associations]` section keeps every unrelated entry intact.
- **htop that "opens and closes instantly" is repaired on every existing container by `umo update`:** the failure itself (a blank or unresolvable `TERM` reaching the container, ncurses resolving the terminal type `unknown` and htop dying before first paint) was fixed in v4.16.8, but containers installed before that release kept the old login wrapper and unguarded bashrc. The refresh pass re-renders `umo-login.sh`/`umo-user.sh` with the `TERM="${TERM:-xterm-256color}"` default and prepends the marker-checked TERM guard block on both users' bashrc, so one `umo update` on the device is enough: `umo login` → `htop` renders its full UI instead of exiting rc=1, and the menu entry (htop ships an `htop.desktop` with `Terminal=true`) stays alive because xfce4-terminal provides a real `xterm-256color`.
- **VNC no longer runs untuned - the session gets real performance knobs and the aggressive mode stops being dead code:** `umo_perf_vnc` exported `UMO_VNC_DEPTH=16` in aggressive mode and nothing ever read the variable, so aggressive installs ran at depth 24 exactly like balanced ones; meanwhile TigerVNC's defaults (60 updates per second, ImprovedHextile compression on) spend phone CPU on encoding work that is pointless for a viewer connected over loopback - the very CPU proot's ptrace tax already fights for, which is what makes the desktop freeze while apps open. The container start script now sources an optional `/etc/umo/vnc.conf` and passes `-FrameRate` and `-ImprovedHextile` to `Xtigervnc` (each flag probed against `Xtigervnc -help` first, so a TigerVNC build missing either parameter still starts), and the perf phase writes that file - balanced: depth 24, 30 fps, fast hextile; aggressive: depth 16, 20 fps, fast hextile - while the container refresh deploys the same file into existing containers so `umo update` alone speeds up an existing install, and the start banner now prints the active tuning (`depth 24 - 30 fps - hextile fast`). Verified in a live container: the tuned `Xtigervnc :5 … -FrameRate 30 -ImprovedHextile 0` comes up clean and listens, the unprobed-parameter fallback path keeps the server startable, and both jammy (TigerVNC 1.12) and noble (1.13) advertise both parameters.
- **The compositor is now forced off in existing containers too:** the xfwm4 channel template ships `use_compositing=false` for fresh installs, but containers created before that template kept compositing on - every frame gets re-composited before VNC encodes it, the heaviest per-frame cost on a phone CPU. The container refresh now flips `use_compositing` true → false in any existing per-user `xfwm4.xml` channel file and reports `Compositor Disabled For VNC Performance` when it did.
- **`xdg-utils` was missing from every graphical desktop set:** the XFCE4, LXDE and Openbox installs all used `--no-install-recommends` and nothing in those package lists pulls `xdg-utils`, so `xdg-open` - the generic URL hand-off countless apps call - simply did not exist inside the container and every such click failed silently. It now installs with all three graphical desktops, both in the DE installer and in the VNC start script's auto-install fallback list.

## [v4.16.12] - 2026-08-28

### 🎨 Changed
- **GNOME Web (Epiphany) is gone from the project entirely - Falkon is the one and only browser:** v4.16.6 made Falkon the default but kept Epiphany around as a legacy fallback in six places, and every trace has now been removed. The launcher wrapper (`/usr/local/bin/umo-browser`) no longer resolves `epiphany`/`epiphany-browser` and no longer exports the WebKit sandbox switch or the cairo GSK renderer - it execs Falkon with the QtWebEngine switches or exits 127 with the install hint; the in-container app installer no longer rewrites Epiphany's desktop entry or moves aside its D-Bus service; the Plank dock builder no longer pins Epiphany when Falkon's desktop file is missing; the app-set detector recognizes a browser set by Falkon alone; and the `WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS` export is dropped from the fresh-container shell profile, the VNC session environment and the wrapper alike. Existing containers that still carry the old browser get it actively removed during `umo update`/`umo refresh`: the container refresh purges `epiphany-browser`/`epiphany` with autoremove (evidence in `/tmp/umo-epiphany-purge.log`), deletes any surviving desktop entry, scrubs the stale WebKit sandbox export out of `/root/.bashrc` and `/home/umo/.bashrc` line by line, and reports `Legacy GNOME Web (Epiphany) Removed - Falkon Is The Default Browser` when it actually had something to remove. Verified end-to-end in live containers: an Epiphany install is fully purged by the refresh block (binary, desktop entry and dpkg state all gone, the bashrc scrub keeps every other line intact), and Falkon launches through the slimmed wrapper under X with its desktop entry pointing at it.

## [v4.16.11] - 2026-08-28

### 🎨 Changed
- **The fetch-tool fallback no longer presents itself as a warning:** fastfetch does not exist in either the 22.04 or the 24.04 repositories, so the single `⚠ Fastfetch Unavailable On This Release - Installing Neofetch Instead` line introduced in v4.16.9 fired on every install of every supported release - a warning that is always true is noise, not a warning. The basic set now checks availability quietly (`apt-cache show` straight into the log) and installs whichever exists as one normal labeled group - `Installing Fetch Tool (Neofetch)...` on 22.04/24.04, `Installing Fetch Tool (Fastfetch)...` on any future release that ships it - leaving exactly one chevron step line and one checkmark verdict, no warning glyph. The either/or satisfaction probe (`fastfetch,neofetch`) is unchanged.

## [v4.16.10] - 2026-08-28

### 🐛 Fixed
- **The "to verify the environment." hint after `umo update` printed in blue instead of the dimmed white of every other hint line:** the cyan color span around `umo status` was never reset before the dim attribute - `${_UMO_CYN}umo status${_UMO_DIM} to verify...` - and ANSI `2m` only adds faintness without clearing the color, so on terminals that ignore the faint attribute (Termux among them) the whole tail of the line stayed bright blue. The `umo user` hint carried the identical missing-reset bug. Both lines now reset before the dim span (`...umo status` + reset + dimmed `to verify the environment.`), matching the correct pattern the sibling `umo update --scripts-only` hint already used, so the hint tails render in the same soft white/grey as the rest of the CLI.

## [v4.16.9] - 2026-08-28

### 🎨 Changed
- **The installation log now speaks with one voice everywhere:** the four installers each printed in their own dialect - the apps installer printed bare `Installing X...` / `Group OK` / `Group FAILED` lines through a host-side pipe filter that stripped their color, the desktop installer tee'd its entire raw apt stream into the terminal with no progress lines at all and a `=== DESKTOP INSTALL FAILED ===` banner, the VNC installer streamed raw apt output with `=== ERROR ===` and `--- section ---` diagnostic banners, and the theme installer streamed raw apt output - so a single install flickered between four output styles. Every generated in-container script now shares one log prelude, emitted from a single source (`_umo_log_container_prelude` in `lib/core-ansi.sh`): the exact glyph/color detection and the `_step/_ok/_fail/_warn` quartet that `config/container/umo-startvnc` and `umo-install-extras` already used. Progress is `❯`, success is `✔`, failure is `✖`, fallbacks are `⚠`, and error details indent six spaces under their failure line - while all apt/dpkg noise goes into that step's own log file (`/root/install-apps.log`, `/root/install-de.log`, `/root/install-vnc.log`, `/root/install-theme.log`) instead of the terminal. The apps and desktop installers also run direct-to-terminal now (the old host-side pipe and tee filter were what stripped container color in the first place), the desktop and VNC host verdicts switch from ad-hoc lowercase printfs (`installed successfully`, `encountered errors`) to the standard `umo_log_ok`/`umo_log_warn` helpers (`XFCE4 Installed`, `TigerVNC Installation Encountered Errors (Code N)`), the desktop installer's apt evidence now lands in `/root/install-de.log` instead of a tee, the CRITICAL missing-component guidance is rebuilt on the standard helpers, and the perf debloat/cleanup scripts plus the two bootstrap configure steps redirect their apt output into log files too, so nothing unstyled surfaces anywhere in the flow. Verified end-to-end in a live container: the basic set, the full XFCE4 desktop install, TigerVNC, the theme package group and a deliberately-broken package group all print the same hierarchy (step heading, chevron sub-steps, verdict glyphs, indented failure details).

### 🐛 Fixed
- **The fastfetch step printed a scary failed group with four repeated apt errors on every install:** the basic set ran the fallback as `_apt fastfetch || _apt neofetch`, and since fastfetch does not exist in either the 22.04 or the 24.04 repositories, every install first printed `Group FAILED: Fastfetch - real apt errors:` followed by four identical `E: Unable to locate package fastfetch` lines (the initial attempt and the retry, each surfaced twice by the accumulated-log grep) before falling back to neofetch as designed. The fallback is now quiet: the generated script checks availability with `apt-cache show` straight into the log, prints one `⚠ Fastfetch Unavailable On This Release - Installing Neofetch Instead` line only when neofetch is actually chosen, and installs the chosen package as one normal `Installing Fetch Tool...` group. Real failures still surface - with the error block deduplicated (repeated identical lines collapse into one) and capped at six indented lines instead of eight raw ones.

## [v4.16.8] - 2026-08-28

### 🐛 Fixed
- **htop started and quit immediately:** the proot login wrappers forwarded the caller's TERM verbatim (`TERM="$TERM"` inside the `env -i` chain), so any invocation where TERM arrives empty or unset - `umo start` from a context without a terminal, or a Termux session that never exports TERM - reached the container with a blank TERM, ncurses resolved the terminal type `unknown`, and htop died before first paint with `Error opening terminal: unknown.` (reproduced in a live container: TERM set, htop renders its full UI; TERM unset, it exits rc=1 instantly). TERM now defaults to `xterm-256color` in every wrapper rendering - the fresh-install heredocs for both `umo-login.sh` and `umo-user.sh` in `modules/umo-proot.sh`, and both host-side templates `config/templates/umo-login.sh` and `config/templates/umo-user.sh` that `umo update`/`umo refresh` re-render for existing containers - and a guard block is prepended on top of `/root/.bashrc` and `/home/umo/.bashrc` (at install time through the proot bashrc patch, and into existing containers during the container refresh of `umo update`/`umo refresh`): when TERM is empty, `dumb`, or its terminfo entry fails `infocmp`, the guard exports `xterm-256color` - a target that always resolves because ncurses-base (an Essential package) ships that entry, verified live at `/lib/terminfo/x/xterm-256color`. The basic set also installs `ncurses-term`, the full ~2800-entry terminfo database, so exotic TERM values device terminals may export (alacritty, tmux-256color, konsole-256color and friends) keep their real capabilities instead of relying on the guard. The guard is marker-checked and idempotent, prepends above every existing line, and preserves the original bashrc content byte-for-byte. Verified end-to-end in a live container: all six guard cases (empty, dumb, missing-entry, valid entries) behave correctly, a login shell with a blank TERM lands on `xterm-256color`, and htop runs inside xfce4-terminal on the desktop. htop is a probe binary for the basic, browser and full sets from this release.
- **The basic-set installer reported a broken status on every install since v4.16.6:** the either/or probe entry `fastfetch|neofetch` was baked unquoted into the generated install script's `for` word list, where the shell reads `|` as a pipeline operator - a syntax error at the probe line aborted the whole rest of the script (probe loop and status file write), so every basic/browser install ended with `MISSING=probe-not-run` and the host line said "Finished With Warnings" even though every package had actually installed (the install body runs before the parser reaches the broken line). The either/or separator is now a comma (`fastfetch,neofetch`) and the probe `case` matches and splits on `*,*` instead. Verified: the old generated script fails under `sh` with rc=2 at exactly that line, the new one parses clean, and a real end-to-end basic-set run through the exact `_run_installer` flow in a live Ubuntu container reports `SET-RESULT OK`, with neofetch satisfying the either/or probe on jammy where fastfetch does not exist.
- **The desktop environment was audited app by app against a clean live container and passed whole:** the session stack (Xvfb, xfwm4, xfdesktop, xfce4-panel with the whiskermenu brand button, plank) plus every shipped application - thunar, xfce4-terminal, mousepad, ristretto, file-roller, xfce4-taskmanager, xfce4-screenshooter, and Falkon launched through its wrapper from the hardened desktop entry - all start, stay alive, and render under X; htop inside xfce4-terminal (the exact failing case from the field) runs clean once TERM is defaulted. The only defect the audit found was the TERM gap fixed above.

## [v4.16.7] - 2026-08-28

### ✨ Added
- **The dev set now ships Visual Studio Code and Geany instead of just command-line tools:** the set carried python3/nodejs/gcc/vim and nothing graphical, which made it look empty next to its name. The generated install script now wires the official Microsoft apt repository (downloads `packages.microsoft.com/keys/microsoft.asc`, dearmors it into `/usr/share/keyrings/packages.microsoft.gpg` - through `gpg --dearmor` when present and through a pure grep+base64 fallback otherwise, since jammy's apt 2.4 rejects ASCII-armored keys under `signed-by` and the minimal rootfs carries neither gpg nor wget guaranteed - then writes the sources entry for amd64/arm64/armhf and refreshes apt) and installs `code`, which ships real debs for arm64 on both jammy and noble. VS Code is Electron, so it gets the same proot treatment as Falkon: a dedicated launcher wrapper (`/usr/local/bin/umo-code`, shipped in `config/container/`) runs it with `--no-sandbox --disable-gpu --disable-dev-shm-usage`, software GL, a defaulted DISPLAY and - because the container session runs as root and VS Code refuses to start as superuser otherwise - a `--user-data-dir` when the uid is 0; `code.desktop` has every `Exec=` line (main and desktop actions alike, since an action run without the sandbox switches dies before first paint under proot) rewritten to the wrapper, both at app-set install inside the container and host-side during `umo update`/`umo refresh`. Alongside it, the set gains Geany (a lightweight GTK IDE that renders fast over VNC), `python3-dev` and `pkg-config`, the Plank dock pins `code` for the dev and full sets, and the installer menu, the install guides (EN/AR), and the satisfaction probes (dev and full) match. If the Microsoft repository is unreachable the group fails loudly, the rest of the set still installs, and the result line reports exactly `MISSING=code` with the diagnose command. The recommended disk space for dev rises to ~3.4GB and full to ~7GB. Verified end-to-end against live Ubuntu containers: the repository wires on jammy (gpg path) and noble (base64 fallback path, no gpg present), `code` 1.135 installs on both, every dev probe resolves, and VS Code launches through the wrapper as root under Xvfb and paints its window.

## [v4.16.6] - 2026-08-28

### 🐛 Fixed
- **The whiskermenu button icon still showed the stock icon after a full uninstall + reinstall:** the v4.16.5 approach only enforced the icon through the `xfce4-panel` xfconf channel, but reading the plugin source for both Ubuntu releases in the field shows that is not where jammy's plugin reads it from at all - jammy ships whiskermenu 2.7.1, which ignores the xfconf channel entirely and loads `button-icon` from `/etc/xdg/xfce4/whiskermenu/defaults.rc` plus each user's `~/.config/xfce4/panel/whiskermenu-N.rc` profile files, so every xfconf write was invisible to it; noble ships 2.8.3, which does bind xfconf, but only after the panel's own first-boot migration, so a stale or still-missing value rendered the stock icon there too. The brand is now enforced on three layers: the VNC start script (before any session starts) writes `defaults.rc` with the absolute brand path, seeds every session user's `xfce4-panel` channel from the bundled panel template when the channel file is missing, patches every existing `whiskermenu-*.rc` profile in place, and rewrites stale `button-icon` entries inside the users' panel channel XML directly (handling both the open-tag and self-closing forms of the whiskermenu plugin element, keeping every other property intact, idempotent across restarts); the in-session desktop init keeps the xfconf enforcement as a live backstop and now verifies the value reads back correctly in up to three rounds instead of writing blindly; and both the theme phase and `umo update`/`umo refresh` deploy the defaults file plus the panel template into the container. Verified end-to-end against a real running panel on both releases - the button renders the orange Circle of Friends on jammy (2.7.1, via defaults.rc + profile patch) and on noble (2.8.3, via the seeded channel file).
- **Non-basic app sets could install nothing at all while the installer still reported success:** every package group ran through `apt-get install ... || true` followed by `dpkg --configure -a || true`, so any failure - a transient repository error, an interrupted dpkg run, a hang under proot - was swallowed and the phase printed "All Applications Installed" over an empty set. The app installer is rebuilt around a per-group `_apt` helper: each package group gets its own apt invocation bounded by an 1800-second timeout and appended to `/root/install-apps.log`, a failed group triggers exactly one repair-and-retry round (`dpkg --configure -a` + `apt-get update` + reinstall of the same group), and after the phase finishes the generated script probes every expected binary (with either/or support, e.g. `fastfetch|neofetch`) and writes `OK` or `MISSING=<packages>` to a status file that the host-side installer reads back - so the result line now reports exactly which packages are missing and prints the one command that opens the log, instead of claiming success. The generated script is kept at `/root/install-apps.last.sh` for inspection, and the phase starts with a free-disk-space check whose recommendation is sized per set (dev ~2.6GB, media ~3.6GB, office ~2.8GB, full ~6.2GB), warning before a doomed install instead of failing package-by-package. Verified end-to-end against a real Ubuntu container: the browsers and dev sets run through the exact generated script, install, retry-free, and report `SET-RESULT OK` with every probe satisfied.

### 🎨 Changed
- **The default browser is now Falkon, replacing GNOME Web (Epiphany) in every set:** the GTK4/WebKitGTK stack was the heaviest thing in the container - slow to start and slow to render over VNC, and it needed a chain of sandbox and renderer workarounds just to paint a window under proot. Falkon is a lightweight QtWebEngine browser that ships as a real deb on both jammy and noble (arm64 included), so every app set now installs `falkon` instead of `epiphany-browser` and every satisfaction probe looks for it (existing containers keep working - epiphany stays as the legacy fallback in the wrapper and in set detection). The launcher wrapper (`/usr/local/bin/umo-browser`) now prefers falkon and exports `QTWEBENGINE_DISABLE_SANDBOX=1` plus `--no-sandbox --disable-gpu --disable-dev-shm-usage`, the official switches for the same reason WebKit's sandbox was disabled: QtWebEngine's sandbox needs namespaces proot cannot provide, GPU acceleration is meaningless on llvmpipe, and `/dev/shm` is too small - with epiphany kept below it so older containers still launch their existing browser. Falkon's desktop entry (`org.kde.falkon.desktop`) gets its main `Exec=` rewritten to the wrapper - only the first one, so the New Tab/New Window/Private Browsing desktop actions keep their own commands - the Plank dock pins `org.kde.falkon`, the Openbox root menu falls back through the wrapper to `falkon`, the dpkg excludes keep falkon's man page instead of epiphany's so `update-alternatives` stays clean, and both the VNC session environment and the proot profile export the QtWebEngine switches so terminal launches behave the same as menu launches. The installer menu, the install guides (EN/AR), and the `--apps` help line (now listing all six sets: basic, dev, media, office, browser, full) match.

## [v4.16.5] - 2026-08-28

### 🎨 Changed
- **The bundled Ubuntu logo is now the authentic one, fetched from the internet, not a hand-drawn approximation:** v4.16.4 shipped a locally-constructed `ubuntu.svg`; that is replaced with the exact official Ubuntu 2022 brand mark - the orange Circle of Friends with no wordmark - fetched verbatim from Wikimedia Commons (`Ubuntu-logo-no-wordmark-solid-o-2022.svg`, © Canonical Ltd., GPLv3). The bundled `config/theme/icons/ubuntu.svg` is byte-for-byte identical to the upstream file (only a trailing newline differs, verified by hash). It is also rasterized to PNG at 48/64/96/128/256 and every raster is squared onto a transparent canvas so it renders cleanly in the panel button.

### 🐛 Fixed
- **The whiskermenu button icon still did not change to the Ubuntu logo after v4.16.4:** the v4.16.4 approach pointed the panel at an icon *name* (`button-icon=ubuntu`) installed only as an SVG in the hicolor theme, which relies on the whole icon-theme/lookup chain resolving the name at runtime - a chain that stays broken under the minimal container (no inherited theme index reliably mapping the name, and no SVG rasterizer wired into the panel's icon lookup), so the button kept its stock icon. Reading the actual `xfce4-whiskermenu-plugin` source shows the reliable path: when `button-icon` is an **absolute file path**, the plugin's `icon_changed()` flags it as a file icon and `size_changed()` loads it directly with `gdk_pixbuf_new_from_file_at_size()`, completely bypassing icon-theme resolution and the SVG loader. The panel template now ships `button-icon=/usr/share/umo/brand/ubuntu.png`, the deploy step installs that exact raster to that exact path, and the session-boot init re-points every whiskermenu plugin to the same absolute path at every session start (guarded on the file existing), so the logo shows regardless of theme state. Both the install-time theme apply and the host-side `umo update`/`umo refresh` now deploy the full set (SVG + all five PNGs into hicolor, plus the brand PNG), replacing the old SVG-only copy.

## [v4.16.4] - 2026-08-27

### ✨ Added
- **The XFCE top-panel menu button now carries the Ubuntu identity:** the whiskermenu button icon switches from the stock `start-here-symbolic` to a bundled Ubuntu roundel (the orange Circle of Friends, shipped as `config/theme/icons/ubuntu.svg`). The icon is installed into the universal hicolor theme at `/usr/share/icons/hicolor/scalable/apps/ubuntu.svg` so it resolves under every icon theme the design activates (Tela, Materia, gnome) - with a minimal hicolor `index.theme` written only when the system one is missing - the panel template ships `button-icon=ubuntu`, and the session-boot init refreshes the hicolor icon cache and re-points every whiskermenu plugin's `button-icon` to `ubuntu` at every session start, so existing containers get the icon on their next `umo stop && umo start` after an update (the icon file is also deployed host-side during `umo update`/`umo refresh`).

### 🐛 Fixed
- **The container clock and date no longer run on hardcoded UTC:** the container now inherits the device timezone automatically, the same one Termux sees. The installer reads `getprop persist.sys.timezone` (falling back to `$TZ`, then to the numeric `date +%z` offset mapped onto `Etc/GMT±N` with the inverted Etc sign and half-hour rounding, with charset/depth validation and `..` traversal rejection on every path) and ships the value three ways: the rootfs gets `/etc/localtime` linked and `/etc/timezone` written during finalize, the `tzdata` debconf preseeds in the desktop and VNC install scripts now carry the detected Area/Zone instead of the old pinned `Etc`/`UTC` (so tzdata's postinst can never reset the container to UTC), and the stray `export TZ=Etc/UTC` left in the VNC script header is gone. The detected zone shows in both the Configuration Summary and the Installation Complete summary, `umo update`/`umo refresh` sync the timezone into existing containers from the device, and a zone the rootfs does not carry falls back to `Etc/UTC` with a warning instead of a broken clock. The panel clock template also becomes explicit about showing both the time and the date (digital mode with the date+time layout, the only layout that renders both) and drops the `show-seconds` property that digital mode never reads, so the corrected zone surfaces as the right local time and date straight from the first session.

## [v4.16.3] - 2026-08-27

### 🐛 Fixed
- **GNOME Web still did nothing on click in the basic set (even with v4.16.2's sandbox switch):** the sandbox switch only reached launches that ran the patched `Exec=` line, but GNOME Web's desktop entry ships with `DBusActivatable=true`, so XFCE launchers (menu, plank dock, panel launchers) activate it through the D-Bus service (`org.gnome.Epiphany.service`), which runs the raw binary and skips the `Exec=` line entirely - the WebKit sandbox then kills the web process before a window ever appears. On top of that, GNOME Web on noble is GTK4, and under Xvnc the GL renderer path dies before first paint. Every click-launch path now funnels through a dedicated launcher wrapper (`/usr/local/bin/umo-browser`, shipped in `config/container/`), which disables the WebKit sandbox with the official switch, pins the GTK4 renderer to cairo (with software GL), defaults DISPLAY, resolves the binary even when only `epiphany-browser` is on PATH, and logs every attempt to `/tmp/umo-browser.log` so any future failure is one file away from a diagnosis. The wrapper is deployed at install time (VNC scripts phase plus the apps phase, so minimal-mode containers get it too) and during `umo update`/`umo refresh` for existing containers; the `.desktop` file is rewritten to `Exec=/usr/local/bin/umo-browser %U` with `DBusActivatable=false` forced and the cold-start D-Bus service file moved aside (at app-set install inside the container and host-side during update/refresh, including containers already carrying the older env-based Exec line from v4.16.2); the Openbox fallback menu now calls the wrapper first; and fresh containers export `GSK_RENDERER=cairo` and `LIBGL_ALWAYS_SOFTWARE=1` from the root shell profile alongside the sandbox switch so terminal launches behave the same. The post-install browser probe now also reports the installed version (`UMO-BROWSER-OK ...` / `UMO-BROWSER-MISSING ...`) and runs inside the container instead of being evaluated on the host at script-generation time.

## [v4.16.2] - 2026-08-27

### 🐛 Fixed
- **GNOME Web (the basic-set browser) could not run inside the container:** WebKitGTK launches its web/network subprocesses inside a bubblewrap sandbox, which needs user namespaces that proot does not provide - so Epiphany died or came up blank the moment a page tried to load. Every launch path now disables that sandbox with the official `WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS` switch: the app's `.desktop` file is rewritten to `Exec=env WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1 epiphany %U` right after the app-set install inside the container, the same rewrite is applied host-side during `umo update`/`umo refresh` for containers that already have the browser (so existing installs are fixed without reinstalling), the Openbox menu fallback chain carries the switch, and fresh containers export it from the root shell profile so running `epiphany` in a terminal works too.
- **The XFCE desktop could still boot with the stock wallpaper instead of the UMO one:** the per-channel defaults in `/etc/xdg` only seed properties the session user has never saved, and a saved `last-image`/`last-single-image` from the XFCE default always won on the next boot. The theme apply now also rewrites the session users' own xfconf channel files on disk (`/root` and `/home/umo`) - existing files keep every other setting but get their image paths pointed at `/usr/share/wallpapers/umo-wallpaper.jpg`, missing files are created with the UMO backdrop under every plausible VNC monitor key (monitor0, monitor-0, monitorVNC0, monitorVNC-0, monitorVirtual1, default...) - so the very first xfdesktop of a fresh user already reads the UMO wallpaper, with the existing session-boot apply (xfconf writes + `xfdesktop -R`) kept as the live-session layer. The stock wallpapers shipped under `/usr/share/backgrounds/xfce/` are now overwritten with the UMO image alongside `/usr/share/xfce4/backdrops/`, the shipped per-channel template gains the XFCE-4.18 `last-single-image` key and the full monitor-key matrix, and the session-boot init logs the connected outputs, the channel's monitor keys and the backdrop values before and after its reload (`/tmp/umo-desktop-init.log`) so any future miss is one file away from a diagnosis.

## [v4.16.1] - 2026-08-27

### 🎨 Changed
- **Every in-progress sub-step now carries the chevron arrow, everywhere, and only section headings keep the side block:** the designer-extras flow already set the pattern (`▌  Install Designer Extras...` heading above `❯  Fetching Orchis-theme (git)...` sub-steps) and the whole tool reads the same way now. The install flow prints `❯  Installing XFCE4...`, `❯  Installing TigerVNC...` and `❯  Installing <set>...` under their `▌` step headings (the apps module printed no in-progress line at all before - it ran from the heading straight into its container script with nothing on screen until the final verdict, so multi-minute set installs looked like a stall). The update flow prints `❯  Checking For New Release On GitHub...`, `❯  Downloading Release...`, `❯  Refreshing Host/Container Scripts...` under its `▌` step headings. `umo start` prints `❯  Initializing Termux:X11 Services...`, `❯  Initializing UMO Services...`, the generated environment wrapper prints `❯  Starting UMO Environment...` and the in-container VNC script prints `❯  Starting UMO VNC Server...` (its block glyph is gone - every line it prints is a sub-step). `umo stop` prints `❯  Stopping UMO Services...` and the rendered stop script prints `❯  Stopping VNC...`, and the one-liner release installer prints `❯  Fetching Latest Release From GitHub...` / `❯  Starting Installer...` under its `▌  UMO Release Installer` heading. On non-UTF-8 terminals the chevron falls back to `>` exactly like the extras lines, while headings keep the `|` block - the two stay visually distinct in ASCII mode too. Verified end-to-end under a PTY against the desktop, VNC, apps, update, start, stop and release-installer flows, in both UTF-8 and ASCII modes.

## [v4.16.0] - 2026-08-27

### 🔒 Security
- **The bootstrap apt sandbox config never left the container:** the proot bootstrap writes `etc/apt/apt.conf.d/99-umo-sandbox` with options that are only safe while the rootfs is being assembled (`APT::Get::AllowUnauthenticated "true"`, `APT::Acquire::AllowInsecureRepositories "true"`, `Dpkg::Options:: "--force-all"`, `Debug::NoLocking "1"`), and until now that file stayed forever - the container permanently accepted unauthenticated packages and force-ran every dpkg operation. The finalize phase now replaces the file once bootstrap is done with a sanitized performance-only config (`APT::Sandbox::User "root"`, `--force-confdef`, `--force-confold`, `Dpkg::Use-Pty "0"`, `DPkg::FlushSTDIN "false"`), and `umo update`/`umo refresh` apply the same replacement inside existing containers during the container-refresh step - so installs created before this release are hardened too - and the running system verifies package authentication like a normal Ubuntu with dpkg protections back on.
- **The `--dir=<path>` installer argument was injected unvalidated into shell strings:** the sources.list writer and the in-container README writer embedded the raw value into `sh -c` command strings, so a path containing quotes could smuggle commands in. The value is now validated against a strict charset (letters, digits, dot, underscore, hyphen, slash - `~` still expands to the home directory), and the README writer passes the path as a positional argument instead of embedding it.

### 🐛 Fixed
- **`umo stop` reported success when the stop was incomplete:** the in-container `umo-stopvnc` printed the green OK glyph on its "VNC Stop Incomplete (A Server Process Survived)" branch. The failure branch now prints the warning glyph in the warning color.
- **The APT speed config depended on which copy happened to win:** `config/templates/apt-umo-speed.conf` was missing `Acquire::PDiffs "false";` while the fallback heredoc in the perf module carried it, so the container got a different apt config depending on whether the template file was found. The template now matches the fallback exactly.
- **`umo start` and `umo stop` gave misleading output on a machine where UMO was never installed:** both proceeded with a non-existent `umo-login.sh`, so start produced the "VNC Failed To Start / phantom process killer" guidance (meant for a real install) instead of saying UMO is missing. Both now fail fast with a clear "UMO not installed" message (stop exits cleanly with nothing to stop).
- **Trailing whitespace in the installer help display:** three blank display lines in `bin/umo-install` carried trailing spaces, violating the project `.editorconfig`. Trimmed.
- **The full Termux path prefix was still printed in display messages (`/data/data/com.termux/files/home/...` instead of `/home/...`):** the display-path helpers (`umo_fs_display_path`, the `_umo_dp` copies in `bin/umo-cli` and `bin/umo-start`) used `${PREFIX:-/data/data/com.termux/files}` as the base to strip, but Termux sets `PREFIX` to `/data/data/com.termux/files/usr`, so the fallback never applied and only paths under `usr` were ever shortened. The base is now derived from the parent of `$PREFIX` (the real files directory), so every path inside the Termux tree is shown shortened, not just `/home`: `Path: /home/umo-ubuntu`, `CLI command installed (/usr/bin/umo)`, `Scripts: /home/.umo`, etc. The same fix also covers the remaining messages that still printed raw host paths: host aliases + settings-saved lines, cache/archive errors, the missing-archive error in the download library, the VNC module (config dir, missing container script, scripts dir), every `core-fs` helper message (mkdir, write, backup, patch, render), the release installer's "installed to" line, and the `--dir` example in the installer help (now `--dir=~/ubuntu`). Functional paths written into configs, scripts and copy-pasteable commands stay absolute.

### 🗑️ Removed
- **Every comment stripped from all code files (29 shell scripts):** header banners, inline notes and the comments inside generated-script heredocs are gone from all of `install.sh`, `umo.sh`, `bin/`, `lib/`, `modules/`, `config/container/`, `config/templates/` and `config/xstartup` - the stripper was heredoc-aware and quote-aware, so shebangs, `#` characters inside quoted strings, `${var#pattern}` expansions and heredoc content survived byte-for-byte (verified by `sh -n` on every file and an unchanged shellcheck fingerprint). The two functional survivors are the shebangs inside generated scripts and the `# UMO Audio bridge` marker line, which the PulseAudio config patch uses to detect an already-applied block.
- **Two dead dpkg config lines:** `Dpkg::Post-Invoke {}` and `Dpkg::Pre-Invoke {}` in the bootstrap sandbox config were no-ops (an empty pair does not clear the invoke lists) and were dropped with the sandbox-config rewrite.
- **Reference-count pass on unused code and files:** zero unused functions, zero unused variables (the two shellcheck SC2034 notes are cross-file uses) and zero orphan files - every theme config, template, container script, screenshot, doc and workflow is reachable - so nothing else was removed. The one intentional duplication (host scripts written by heredocs at install time and by templates at refresh time) is kept on purpose.

### 🎨 Changed
- **The installer sub-headings now carry the same side arrow as `umo update`:** `umo_ui_header` and `umo_ui_menu` (System Check, Dependencies, Ubuntu RootFS, Proot Container, VNC Server, Audio Bridge, Systemctl Emulator, Desktop Environment, Applications, Performance Tuning, Desktop Theme, Finalizing, System Summary, Configuration Summary, the four selection menus) print the `UMO_G_STEP_BLOCK` mark before the title - `▌ System Check` with the underline extended to match, exactly the block style the update flow uses for its step headings - with the same clean `|` fallback on non-UTF-8 terminals. The "Installation Complete" and "Get Started" headings on the final screen carry the mark too.
- **Unified comment style for all config files:** the `.env`-style configs keep their comments and now all use the same box format - a `# ─────────────────────────────────────────────` banner around the file title plus `# ── Section ──` markers (apt speed conf, GTK2/GTK3 templates, LXDE session/desktop-items/panel, tint2, XFCE terminal, Plank dock.theme). XML configs carry the same box inside `<!-- -->` (fontconfig, XFCE desktop/panel/xfwm4/xsettings, openbox rc/menu) and the fastfetch JSONC inside `//`. The Plank dock.theme also drops the verbose per-key upstream descriptions in favor of the two section markers. `.gitignore`, `.gitattributes` and `.editorconfig` already used the style and stay untouched.

## [v4.15.11] - 2026-08-27

### 🐛 Fixed
- **The Plank dock rendered as the square, edge-glued stock dock instead of the rounded design:** the dock runs with `Theme=Gtk+`, which plank resolves to a `plank/dock.theme` file inside the ACTIVE GTK theme folder - and the Orchis installer never ships its plank theme (the file exists in the Orchis source, but `install.sh` does not copy it), so plank warned and fell back to its built-in Default theme (the square one). UMO now carries the rounded Orchis dock.theme (TopRoundness=18, translucent black, the exact file from the Orchis source) in `config/theme/plank/` and installs it under every GTK theme the design may activate (Orchis-Dark/Light-Compact and both Materia fallbacks), so the dock is rounded whichever theme wins.
- **The UMO wallpaper still did not appear in some sessions:** the in-container desktop init is no longer silent - every step (wallpaper found, bus source, channel wait, apply rounds, reload, theme enforcement) now logs to `/tmp/umo-desktop-init.log` inside the container, so a failure is one file away from a diagnosis. Two real fixes on top: the session dbus discovery gains a third fallback (reading `DBUS_SESSION_BUS_ADDRESS` from the environ of a running xfconfd/xfdesktop/xfce4-session/xfwm4/plank process when the dbus session file is missing), and after writing every backdrop property the init now runs `xfdesktop -R` (reload all settings and repaint), because a session that started before the channel write can miss the change notification and keep showing the old backdrop.
- **Em dashes removed from the remaining places:** all em dashes left in the older commit messages and in the published release notes of v4.15.1 through v4.15.9 are gone - the history was rewritten, all tags re-pointed at the rewritten commits, and the release notes re-published from the updated CHANGELOG.

## [v4.15.10] - 2026-08-27

### 🐛 Fixed
- **Two `update-alternatives` warnings on every `epiphany-browser` install ("skip creation of /usr/share/man/man1/x-www-browser.1.gz ... associated file ... doesn't exist", same for `gnome-www-browser`):** the epiphany postinst registers both browser alternatives with a slave man page (`epiphany-browser.1.gz`), but the UMO dpkg excludes file keeps all of `/usr/share/man/*` from ever being unpacked, so the slave target never existed. Harmless, but noisy on every fresh install and on any future epiphany upgrade. The excludes now carry a `path-include` for exactly that one ~1 KB man page (dpkg's last-matching-rule-wins semantics, the same mechanism the English-locale include already uses), so the file is unpacked, the alternative slave links are created cleanly, and both warnings are gone at the source.

### 🎨 Changed
- **No more em dashes anywhere in the project text:** all em dashes in `CHANGELOG.md` and both README files were replaced with plain hyphens and regular punctuation, unifying the writing style with the release titles.

## [v4.15.9] - 2026-08-27

### 🐛 Fixed
- **Tela icons always reported "Install Incomplete / icon theme Tela-Black-Dark missing" even though the installer finished successfully - case mismatch:** the Tela installer creates lowercase directories (`Tela-black-dark`, verified again against the upstream `install.sh` and a full local run), but the whole design checked and configured `Tela-Black-Dark`. GTK icon-theme names are case-sensitive, so the theme could never be found. All references (mode defaults, extras installer, satisfaction probe, session-boot enforcement, config-alignment sed) now use the real lowercase name, and the alignment pass also migrates any config still carrying the old capitalized form.
- **`firefox-esr` has no installation candidate on Ubuntu and broke every app-set install:** Ubuntu dropped the Firefox ESR deb (Firefox is snap-only, which cannot run inside proot), so every set that referenced it printed `E: Package 'firefox-esr' has no installation candidate` and the app-set probe could never be satisfied. All sets and probes now use `epiphany-browser` (GNOME Web - a real deb that works inside proot), the duplicate install line in the browsers set is gone, and the Plank dock pins `org.gnome.Epiphany` instead of `firefox-esr`.
- **FiraCode Nerd Font reported "Could Not Be Installed" despite a 100% download:** the verification required `fc-list` (fontconfig), so on containers without it the freshly extracted fonts were declared missing. Success is now verified by the extracted `.otf`/`.ttf` files themselves (with `fc-cache` still run when available), and a `FiraMono.tar.xz` download is retried when the zip or `unzip` fails.

### ⚡ Performance
- **Tela install is now ~3x faster:** the extras installer previously installed both Tela families (standard + black, six variants of sed-heavy SVG recoloring and icon-cache runs under proot) regardless of the theme mode. It now installs only the variant family the active mode needs (dark: `Tela-black` + `Tela-black-dark`; light: `Tela` only) and patches the installer's `BRIGHT_VARIANTS` line to skip the unused brightness levels - verified end-to-end locally against the upstream `install.sh` (dark mode installs exactly the two needed variants and nothing else). The patch is idempotent: it matches both the pristine `readonly BRIGHT_VARIANTS=...` line and an already-patched one, so a cached source kept from an interrupted run can never pin the wrong variant list on the next run (including after a mode change).

### 🎨 Changed
- **Docs and menus no longer advertise what does not install:** the install guide (EN/AR) now describes the basic set as shipping GNOME Web (Epiphany) and the default `umo-dark` theme with its real names (Orchis-Dark-Compact + Tela-black-dark icons + DMZ cursor, Materia/gnome fallback when the designer extras are missing) instead of the old Materia-dark + Papirus-Dark description, the READMEs (EN/AR) carry the lowercase icon-theme name, the installer's app-set menu says "Browser (Basic + GNOME Web)", and the Openbox root-menu browser chain falls back to `epiphany` instead of `firefox-esr`.

## [v4.15.8] - 2026-08-27

### 🐛 Fixed
- **The UMO wallpaper never appeared in the VNC session - root cause found:** `umo-desktop-init` waited for the xfce4-desktop xfconf channel *before* discovering the session dbus address, and dbus-launch only exports that address into the session's own child chain (not into the background init script) - so every `xfconf-query` failed and the script gave up after 20 seconds without applying anything. The dbus discovery now runs first (from the session bus file), the channel wait was extended to 60 seconds, and the wallpaper is applied to every monitor key that exists (xfconf-enumerated keys + xrandr outputs + the common fallback names), including `last-single-image`, with a verification grep and up to 3 retry rounds while xfdesktop finishes registering.
- **Plank dock did not match the design and had no pinned apps:** the dock now gets a written configuration on every design apply - `Theme=Gtk+` so it inherits the active GTK theme (Orchis dark/light instead of the stock gray), bottom position, centered, 48px icons, no auto-hide - plus default launchers pinned per the selected application set (base: Thunar, Terminal, Firefox ESR, Mousepad; media/full add VLC + GIMP; office adds LibreOffice + Atril; browser/full add Epiphany). Only apps whose `.desktop` file actually exists in the container get pinned, so the dock is always valid.

### 🎨 Changed
- **Sub-headings now use the installer's side arrow:** the in-container scripts (designer extras installer, VNC launcher/stopper) detect glyph support exactly like the installer - sub-steps print `❯` instead of the block mark (which stays reserved for main steps), with a clean ASCII fallback on non-UTF-8 terminals, and NO_COLOR/non-TTY output is blanked like everywhere else.

## [v4.15.7] - 2026-08-27

### 🐛 Fixed
- **The XFCE session never showed the UMO design after the first boot (no wallpaper, default panel, no dock):** `umo update` treated the theme as "already applied" whenever the Orchis/Tela/font directories existed and only re-checked the designer extras - skipping the whole cheap design pass (wallpaper, XFCE panel/xsettings/terminal, GTK config, fastfetch, ownership). The theme module is now split: the expensive part (apt packages + downloads) still runs only when missing, but a new `umo_theme_reapply_config` re-applies all local design configuration on **every** update, so the wallpaper and panel layout always converge on the UMO design.
- **The bottom Plank dock was missing in XFCE:** plank was neither in the XFCE desktop package set nor autostarted by the session - the VNC `xstartup` only started it on the non-XFCE fallback path (`startxfce4` is exec'd first, so the later `plank &` line never ran). Plank is now installed with the XFCE set (installer, re-apply and the startvnc lazy installer) and autostarted by xfce4-session via `plank.desktop` entries (per-user `~/.config/autostart` + system-wide `/etc/xdg/autostart`).
- **Session-boot theme enforcement:** `umo-desktop-init` now also sets the live GTK/icon theme with `xfconf-query` (Orchis/Tela when present, Materia/gnome fallback otherwise) - xfconf caches can ignore freshly written channel files, so the design is forced at every session start, alongside the existing wallpaper fix.
- **Application-set amnesia on legacy installs:** the saved app set was hard-defaulted to `basic` when not recorded, silently dropping richer sets. `umo update` now detects the installed set by probing the container binaries (full → office → media → dev → browser → basic), so re-apply repairs the apps the user actually has.

## [v4.15.6] - 2026-08-27

### ⚡ Performance
- **Dropped `papirus-icon-theme` from the theme packages - the single biggest install-time cost.** It unpacks ~120k tiny SVG files, which under proot's syscall emulation takes an hour or more (the "Setting up papirus-icon-theme" hang). It was dead weight anyway: it was re-introduced in v4.3.0 for the old Orchis/Papirus design, but the current design uses the Tela icons from the designer extras (fixed and verified in v4.15.5), and the project's own "Theme Phase Speedup" release had removed it before for exactly this reason. The re-apply path also purges it from existing installs (`apt-get remove -y papirus-icon-theme` when present), freeing ~600 MB of disk and removing it from all future dpkg runs.

### ✨ Added
- **`umo update --no-upgrade`:** runs the whole update (tool, scripts, settings re-apply) but skips the Ubuntu system upgrade phase - for users who want UMO current without waiting for `apt-get upgrade` + `full-upgrade` inside the container. Documented in the help, README and install docs (EN/AR).

### 🐛 Fixed
- **No more broken icons when the designer extras are unavailable:** previously the GTK/xsettings configs still pointed at `Tela-Black-Dark`/`Orchis-*-Compact` even when those themes had not installed, leaving the desktop with missing themes. The theme module now falls back to guaranteed-installed themes - `Materia-dark`/`Materia-light` (GTK) and `gnome` (icons) - and says so in the warning line.
- **The in-container config alignment upgrades fallback configs automatically:** when the Tela/Orchis installer succeeds on a later run, it now rewrites the icon-theme entries too (the `IconThemeName` XML property and the `gtk-icon-theme-name` keys, per file type) instead of only swapping old Papirus/Materia names - so a desktop that started on the fallback themes converges on the full designer set.

## [v4.15.5] - 2026-08-27

### 🐛 Fixed
- **The designer extras could never fully succeed - the two upstream installers were invoked with the wrong options, so the checked directories were never created (verified against the actual Orchis/Tela installer sources and a full local install run):**
  - **Orchis:** `--tweaks compact` only selects the no-floating-panel asset tweak and does not change the installed directory name - the install produced `Orchis-Dark` while the check looked for `Orchis-Dark-Compact`. The call now uses `-s compact` (the size variant that actually appends `-Compact` to the directory name) alongside the tweak: `./install.sh -d /usr/share/themes -c dark -s compact --tweaks compact` (same for light).
  - **Tela:** the installer's color argument selects the variant family, and no argument means "standard only" - the old call created `Tela`/`Tela-light`/`Tela-dark` but never `Tela-Black-Dark`. The script now runs both families: the standard set plus `./install.sh -d /usr/share/icons black`, each step skipped when its variant already exists.
  - Local proof run: the corrected Tela calls produce exactly `Tela`, `Tela-light`, `Tela-dark`, `Tela-black`, `Tela-black-light`, `Tela-black-dark` in dependency order; the Orchis name assembly (`name + color + size` in `core.sh`) confirms `Orchis-Dark-Compact`/`Orchis-Light-Compact` from the corrected flags.
- Together with v4.15.4 (auto-installed `sassc` + murrine, logged failures with inline log tails, git→tarball fetch fallback), the designer extras now complete end-to-end and - if anything still fails - say exactly what and why.

## [v4.15.4] - 2026-08-27

### 🐛 Fixed
- **Designer extras (Orchis / Tela) kept reporting "Designer theme ... unavailable" on every run with no cause shown.** Fixed in `config/container/umo-install-extras`:
  - The Orchis installer needs the SCSS compiler `sassc` and the murrine GTK2 engine, which the base container does not ship - the install failed silently every single time while its output was swallowed by `tail -n 3` + `|| true`. The script now auto-installs `sassc` + `gtk2-engines-murrine` before the first Orchis run (and warns with log lines if the install still cannot proceed).
  - **No more silent failures:** every fetch/install command logs to `/tmp/umo-install-extras.log`, and a failure prints the last 6 lines of that command's real output inline.
  - **New fetch fallback:** when `git clone` fails (mobile carriers sometimes block the git transport / codeload while github.com itself works - the FiraCode download succeeds on the same connection), the script retries with the master tarball over plain HTTPS via curl.
  - The FiraCode step no longer claims "Installed" when `unzip` silently failed - success is now verified against `fc-list`, and a missing curl/unzip is reported.
  - The final verdict names exactly what is missing (GTK theme, icons, or both) and prints the retry command (`umo login -c 'umo-install-extras dark'`).
- **Misleading "(Offline?)" warning in the theme module:** replaced with a per-component status ("Designer Extras Incomplete (GTK Theme + Icons Missing) - Config Targets ...") since the network can be fine while one component fails.

### 🎨 Changed
- The in-container extras installer follows the same Title Case message convention as the rest of the tool.

## [v4.15.3] - 2026-08-27

### 🎨 Changed
- **Title Case everywhere in the `umo update` / `umo refresh` output:** v4.15.1 unified the step headers ("Refreshing Host Scripts", "Upgrading The Ubuntu System...") in title case, but the status lines printed between them were still sentence case ("System packages upgraded", "3 new commits on main:", "finished with warnings"). Every ok/warn/info line the update flow prints is now title case too, across:
  - `bin/umo-cli` - the whole self-update / release-update / refresh / re-apply / upgrade / summary path ("Host Scripts Updated In ...", "N New Commits On Main:", "UMO Is Already Up To Date", "Release vX Installed", "System Packages Upgraded", "UMO Fully Updated (...)", the wrapper-refresh and xstartup lines...)
  - `lib/core-ansi.sh` - the "X Failed", "Last 30 Lines Of Log:" and "X Finished With Warnings (Code N)" lines every quiet/streamed run emits
  - `lib/core-fs.sh` + `lib/core-net.sh` - backup, patch, checksum and download messages ("Backup Created:", "SHA-256 Mismatch For...", "Downloaded File Invalid Or Corrupt, Trying Next Mirror")
  - the theme / apps / desktop / perf / systemctl / audio / proot / VNC modules - "Theme Packages Installed", "Designer Extras Applied", "VNC Configured", "Login Scripts Ready" and friends
  - technical tokens keep their real spelling: file names (`xstartup`, `install-vnc.sh`), paths, and copy-pasteable commands after "Run:"/"Fix With:" stay lowercase.
- **The "CLI Wrapper Updated" line also gets a clean path** (no more `home/../usr/bin` detour) and goes through the display-path shortener like the rest.

### ✨ Added
- **GitHub releases now carry the CHANGELOG content directly:** the release workflow extracts the `[vX.Y.Z]` section of `CHANGELOG.md` (same awk pattern as the Orbiscreen project) and publishes it as the release notes instead of the bare auto-generated compare link.

## [v4.15.2] - 2026-08-27

### 🐛 Fixed
- **`umo start` reported "VNC Failed To Start" on slow first boots:** the launcher waited a fixed 5 seconds and checked once for the X server, but a first boot after a fresh install (cold proot startup + pulseaudio + Xtigervnc) legitimately takes longer - so it declared failure while the starter was still working. It now polls up to 90 seconds for the X server to appear and stops early when the starter process exits.
- **Misleading empty-log message:** the failure panel claimed "the starter was killed before it could run" whenever the log was empty. It now distinguishes the real cases: starter still running but no X server in time, vs. starter exited with no output (the Android 12+ phantom-process-killer case, with the one-time adb fix pointed out).
- **In-container VNC starter printed nothing until success or error**, so the host log stayed empty during every slow boot; it now announces "Starting UMO VNC Server..." before the pre-flight cleanup, keeping the log useful for diagnosis.

### 🎨 Changed
- **Short host paths in every user-facing message:** the Termux base prefix (`/data/data/com.termux/files`) is no longer displayed - `Path: /home/umo-ubuntu` instead of `Path: /data/data/com.termux/files/home/umo-ubuntu`. Applied across the installation summary, `umo status` (Scripts path), `umo start` (failure log path), the uninstall list + progress lines, `umo backup`, `umo refresh` messages, the "UMO not installed" host-wrapper errors and the installer's missing-binary error - via a new `umo_fs_display_path()` helper in `core-fs.sh` and matching `_umo_dp()` helpers in the standalone scripts. Paths inside copy-pasteable commands (git stash pop, manual removal hints) stay absolute.

### 🧹 Cleanup
- The uninstall confirmation's `umo` command path is built without the `home/../usr` detour, and the legacy host-scripts list prints one entry per file with shortened paths.

## [v4.15.1] - 2026-08-27

### 🎨 Changed
- **One unified output language across every surface:** the session scripts (`umo-start`/`umo-stop`), the CLI, the generated host wrappers (login / start / VNC start / VNC stop), the container helpers (`umo-startvnc`, `umo-install-extras`), the release installer (`umo.sh`) and the repo entry (`install.sh`) all print the same `▌` run marks, `✔`/`✖`/`⚠`/`ℹ` glyphs and the shared orange/green/red/cyan/yellow palette - the last `[OK]`/`[ERR]`/`[..]`-style echo lines are gone from the whole project.
- **NO_COLOR + TTY-aware colors everywhere:** every standalone entry point blanks its palette when `NO_COLOR` is set or stdout is not a TTY, so piped and logged output stays plain; `core-ansi` also blanks the shared `NC/BOLD/DIM` + brand color variables whenever color support resolves to zero.
- **UTF-8 glyph detection with a locale fallback:** glyph support is detected from `LANG/LC_ALL/LC_CTYPE` and falls back to `locale charmap` when those are unset - a Termux session without an explicit `LANG` still gets the Unicode marks, non-UTF-8 terminals get a clean ASCII fallback (`OK`/`ERR`/`!`/`|`), consistently from the release installer down to the in-container logs.
- **The release installer (`umo.sh`) output is modernized:** every `[OK]/[ERR]/[..]` echo is replaced with styled `✔`/`✖`/`▌`/`ℹ` lines using self-contained color + glyph detection (no library dependency before anything is installed), and "UMO Release Installer" now uses the same `▌` step mark as the rest of the tool.
- **CLI vocabulary:** the unused `_umo_info` is replaced by a new `_umo_run` in-progress line (orange `▌`), `_umo_kv` labels now use a width-20 colon format matching the installer summaries, and step messages use consistent title case ("Refreshing Host Scripts", "Installing Dependencies"...) - the container helpers follow the same capitalization.

### ✨ Added
- **`umo_log_run()` in `core-ansi`:** a shared in-progress line (step `▌` block without the leading newline) used by the desktop and VNC installers for their "Installing ..." runs.

### 🐛 Fixed
- **Literal `\033[0m` printed after "UMO VNC Server Active":** in `config/container/umo-startvnc` the reset code was passed to a `%s` printf slot, which never interprets escapes - the raw text ended up on screen. It is now passed via `%b` like every other code.
- **`install.sh` cleared the screen even when piped:** the screen-clear escape burst was emitted unconditionally, polluting logs and the error path; it now runs only on a real TTY.
- **Hard errors in the container VNC helper were named `_warn`** while printing a red `✖` - renamed to `_err` so the function name, color and severity agree.
- **SECURITY.md version badge synced:** it was left on 4.14.2 (missed in the v4.15.0 docs pass) and now tracks the release again.

### 🧹 Cleanup
- **Full-project audit pass:** `sh -n` + shellcheck clean across all 27 scripts, every function call cross-checked against its definition across lib/module/CLI boundaries, every `{{...}}` template placeholder verified against its renderer, and every error path (missing install dir, missing installer, non-Termux host, `refresh` outside an install) behavior-tested. Dead vocabulary removed with the change (`_umo_info`/`_G_INFO` in the CLI, the unused `_UMO_DIM` in `bin/umo-stop`).

## [v4.15.0] - 2026-08-26

### ✨ Added
- **Day/Night theme choice in the installer:** a new "Choose Theme Mode" menu picks **Night Mode** (Orchis-Dark-Compact + Tela-Black-Dark) or **Day Mode** (Orchis-Light-Compact + Tela); the whole design system (GTK, xfwm4, icons, terminal) is rendered from that choice. `--mode=dark|light` is a new alias for `--theme`, and `dark`/`light`/`day`/`night` values are accepted.
- **Saved install settings (`~/.umo/umo.conf`):** the installer now records the chosen Ubuntu version, DE, app set, theme mode, perf mode and install dir; `umo --user` keeps it current. Legacy installs get their settings detected from the existing container (xstartup DE, xsettings theme) and the conf is written on the first update.
- **A themed Fastfetch config matching the reference screenshot:** the builtin Ubuntu logo, the exact module sections (OS, Host, Kernel, Uptime, Packages, Shell, Display, DE, WM, WM Theme, Theme, Icons, Font, Terminal, Terminal Font, CPU, GPU, Memory, Swap, Disk, Locale, colors) and orange UMO keys - deployed system-wide (`/etc/xdg/fastfetch`) plus per-user, so `fastfetch` inside the container looks like the reference out of the box.
- **Application sets per category are now complete:** Basic (utilities + editor + image viewer + archiver + Firefox + Fastfetch), Developer (Python/Node/GCC toolchain + vim/tmux/ssh/sqlite), Media (VLC/FFmpeg/mpv/Audacity/GIMP), Office (LibreOffice Writer/Calc/Impress + atril), Browser, and Full Suite - and the installer menu now offers all six categories instead of four.
- **`umo refresh` command:** re-renders the `umo` CLI wrapper, host scripts and container scripts from the local tool copy without touching git - the same tooling `umo update` uses, exposed for instant local repair. `umo-install --refresh` now delegates to it.

### 🎨 Changed
- **`umo update` is now a complete update system:** after pulling the new version it re-renders the CLI wrapper, refreshes host + container scripts, then **re-applies the saved settings** (theme re-rendered for the saved mode, designer extras verified, chosen app category reinstalled idempotently, desktop components verified and self-installed if missing) and finally upgrades the entire Ubuntu system - nothing is skipped because it already exists. `--scripts-only` keeps the old fast behavior.
- **The `umo` CLI now uses the unified v4.14 design language:** the wrapper was extracted from a giant heredoc into `bin/umo-cli` and every command (status, update, backup, uninstall, help...) now prints the same `▌` steps, `✔`/`✖`/`⚠`/`ℹ` marks, orange rules and panels as `umo-install` - and `umo update` re-renders the wrapper itself so the style can never go stale again. `umo start` also self-heals an outdated wrapper on launch.
- **Theme matches the reference design exactly:** UI font is **Ubuntu SemiBold 10**, monospace is **FiraCode Nerd Font Mono 9**, the xfce4-terminal font is **FiraCode Nerd Font Mono Bold 9**, the XFCE window-manager theme now follows the selected GTK theme (it was hardcoded to Greybird-dark), and the Ubuntu font family ships in the theme packages. LXDE/Openbox templates render the same fonts.
- **Every source file now carries a documented header in the project style** (`UMO - <role> (GPL-3.0-or-later)` + repository link): all installer/CLI/lib/module scripts, container helpers, rendered templates (sh, conf, XML, JSONC), theme configs and entry points are identified on sight, matching the documentation convention used across the project family.

### 🐛 Fixed
- **Light mode never got the designer theme:** extras (Orchis/Tela/FiraCode) were skipped entirely for `umo-light`; they now run for both modes, install BOTH Orchis compact variants plus the Tela set, and the session-start self-heal reads the container's theme-mode marker (`/etc/umo/umo-theme-mode`) so light installs stop re-pulling the dark theme on every start.
- **`umo-install --refresh` called functions that moved out with the CLI wrapper** and crashed with "command not found". It now renders `bin/umo-cli` and delegates to the new `umo refresh` command, so install/update/refresh share one code path.
- **`umo update` settings re-apply sourced the theme/apps modules without the shared libs**, so `umo_log_step` / `umo_fs_render` were undefined mid-run. The update flow now loads `core-ansi.sh` + `core-fs.sh` first and guards against a missing tool tree.
- **Desktop self-heal during update now matches the installed DE** (LXDE/Openbox/minimal get their own package sets instead of always installing XFCE, and the XFCE repair set matches the installer exactly), and the saved Ubuntu version for legacy installs is detected from the container's `os-release` rather than assumed 22.04.
- **Fast repeat updates:** `umo update` now probes the container before re-applying settings - when the designer theme (GTK + icons + Nerd fonts) and the chosen application set are already installed, the minutes-long apt re-runs are skipped and only verified, while anything missing still triggers the full self-heal.
- **`umo update` no longer endangers local git changes:** the auto-stash includes untracked files (`stash push -u`), only pops a stash it actually created (verified via `refs/stash` before/after), and the update aborts instead of `reset --hard` when stashing fails (e.g. git identity not configured).
- **Release install survives interruptions:** the tarball swap rolls back to the previous version if the new tree is invalid, and a tool directory left missing by an interrupted update is restored from its `.old` backup on the next run.
- **The `umo` wrapper is rendered atomically everywhere** (`.new` + non-empty check + `mv`, with `mktemp` for the refresh wrapper) so a failed render can never clobber a working CLI, and all placeholder substitutions are sed-escaped against `&`/`\`/`|`/`"` in paths.
- **`umo --user` records detected settings** (DE/theme/apps/Ubuntu version) instead of stamping defaults into `umo.conf` on legacy installs, and the aliases hook in `.bashrc`/`.zshrc` now points at the actual aliases file location.
- **Designer extras install is interruption-tolerant:** an incomplete Orchis/Tela install keeps its cloned repo, so the next run installs only the missing variants from the local copy instead of re-cloning and retrying from scratch.
- **`umo update` reports real upgrade results:** after the system upgrade it checks `dpkg --audit` + `apt-get check` inside the container and warns with a repair command instead of always claiming success.

## [v4.14.2] - 2026-08-24

### 🎨 Changed
- **One unified terminal design language across install, update and session flows:** every in-container message now uses the same UMO vocabulary as the installer (`›` steps, `✔` success, `✖` failure, `⚠` warnings, `▌` notes, orange `─` rules) instead of each script inventing its own `[..]`/`[OK]`/`====` styles. The VNC server banner matches the `umo start` panel, and long apt runs stream through a single progress filter that keeps moving lines (downloads/unpacking/setup) indented under their step while hiding static headers.

## [v4.14.1] - 2026-08-24

### 🐛 Fixed
- **VNC still died instantly with an EMPTY log after fresh installs:** the v4.13.3 single-supervisor check skipped descendants but still SIGKILLed ANCESTORS - `pgrep -f umo-startvnc` matches the nohup wrapper, proot and the container bash (all carry the string in argv), and killing proot destroys the entire traced tree before the script prints anything. The check now walks upward from the script's own PID: any candidate found in that ancestry chain is spared; only genuinely foreign supervisors are killed. Verified with real parent/foreign process tests.
- `umo start` failure screen now says "(no output captured...)" when the starter was killed before producing any log output, instead of a silently empty section.

## [v4.14.0] - 2026-08-24

### ✨ Added
- **`umo update` now upgrades the entire Ubuntu system:** after the script refresh, the container runs `apt-get update` + full `upgrade` + `full-upgrade` + `autoremove`, streamed live so progress is always visible. Long-installation progress streaming remains part of the installer phases (desktop/theme/extras) where those installs belong.

## [v4.13.3] - 2026-08-24

### 🐛 Fixed
- **VNC died instantly with an empty log on fresh installs:** the single-supervisor check killed every process whose command line contained "umo-startvnc" with SIGKILL - which matched the script's own ancestor chain (nohup wrapper, proot, container bash). Killing the proot ancestor destroys the whole traced tree, so the script died before printing anything (empty "Last log lines"). The check now walks `/proc` ancestry and only kills genuinely foreign supervisors.
- **Long installs no longer look frozen:** the desktop, VNC and theme apt runs stream their full output (downloads, unpacking, setup) instead of filtering it into silence; the designer-extras script announces every stage (fetch/install Orchis, Tela, font) and only suppresses the font-cache noise.

## [v4.13.2] - 2026-08-24

### 🔧 Changed
- **Clean separation of update vs install:** `umo update` is now a fast scripts-only operation (deploys helper scripts, re-renders xstartup, applies silent hooks) and no longer installs desktop packages or designer themes - those belong to `umo install` / fresh installs, with the session-start self-heal still covering both automatically.

### 🧹 Cleanup
- Full-project audit pass: removed the now-dead `_umo_de_footer`, a stray version comment in xstartup, and an `A && B || C` lint pattern; shellcheck, sh -n, xmllint, CLI heredoc, secrets, comment policy and dead-code matrix all clean.

## [v4.13.1] - 2026-08-24

### 🐛 Fixed
- **Designer extras never installed on existing containers:** Orchis/Tela/FiraCode only ran during the theme phase of a FULL install, so updated containers kept the old Materia look. The extras installer now lives in `config/container/umo-install-extras` and is deployed with every `umo update`, executed automatically by the update flow when Orchis is missing, AND self-healed at session start - with the theme config swap (Materia-dark→Orchis-Dark-Compact, Papirus-Dark→Tela-Black-Dark) applied to existing user configs.

### ✨ Added
- **Plank dock** (the bottom icon dock from the reference design): auto-installed at session start when available and launched by xstartup.

## [v4.13.0] - 2026-08-24

### 🐛 Fixed
- **Wallpaper fell back to distro default:** xfdesktop resolves backdrops per monitor name and distro defaults won whenever our user config missed the active monitor. Our desktop XML is now installed as SYSTEM-wide xfconf defaults (`/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/`), every distro backdrop image in `/usr/share/xfce4/backdrops/` is overwritten with the UMO wallpaper, and per-user/desktop-init behavior is unchanged.

### 🎨 Changed
- Dark theme now matches the designer reference: **Orchis-Dark-Compact** (GTK), **Tela-Black-Dark** (icons), **FiraCode Nerd Font Mono** (terminal/monospace). Orchis + Tela install from their upstream repos during the theme phase (best-effort; offline falls back to Materia-dark + Papirus-Dark); FiraCode Nerd Mono ships via the nerd-fonts release zip with `unzip` added to theme packages.

## [v4.12.1] - 2026-08-24

### 🐛 Fixed
- **ROOT CAUSE of every empty-desktop install: wrong package name.** The XFCE set referenced `xfdesktop`, which does not exist in Ubuntu (the package is `xfdesktop4`) - and apt aborts the ENTIRE command when any named package is missing. Since v4.9.1 this single bad name instantly killed the whole desktop apt run on every fresh install (panel, session and window manager were in the same command), producing the silent empty desktop while everything else installed fine. All install lists now use `xfdesktop4`.
- **Removed debug clutter from the install/session output:** the per-pass "Desktop install pass N/3", component-probe and panel-warning lines are gone; the retry logic stays but runs quietly, and the real apt errors still print only on genuine failure.

## [v4.12.0] - 2026-08-24

### 🐛 Fixed
- **Desktop install is now self-verifying inside the installer itself:** the generated `install-de.sh` refreshes package lists first, then runs the desktop apt install in up to 3 passes (each pass re-checks its core component and stops as soon as it exists), and on final failure prints the unfiltered `/var/log/apt/term.log` errors directly instead of dying quietly behind `|| true`.
- **Installer-level safety net:** `umo_phase_finalize` now verifies the DE core component (`startxfce4`/`startlxde`/`openbox-session`/`xterm`) before finishing; if the desktop phase silently failed earlier, finalize retries the whole desktop install automatically.

### ✨ Added
- `umo install` subcommand (v4.11.0) + session-start auto-heal (v4.11.2) + installer retry/safety-net (this release) form three independent layers so a missing desktop can no longer survive silently.

## [v4.11.2] - 2026-08-24

### 🐛 Fixed
- **Zero-manual-action desktop healing:** if the XFCE components are missing at session start (the state every install on some devices kept producing), the VNC start script itself now runs `apt-get update` + installs the full desktop set automatically BEFORE launching the session - streamed live into the same terminal as `umo start` - and only then starts the desktop. A broken container repairs itself on the first `umo start`; nothing manual, no reinstall needed. If automatic installation still fails, the unfiltered apt errors are printed directly.

## [v4.11.1] - 2026-08-24

### 📖 Diagnostics
- **DE install evidence is no longer destroyed:** the generated `install-de.sh` was deleted after every run and its output discarded, making repeated empty-desktop installs undiagnosable. The full run output is now kept at `/root/install-de.log`, the script itself preserved as `/root/install-de.last.sh` (with its real exit code via `PIPESTATUS`), and when the post-install probe finds the core component missing it prints the tails of both the run log and apt's own `/var/log/apt/term.log` (which holds the unfiltered dpkg/apt errors) alongside the repair command.

## [v4.11.0] - 2026-08-24

### ✨ Added
- **`umo install`:** re-runs the full installer from the installed tree (`umo install`, extra installer flags pass through, e.g. `umo install --de=xfce4`). The recommended repair path for existing installs whose wrapper predates newer update-flow logic; fresh one-liner installs remain the canonical path: `bash <(curl -fsSL https://raw.githubusercontent.com/shadow-x78/ubuntu-modded-optimized/main/umo.sh)`.
- `umo --help` now lists `install` under Maintenance.

## [v4.10.6] - 2026-08-24

### 🐛 Fixed
- **Empty desktop self-heal:** the component probe confirmed existing containers can lack the ENTIRE XFCE set (startxfce4/xfwm4/panel/xfdesktop all missing). `umo update` now detects the missing desktop launcher and installs the full XFCE core set in-container as a visible streamed step (up to 30 min, progress echoed, success/failure stated explicitly) instead of only patching two individual packages.

## [v4.10.5] - 2026-08-24

### 🐛 Fixed
- **"Cannot establish any listening sockets - server already running":** repeated `umo start` invocations spawned competing VNC supervisors that kept killing and re-spawning each other's servers, so every new Xtigervnc lost the bind race against a live predecessor and exited instantly (black screen with cursor). The start script now enforces a single supervisor (kills older instances of itself), shuts down old servers with escalating TERM→KILL rounds and verifies they are gone, detects the "already running" bind failure specifically, cleans up and retries once instead of counting it as a crash.

## [v4.10.4] - 2026-08-24

### 📖 Changed
- One-liner install command switched from `curl … | bash` to `bash <(curl -fsSL …)` across both READMEs, install docs and SECURITY.md.

### 📖 Diagnostics
- The VNC supervisor now logs a component availability line (startxfce4 / dbus-launch / xfwm4 / panel / xfdesktop / xset + machine-id files) into `~/.umo/logs/vnc-start.log` 12 s after every session start, so a black desktop immediately names its own missing pieces.

## [v4.10.3] - 2026-08-23

### 🐛 Fixed
- **Desktop installs time out on slow devices (the recurring empty-desktop cause):** the XFCE/LXDE/Openbox apt runs were capped at 600 s - a ~300-package install through proot regularly exceeds that, apt gets killed mid-run, and the old "repair" then force-removed every half-installed package, leaving a silent empty desktop on fresh installs while small sets (VNC deps) succeeded. DE timeouts are now 1800 s.
- **Repair no longer destroys half-installed desktops:** `_um_apt_repair` now tries configure → `apt-get -f` → configure first, then reinstalls broken packages by name, and only force-removes as an absolute last resort (applied to both the desktop and VNC repair bodies).
- **PulseAudio exited after ~20 s of silence:** Termux PulseAudio defaults to `--exit-idle-time=20`, so audio showed "stopped" minutes after start and containers had nothing to connect to. Every launch site (`umo start`, both VNC host wrappers) now uses `--exit-idle-time=-1`.

## [v4.10.2] - 2026-08-23

### 🐛 Fixed
- **Desktop installs could fail silently, leaving an empty desktop:** the DE installer tolerated any apt error and never verified the result - a fresh install with only 295 packages shipped no `startxfce4`, no panel and a permanently black VNC screen while claiming success. Each DE install now verifies its core component (`startxfce4` / `startlxde` / `openbox-session` / `xterm`) inside the container and prints a CRITICAL banner with the exact repair command when missing.
- **Silent audio failure on start:** `umo start` now checks that the Termux-side PulseAudio daemon is actually alive after `pulseaudio --start` and prints the fix command when it is not.

## [v4.10.1] - 2026-08-23

### 🐛 Fixed
- **Wallpaper timing race:** `umo-desktop-init` now waits up to 20 s for `xfconfd` to accept queries before applying the backdrop (it previously fired once at ~4 s, before xfconfd was necessarily ready in slow proot sessions).

### 📖 Diagnostics
- **Desktop-death visibility:** the VNC supervisor now checks for a panel process 12 s after session start and, whenever the desktop session dies, dumps the last lines of `session.log` straight into `~/.umo/logs/vnc-start.log` - so `umo start` output alone reveals which XFCE component is crashing and why.

## [v4.10.0] - 2026-08-23

### 🐛 Fixed
- **`user: "$UMO_USER"` garbage in update output:** the current-user extractor captured the shell variable form `"$UMO_USER"` (quotes included) from `umo-user.sh` and fed it back into re-renders. Extraction now strips quotes and falls back to `umo` for variable/placeholder forms; the template also uses an unquoted variable so it can never be misparsed again.
- **Silent deployment failures masked as success:** helper-script copies and xstartup renders used `|| true` fire-and-forget writes - a failed deploy looked identical to a successful one (the exact reason stale xstartup survived "successful" updates). Deployment is now atomic (tmp + mv) with explicit per-file `deployed:` / `FAILED:` lines, and every rendered xstartup is verified to contain the new-format marker (`XDG_RUNTIME_DIR`) before being reported as updated.
- **xstartup now created even when absent** (previously skipped), so containers missing it get the full modern session file on first refresh.

## [v4.9.9] - 2026-08-23

### 🐛 Fixed
- **Black desktop, cursor-only (old containers):** `xset` was missing because `x11-xserver-utils` was never in the VNC dependency list; xstartup now guards every optional tool, exports `XDG_RUNTIME_DIR` (required by xfce4-session/dbus and previously missing from the main template), and falls back gracefully.
- **Session resilience:** if the full DE launcher is unavailable, xstartup assembles whatever exists manually (xfdesktop + panel + wm + terminal) and keeps the session alive with `tail -f /dev/null`, so partial installs still render something instead of a bare black root window.

### 🔧 Changed
- `x11-xserver-utils` added to the VNC install set for fresh installs; the `umo update` in-container hook now installs both `xfdesktop` and `x11-xserver-utils` when missing on existing ones.

## [v4.9.8] - 2026-08-23

### 🐛 Fixed
- **Black screen with a movable cursor:** the generated X cookie did not match how local clients resolve the display, so `startxfce4` (and every X client) failed to connect and only the server-side cursor remained. Since the server is hardcoded to `127.0.0.1` and protected by VncAuth, internal X auth is now disabled entirely: no `-auth`, no cookie generation, clients connect freely on the loopback-only socket.

### ✨ Added
- **`umo update` auto-installs `xfdesktop`:** existing containers predate the v4.9.1 package-set fix, so the desktop renderer was missing; the in-container hook now detects its absence and installs it (non-interactive, 300s cap), restoring wallpaper/icons without a reinstall.

## [v4.9.7] - 2026-08-23

### 🐛 Fixed
- **Full-project audit (v4.9.1-v4.9.6 delta):** `umo update`'s new in-container deployment referenced `UMO_INSTALL_DIR`, which is undefined in the `umo` wrapper context - the helper-script deploy would have silently done nothing on a real update. The install directory is now derived from `umo-login.sh` (same pattern as host refresh), with a clear warning if it cannot be found.

### ✨ Added
- **`umo-install --refresh`:** safe one-command tool refresh that redeploys ALL updated pieces (host scripts, aliases, in-container VNC helpers, xstartup) without touching the rootfs or running any install phase. This is also the bridge for existing installs whose `umo` wrapper was generated by an older release: run it once against the updated tree and every fix applies immediately:
  ```bash
  sh ~/.local/share/umo/bin/umo-install --refresh
  ```

### 📖 Audit
- Re-ran the full audit suite over the v4.9.1-v4.9.6 delta: 147 functions all live, no unused files, zero stray comments in code, config headers intact, no stale UMO_VNC_PUBLIC/localhost references, secrets clean, XML valid, CLI heredoc parses.

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
- **APT config typo fixed:** five `DPKg::`/mixed-case directives in `99-umo-sandbox` corrected to `DPkg::` - they were silently ignored by apt before.

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
- **`umo uninstall`:** full removal - Ubuntu rootfs, `~/.umo` host scripts/cache/logs, the `umo` command in `$PREFIX/usr/bin`, and the aliases block in `.bashrc`/`.zshrc`. Shows exactly what will be removed and asks for confirmation (`UMO_UNINSTALL_YES=1` skips the prompt). `umo-uninstall` is also listed in `umo --help`.
- **Host aliases file:** the installer writes `~/.umo/aliases.sh` (`umo-start`, `umo-stop`, `umo-startvnc`, `umo-stopvnc`, `umo-login`, `umo-user`) and sources it from `.bashrc`/`.zshrc`, so the shell exposes plain commands instead of loose files.
- **`umo run` / `umo backup` documented** in both READMEs' command tables.

### 🔧 Changed
- **Clean Termux home:** all host-side scripts (`umo-login.sh`, `umo-user.sh`, `umo-start.sh`, `umo-stop.sh`, `umo-vnc-start.sh`, `umo-vnc-stop.sh`, `aliases.sh`) now live in `~/.umo/` instead of `$HOME`. Legacy home copies are removed automatically on install and by `umo update`. The `umo` CLI, session controllers (`umo start/stop/vnc/login/user`) and all modules locate scripts in `~/.umo/` with a fallback to `$HOME` for pre-4.7 installs.
- **Rename `get.sh` → `bash.sh`:** the one-liner release installer is now fetched from `main/bash.sh` (`curl ... main/bash.sh | bash`); READMEs, INSTALL docs, SECURITY.md, CI, release workflow and the tarball contents all follow.
- **Finalizing phase can no longer hang:** every in-container finalize step (`apt-get install sudo`, `dpkg --configure -a`, `usermod`, service restore, VNC password) now runs with `DEBIAN_FRONTEND=noninteractive`, stdin from `/dev/null`, and a hard `timeout` (120 to 900s per step), so a stuck dpkg/proot session is killed instead of spinning forever.
- **Installer config is exported before modules load:** `--dir=`, `--de=`, `--apps=`, `--perf=`, `--theme=` now propagate reliably to every module (they were previously read by modules before CLI parsing could override them).
- **`umo-login.sh` audio socket detection** now also checks `$PREFIX/tmp/pulse-<uid>/native` (Termux's default socket location) in addition to `$PREFIX/root/...`.

### 🐛 Fixed
- **Finalizing spinner hang:** `Installing dependencies...` / `Configuring packages...` could spin forever waiting on interactive dpkg prompts inside proot; all such calls are now timed and non-interactive.
- **`umo user`/`umo vnc` resilience:** subcommands fall back to the legacy `$HOME` locations when `~/.umo` scripts are missing (pre-4.7 installs keep working until reinstalled).

## [v4.6.0] - 2026-08-16

### ✨ Added
- **Full Desktop Design System:** Every graphical desktop now gets a complete bespoke theme, built exclusively from packages available in the official Ubuntu repositories - Materia GTK theme, Papirus icons, DMZ cursors, Inter + JetBrains Mono fonts, and the UMO wallpaper.
- **Real Light Mode:** `--theme=umo-light` is now a genuine light theme (Materia-light + Papirus-Light) with per-DE panel and wallpaper colors; `umo-dark` remains the default.
- **LXDE Design:** Themed `lxpanel` bottom panel (menu, launchers, taskbar, tray, clock), `lxsession` desktop config, and `pcmanfm` wallpaper - applied to both root and the `umo` user.
- **Openbox Design:** `rc.xml` with Clearlooks windows and Inter titlebar fonts, a custom tint2 panel (launcher/taskbar/clock), a generated root menu, and `feh` wallpaper via autostart.
- **One-Liner Installer:** `curl -fsSL https://raw.githubusercontent.com/shadow-x78/ubuntu-modded-optimized/main/get.sh | sh` - downloads the latest GitHub release, verifies its SHA-256 checksum, installs to `~/.local/share/umo`, and launches the installer (interactive or `--no-gui`).
- **Release-Based Updates:** `umo update` now auto-detects the install mode - git-clone installs keep the existing fetch/reset flow, release installs download the newest tagged tarball with SHA-256 verification and swap the install atomically.
- `get.sh` is shipped inside every release tarball and passes all checks (shellcheck + `sh -n`) in CI.

### 🐛 Fixed
- **Broken GTK Theme:** configs referenced `Orchis-Dark` + `Bibata-Modern-Ice`, which were never installed (not available via apt) - everything silently fell back to GTK defaults. All configs now use apt-installable packages that are actually installed.
- **Theme Not Applied to Default User:** XFCE panel/window-manager/desktop configs were written only under root's home; they are now applied to both root and the `umo` user for every DE.
- **Dead Theme Mode:** `--theme=umo-light` previously applied the exact same files as `umo-dark` with no visual difference.
- **xstartup Fallback:** the VNC session fallback ended with `exec twm`, which is not installed anywhere - replaced with `exec xterm`.
- **Docs Inaccuracies:** install docs showed a wrong VNC password and missing `umo start` step; both READMEs' theme descriptions now match reality.
- **Installer Aborts Mid-VNC (`set -e` kills):** the installer exited entirely at the very start of the VNC phase. Root cause: `umo_log_debug` was written as `[ test ] && printf ...` and returned exit code 1 when `UMO_DEBUG` was unset, which under `set -e` terminated the whole installer. Rewritten as `if`/`return 0`.
- **Fatal `cmd; _rc=$?` pattern under `set -e`:** the desktop, apps, theme and download paths captured exit codes with an unguarded trailing `$?`; any non-zero return aborted the installer before the capture. All converted to `cmd || _rc=$?`.
- **`umo_run_quiet` destroyed the global cleanup trap:** it set and later cleared `trap - EXIT INT TERM`, silently disabling the installer's proot/apt/dpkg cleanup after the first spinner run. It now saves and restores the previous INT/TERM traps and never touches EXIT.
- **Hard `umo_die` in filesystem helpers:** `umo_fs_mkdir`, `umo_fs_write`, `umo_fs_render` and `umo_fs_patch` called `umo_die` (un-catchable `exit 1`) on any write failure; they now log a warning and return an error code, letting the install continue.
- **xstartup fallback rewritten:** the VNC session startup now falls back to a complete script (dbus-launch if available, then xfce4 → lxde → openbox → xterm → keep-alive shell) when `config/xstartup` is missing, and sets `XDG_RUNTIME_DIR`; `chmod +x` and user copies are guarded.
- **VNC phase made non-fatal:** `umo_vnc_install` no longer returns 1 when `umo-login.sh` is absent; every VNC step degrades to a warning (missing template, missing `/usr/local/bin`, `vncpasswd` unavailable) and the phase always completes, matching the other phases.
- **Proot prepare touched the HOST `/usr/sbin`:** the `invoke-rc.d`/`service`/`systemctl` divert loop used absolute `/usr/sbin` paths - a no-op on Termux but would corrupt a GNU/Linux host's service binaries if ever run as root; it now operates on `$UMO_PROOT_DIR/usr/sbin` and is fully guarded.
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
- **Unused Config Files:** `config/sources.list` and `config/bashrc.patch` deleted - no script consumed them; both contents are generated inline at install time.
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
