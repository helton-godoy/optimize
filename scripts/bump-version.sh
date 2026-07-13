#!/bin/bash
# =============================================================================
# bump-version.sh — Bump optimize package version and update changelog
#
# Usage:
#   ./scripts/bump-version.sh <major|minor|patch> "Description of changes"
#
# Examples:
#   ./scripts/bump-version.sh patch "Fix --kernel source detection"
#   ./scripts/bump-version.sh minor "Add new --targets flag"
#   ./scripts/bump-version.sh major "Complete rewrite with new architecture"
# =============================================================================
set -euo pipefail

CHANGELOG="debian/changelog"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 2 ]; then
  echo "Usage: $0 <major|minor|patch> \"Changelog message\""
  echo ""
  echo "Bumps the version in debian/changelog and stages the change."
  exit 1
fi

BUMP_TYPE="$1"
MESSAGE="$2"

cd "$REPO_DIR"

if [ ! -f "$CHANGELOG" ]; then
  echo "Error: $CHANGELOG not found"
  exit 1
fi

# Extract current version from first changelog entry
CURRENT_LINE=$(head -1 "$CHANGELOG")
CURRENT_VERSION=$(echo "$CURRENT_LINE" | cut -d'(' -f2 | cut -d')' -f1)
CURRENT_UPSTREAM=$(echo "$CURRENT_VERSION" | sed 's/-[0-9]*$//')

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_UPSTREAM"

case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Error: bump type must be major, minor, or patch"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Mark current version as released (replace UNRELEASED with unstable)
sed -i "1s/UNRELEASED/unstable/" "$CHANGELOG"

# Prepend new UNRELEASED entry
DATE=$(date -R)
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
optimize (${NEW_VERSION}-1) UNRELEASED; urgency=medium

  * $MESSAGE

 -- helton <chileno.brasil@gmail.com>  $DATE

$(cat "$CHANGELOG")
EOF
mv "$TEMP_FILE" "$CHANGELOG"

echo "Version bumped: $CURRENT_UPSTREAM -> $NEW_VERSION"
echo "Changelog updated. Commit and push to trigger the build:"
echo ""
echo "  git add $CHANGELOG"
echo "  git commit -m \"chore: bump version to $NEW_VERSION\""
echo "  git push origin main"
