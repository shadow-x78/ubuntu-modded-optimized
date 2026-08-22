# Contributing to UMO

Contributions to UMO are welcome. This document describes the development workflow.

## 🌿 Branch Naming

Use the following prefixes for branches:

- `feature/` - new features
- `fix/` - bug fixes
- `docs/` - documentation changes
- `chore/` - maintenance tasks

Example: `feature/lxqt-support`

## 💬 Commit Convention

Commit messages follow this format:

```text
umo | <type>: <description>
umo | vX.Y.Z | <type>: <description>
```

- `<type>` is one of `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- `vX.Y.Z` is the current version. Release commits use it.
- A release ships as ONE commit: the pending feature work plus the version bump,
  tagged `vX.Y.Z` (there is no separate `release:` bump commit).

Example: `umo | v4.0.9 | fix: correct dpkg lock cleanup on exit trap`

## 💅 Code Style

UMO is written in **POSIX sh** - no bashisms.

- Every shell script must pass `sh -n` (syntax check).
- Run `shellcheck -s sh` before committing; no new warnings allowed.
- File headers follow the UMO style:

```sh
#!/bin/sh
# UMO - <module name> (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized
```

## ✅ Pull Requests

1. Fork the repo and create a branch from `main`.
2. Make sure `sh -n` and `shellcheck` pass on all changed scripts.
3. Describe your change in `CHANGELOG.md` (rotated into a versioned block at release time).
4. Fill in the PR template checklist.
5. Target the `main` branch.

## 🚀 Release Process (maintainers)

A release is ONE commit containing the pending work plus the version bump:

1. Bump `UMO_VERSION` in `bin/umo-install` and the `UMO_VERSION:-` defaults in
   `lib/core-ansi.sh` and `modules/umo-vnc.sh`.
2. Rotate the version badges in `README.md`, `README_AR.md` and `SECURITY.md`
   (`version-X.Y.Z` / `الإصدار-X.Y.Z`).
3. Move the `CHANGELOG.md` `[Unreleased]` section into a `## [X.Y.Z]` block dated today.
4. Commit everything as one release commit and tag it:

```bash
git add -A
git commit -m "umo | vX.Y.Z | feat: one-line summary of the release"
git tag -a vX.Y.Z -m "umo vX.Y.Z"
```

Then push the result:

```bash
git push origin main --follow-tags
```

The tag push triggers the [release workflow](.github/workflows/release.yml), which
verifies the version, runs syntax checks, and attaches a tarball + SHA256 checksum
to the GitHub release.

---

<div align="center">

Built by <a href="https://github.com/shadow-x78">shadow-x78</a> ·
[Back to README](README.md)

<sub>&copy; 2026 shadow-x78 · Ubuntu Modded Optimized (UMO)</sub>

</div>
