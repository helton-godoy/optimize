#!/usr/bin/env bash
# Install development tools used by this repository.
set -euo pipefail

if ! command -v sudo > /dev/null; then
    echo "sudo is required to install development tools" >&2
    exit 1
fi

if ! command -v apt-get > /dev/null; then
    echo "This bootstrap script currently supports Debian/Ubuntu systems with apt-get." >&2
    echo "Install these tools manually: shellcheck shfmt bash-language-server" >&2
    exit 1
fi

sudo apt-get update

packages=(shellcheck shfmt)
if apt-cache show bash-language-server > /dev/null 2>&1; then
    packages+=(bash-language-server)
fi

sudo apt-get install -y --no-install-recommends "${packages[@]}"

if ! command -v bash-language-server > /dev/null; then
    if command -v npm > /dev/null; then
        sudo npm install -g bash-language-server
    else
        echo "bash-language-server was not available through apt and npm is not installed." >&2
        echo "Install npm or install bash-language-server manually, then run make check." >&2
        exit 1
    fi
fi

echo "Development tools are installed."
