#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

script_version="$(sed -n 's/^readonly OPTIMIZE_VERSION="\([^"]*\)"/\1/p' optimize)"
changelog_version="$(sed -n '1s/.*(\([^-)]*\).*/\1/p' debian/changelog)"

[[ -n "$script_version" ]] || fail "script version not found"
[[ "$script_version" == "$changelog_version" ]] || fail "script version $script_version differs from changelog $changelog_version"

grep -q "\"$script_version\"" optimize.1 || fail "optimize.1 does not contain $script_version"
grep -q "\"$script_version\"" optimize.pt_BR.1 || fail "optimize.pt_BR.1 does not contain $script_version"
grep -q "optimize v$script_version" README.md || fail "README does not contain optimize v$script_version"
grep -q -- "--package-version=$script_version" po/update-po.sh || fail "po/update-po.sh package version is not $script_version"

echo "Version consistency tests passed."
