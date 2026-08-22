#!/bin/bash
# Fetches and verifies the latest signed Omarchy MX Mac installer.

set -euo pipefail

fail() { echo "Error: $*" >&2; exit 1; }

for cmd in curl gpg awk; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command is unavailable: $cmd"
done

if (( EUID != 0 )) && ! command -v omarchy >/dev/null 2>&1; then
  echo "=> Fresh installation detected: escalating with sudo..."
  exec sudo bash "$0" "$@"
fi

work_dir="/root/omarchy-mx-mac-install"
if (( EUID != 0 )); then
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-mx-mac-install.XXXXXXXX")
  trap 'rm -rf "$work_dir"' EXIT
else
  mkdir -p "$work_dir"
fi

cd "$work_dir"

raw_url="https://raw.githubusercontent.com/yannouuuu/omarchy-mx-mac-fedora/main"

echo "=> Downloading installer..."
curl -fLO --retry 3 "$raw_url/install-omarchy-mx-mac"
chmod +x install-omarchy-mx-mac

echo "=> Starting installation..."
bash install-omarchy-mx-mac "$@"
