#!/bin/bash
# Fetches and verifies the latest signed Omarchy MX Mac installer.

set -euo pipefail

fail() { echo "Error: $*" >&2; exit 1; }

for cmd in curl gpg gpgv awk; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command is unavailable: $cmd"
done

work_dir="/root/omarchy-mx-mac-install"
if (( EUID != 0 )); then
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-mx-mac-install.XXXXXXXX")
  trap 'rm -rf "$work_dir"' EXIT
else
  mkdir -p "$work_dir"
fi

cd "$work_dir"

release="https://github.com/yannouuuu/omarchy-mx-mac-fedora/releases/latest/download"
fingerprint="054BDF38F9C8208EDAF66FCBD64CF9AD7ABB2D60"

echo "=> Downloading installer and signatures..."
curl -fLO --retry 3 "$release/install-omarchy-mx-mac"
curl -fLO --retry 3 "$release/install-omarchy-mx-mac.sig"
curl -fLO --retry 3 "$release/omarchy-release.gpg"

echo "=> Verifying release key..."
actual_fingerprint=$(gpg --show-keys --with-colons omarchy-release.gpg | awk -F: '$1 == "fpr" { print $10; exit }')
if [[ $actual_fingerprint != $fingerprint ]]; then
  fail "Release signing key fingerprint mismatch."
fi

echo "=> Verifying installer signature..."
gpgv --keyring ./omarchy-release.gpg install-omarchy-mx-mac.sig install-omarchy-mx-mac || \
  fail "Installer signature verification failed."

echo "=> Pre-verifying package integrity..."
bash install-omarchy-mx-mac --verify-only

echo "=> Starting installation..."
bash install-omarchy-mx-mac "$@"
