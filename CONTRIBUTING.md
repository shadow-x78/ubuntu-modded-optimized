# Contributing to UMO

Contributions to UMO are welcome. This document describes the development workflow.

## 🌿 Day-to-Day Work

- **Branches:** `feature/`, `fix/`, `docs/`, `chore/` prefixes (e.g. `feature/lxqt-support`), branched from `main`.
- **Commits:** `umo | <type>: <description>` for work, `umo | vX.Y.Z | <type>: <description>` for release commits. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- **Style:** POSIX `sh` - no bashisms. Every script must pass `sh -n`; run `shellcheck -s sh` before committing (no new warnings). Headers follow the UMO style:

```sh
#!/bin/sh
# UMO - <module name> (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized
```

- **Pull requests:** from a fork, targeting `main`, with `sh -n` + `shellcheck` clean, a `CHANGELOG.md` entry, and the PR template checklist filled in.

## 🚀 Release Process (maintainers)

A release is ONE commit containing the pending work plus the version bump:

1. Bump `UMO_VERSION` in **all five version homes** so nothing can disagree with the tag:
   - `bin/umo-install` (the source of truth - the release workflow verifies it against the pushed tag)
   - the `UMO_VERSION:-` fallback in `lib/core-ansi.sh` (the banner tag line)
   - the version badges in `README.md`, `README_AR.md` (`version-X.Y.Z` / `الإصدار-X.Y.Z`)
   - the badge lines in `docs/INSTALL.md`, `docs/INSTALL_AR.md`, `docs/TROUBLESHOOTING.md`,
     `docs/TROUBLESHOOTING_AR.md` and `SECURITY.md`
2. Rotate the pending `CHANGELOG.md` entry into a `## [X.Y.Z] - <date>` block dated today
   (the release notes are extracted from this heading by the workflow).
3. Pick the bump by CHANGELOG convention: `✨ Added` work = minor (`4.17.0`), `🐛 Fixed`/
   `🎨 Changed` only = patch (`4.17.1`).
4. Commit everything as one release commit and tag it:

```bash
git add -A
git commit -m "umo | vX.Y.Z | <type>: one-line summary of the release"
git tag -a vX.Y.Z -m "vX.Y.Z - <one-line summary>"
```

Then push the result:

```bash
git push origin main vX.Y.Z
```

The tag push triggers the [release workflow](.github/workflows/release.yml), which
verifies the version against the tag, runs syntax checks, and attaches a tarball +
SHA256 checksum to the GitHub release.

## 🎨 Brand Assets (when touching visuals)

The UMO mark has one geometry with three renderings - keep them in sync:

- `assets/logo/umo-logo.svg` + the PNG set (repository header, READMEs)
- `config/theme/icons/umo.svg` + `umo-*.png` (the desktop menu button / hicolor)
- the terminal banner art in `lib/core-ansi.sh` and the five inline banner sites
  (`bin/umo-start`, `bin/umo-stop`, `bin/umo-cli`, `modules/umo-proot.sh`)

Every art line must be **exactly the same width** (22 chars in the current set,
leading spaces preserved) - the lib banner centers the whole block, and any
ragged line shears the circle. Verify both modes after editing: UTF-8
(half-blocks) and `UMO_ASCII=1` (pure `#`).

---

<div align="center">

Built by <a href="https://github.com/shadow-x78">shadow-x78</a> ·
[Back to README](README.md)

<sub>&copy; 2026 shadow-x78 · Ubuntu Modded Optimized (UMO)</sub>

</div>
