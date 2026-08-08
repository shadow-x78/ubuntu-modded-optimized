#!/bin/sh
# UMO - Release Helper (MIT License)
# https://github.com/shadow-x78/ubuntu-modded-optimized
#
# Usage: ./scripts/release.sh <new-version>
# Bumps the version, rotates CHANGELOG, commits and tags.

set -e

NEW_VER="$1"

if [ -z "$NEW_VER" ]; then
    echo "Usage: $0 <new-version>" >&2
    echo "Example: $0 4.0.9" >&2
    exit 1
fi

case "$NEW_VER" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *)
        echo "Error: version must look like X.Y.Z (got: $NEW_VER)" >&2
        exit 1
        ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Must run on a clean tree so the release commit only contains the bump.
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: working tree is dirty. Commit or stash changes first." >&2
    exit 1
fi

OLD_VER=$(sed -n 's/^export UMO_VERSION="\([^"]*\)"/\1/p' bin/umo-install)
if [ -z "$OLD_VER" ]; then
    echo "Error: could not read UMO_VERSION from bin/umo-install" >&2
    exit 1
fi

if [ "$OLD_VER" = "$NEW_VER" ]; then
    echo "Error: version is already $NEW_VER" >&2
    exit 1
fi

echo "[..] Bumping $OLD_VER -> $NEW_VER"

# ── 1. bin/umo-install ──────────────────────────────────────────
sed -i "s/^export UMO_VERSION=\"$OLD_VER\"/export UMO_VERSION=\"$NEW_VER\"/" bin/umo-install

# ── 2. Badges in README files and SECURITY.md ──────────────────
sed -i "s/version-$OLD_VER-/version-$NEW_VER-/" README.md SECURITY.md docs/INSTALL.md docs/TROUBLESHOOTING.md
sed -i "s/الإصدار-$OLD_VER-/الإصدار-$NEW_VER-/" README_AR.md docs/INSTALL_AR.md docs/TROUBLESHOOTING_AR.md

# ── 3. lib/core-ansi.sh fallback version ───────────────────────
sed -i "s/UMO_VERSION:-$OLD_VER/UMO_VERSION:-$NEW_VER/" lib/core-ansi.sh modules/umo-vnc.sh 2>/dev/null || true

# ── 4. CHANGELOG.md: insert new version block on top ──────────
TODAY=$(date +%Y-%m-%d)
NEXT=$(grep -n '^## \[' CHANGELOG.md | head -1 | cut -d: -f1)
if [ -z "$NEXT" ]; then
    echo "Error: could not find a versioned block in CHANGELOG.md" >&2
    exit 1
fi

TMP="$(mktemp)"
{
    head -n "$((NEXT - 1))" CHANGELOG.md
    echo "## [v$NEW_VER] - $TODAY"
    echo ""
    echo "### Changed"
    echo "- TODO: describe the release changes here before tagging."
    echo ""
    tail -n "+$NEXT" CHANGELOG.md
} > "$TMP"
mv "$TMP" CHANGELOG.md

# ── 5. Validate ────────────────────────────────────────────────
sh -n bin/umo-install
grep -q "UMO_VERSION=\"$NEW_VER\"" bin/umo-install || {
    echo "Error: version bump failed verification" >&2
    exit 1
}

# ── 6. Commit and tag ──────────────────────────────────────────
git add bin/umo-install README.md README_AR.md SECURITY.md CHANGELOG.md \
        docs/INSTALL.md docs/INSTALL_AR.md docs/TROUBLESHOOTING.md docs/TROUBLESHOOTING_AR.md \
        lib/core-ansi.sh modules/umo-vnc.sh

git commit -m "UMO | v$NEW_VER | release: bump to $NEW_VER"
git tag -a "v$NEW_VER" -m "UMO v$NEW_VER"

echo
echo "[OK] Released v$NEW_VER"
echo "     Next: git push origin main --follow-tags"
