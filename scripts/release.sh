#!/bin/sh
# UMO - Release Helper (GPL-3.0-or-later)
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

if ! git diff --quiet || ! git diff --cached --quiet; then
    _dirty_files=$(git diff --name-only; git diff --cached --name-only)
    _non_install_dirty=$(echo "$_dirty_files" | grep -v '^bin/umo-install$' || true)
    _install_bumped=$(git diff bin/umo-install | grep -c "export UMO_VERSION=\"$NEW_VER\"" || true)
    if [ -n "$_non_install_dirty" ] || [ "$_install_bumped" -eq 0 ]; then
        echo "Error: working tree is dirty. Commit or stash changes first." >&2
        exit 1
    fi
    git checkout -- bin/umo-install
fi

OLD_VER=$(sed -n 's/^export UMO_VERSION="\([^"]*\)"/\1/p' bin/umo-install)
if [ -z "$OLD_VER" ]; then
    echo "Error: could not read UMO_VERSION from bin/umo-install" >&2
    exit 1
fi

if [ "$OLD_VER" = "$NEW_VER" ]; then
    echo "[..] Version already at $NEW_VER, continuing with badge/docs update..."
else
    echo "[..] Bumping $OLD_VER -> $NEW_VER"
    sed -i "s/^export UMO_VERSION=\"$OLD_VER\"/export UMO_VERSION=\"$NEW_VER\"/" bin/umo-install
fi

_md_files=$(grep -rl --exclude-dir=.kilo --include='*.md' "version-[0-9]\|الإصدار-[0-9]" .)
if [ -n "$_md_files" ]; then
    echo "$_md_files" | xargs sed -i \
        -e "s/version-[0-9][0-9.]*/version-$NEW_VER/g" \
        -e "s/الإصدار-[0-9][0-9.]*/الإصدار-$NEW_VER/g"
fi

sed -i "s/UMO_VERSION:-[0-9][0-9.]*/UMO_VERSION:-$NEW_VER/g" lib/core-ansi.sh modules/umo-vnc.sh 2>/dev/null || true

TODAY=$(date +%Y-%m-%d)
if grep -q "^## \[v$NEW_VER\]" CHANGELOG.md; then
    sed -i "s/^## \[v$NEW_VER\] - .*/## [v$NEW_VER] - $TODAY/" CHANGELOG.md
else
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
fi

sh -n bin/umo-install
grep -q "UMO_VERSION=\"$NEW_VER\"" bin/umo-install || {
    echo "Error: version bump failed verification" >&2
    exit 1
}

git add bin/umo-install CHANGELOG.md lib/core-ansi.sh modules/umo-vnc.sh bash.sh
_md_new=$(grep -rl --exclude-dir=.kilo --include='*.md' "version-$NEW_VER\|الإصدار-$NEW_VER" .)
[ -n "$_md_new" ] && echo "$_md_new" | xargs git add

git commit -m "umo | v$NEW_VER | release: version bump and docs sync to $NEW_VER"
git tag -a "v$NEW_VER" -m "umo v$NEW_VER"

echo
echo "[OK] Released v$NEW_VER"
echo "     Next: git push origin main --follow-tags"
