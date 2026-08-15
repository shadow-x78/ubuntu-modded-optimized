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
UMO | <type>: <description>
UMO | vX.Y.Z | <type>: <description>
```

- `<type>` is one of `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `release`.
- `vX.Y.Z` is the current version, used on release commits.
- A `release:` type marks the version bump commit.

Example: `UMO | v4.0.9 | fix: correct dpkg lock cleanup on exit trap`

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
3. Describe your change in `CHANGELOG.md` (the release script rotates it into a versioned block).
4. Fill in the PR template checklist.
5. Target the `main` branch.

## 🚀 Release Process (maintainers)

Releases are cut with the helper script, which keeps the version in
`bin/umo-install`, the README badges, and `CHANGELOG.md` in sync:

```bash
./scripts/release.sh <new-version>      # e.g. ./scripts/release.sh 4.0.9
```

The script will:

1. Bump `UMO_VERSION` in `bin/umo-install`.
2. Update the version badge in `README.md` and `README_AR.md`.
3. Move the `CHANGELOG.md` `[Unreleased]` section into a new `## [X.Y.Z]` block.
4. Commit the bump and create an annotated tag `vX.Y.Z`.

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
