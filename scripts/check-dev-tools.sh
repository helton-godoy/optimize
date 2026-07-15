#!/usr/bin/env bash
# Verify development tools expected by CI and local checks.
set -euo pipefail

missing=()

for tool in shellcheck shfmt bash-language-server; do
    if ! command -v "$tool" > /dev/null; then
        missing+=("$tool")
    fi
done

if ((${#missing[@]} > 0)); then
    printf 'Missing development tools: %s\n' "${missing[*]}" >&2
    printf 'Run: make bootstrap-dev\n' >&2
    exit 1
fi

shellcheck --version | sed -n '1p'
shfmt --version
bash-language-server --version 2> /dev/null || bash-language-server --help > /dev/null
