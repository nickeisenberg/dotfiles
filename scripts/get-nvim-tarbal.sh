#!/usr/bin/env bash
set -euo pipefail

VERSION="${NVIM_TAG:-stable}"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
    Linux-x86_64)
        ASSET="nvim-linux-x86_64.tar.gz"
        ;;
    Linux-aarch64 | Linux-arm64)
        ASSET="nvim-linux-arm64.tar.gz"
        ;;
    Darwin-x86_64)
        ASSET="nvim-macos-x86_64.tar.gz"
        ;;
    Darwin-arm64)
        ASSET="nvim-macos-arm64.tar.gz"
        ;;
    *)
        echo "Unsupported platform: ${OS}-${ARCH}" >&2
        exit 1
        ;;
esac

curl -fsSL \
    "https://github.com/neovim/neovim/releases/download/${VERSION}/${ASSET}" \
    -o "${ASSET}"

tar -xzf "${ASSET}"
