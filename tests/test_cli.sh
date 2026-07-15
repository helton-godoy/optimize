#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

expected_version="$(sed -n 's/^readonly OPTIMIZE_VERSION="\([^"]*\)"/\1/p' optimize)"
output="$(./optimize --version)"
[[ "$output" == "optimize $expected_version" ]] || fail "unexpected version output: $output"

help_output="$(./optimize --help)"
[[ "$help_output" == *"native-safe"* ]] || fail "help does not document native-safe"
[[ "$help_output" == *"adaptive"* ]] || fail "help does not document adaptive"
[[ "$help_output" == *"--no-check"* ]] || fail "help does not document --no-check"

if ./optimize "../bad" > /tmp/optimize-test.out 2> /tmp/optimize-test.err; then
    fail "invalid package path was accepted"
fi

if ./optimize --jobs 0 hello > /tmp/optimize-test.out 2> /tmp/optimize-test.err; then
    fail "invalid --jobs value was accepted"
fi

if ./optimize --profile adaptive --cflags "-O2" hello > /tmp/optimize-test.out 2> /tmp/optimize-test.err; then
    fail "adaptive with custom flags was accepted"
fi

if ./optimize > /tmp/optimize-test.out 2> /tmp/optimize-test.err; then
    fail "missing package was accepted"
fi

source ./optimize
[[ "$(normalize_kernel_source "linux-signed-amd64")" == "linux" ]] || fail "linux-signed-amd64 was not normalized to linux"
[[ "$(normalize_kernel_source "linux-signed-amd64 (6.12.95)")" == "linux" ]] || fail "linux-signed-amd64 with version was not normalized to linux"
[[ "$(normalize_kernel_source "linux-signed-hwe-6.8")" == "linux-hwe-6.8" ]] || fail "linux-signed-hwe was not normalized"
[[ "$(normalize_kernel_source "linux-meta-hwe-6.8")" == "linux-hwe-6.8" ]] || fail "linux-meta-hwe was not normalized"

echo "CLI contract tests passed."
