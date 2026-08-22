# Activate the Fedora COPR repositories required by Omarchy on Fedora Asahi Remix.
# Sourced by the provisioning scripts (no shebang — designed to be sourced).
#
# Source: lionheartp/Hyprland COPR confirmed by user as active replacement for
# the deprecated technochip/Hyprland-aarch64 COPR.
# Verify aarch64 package availability before each release.

# ---------------------------------------------------------------------------
# Hyprland aarch64 -- primary COPR for the Wayland/Hyprland stack
# Provides: hyprland, xdg-desktop-portal-hyprland, hyprsunset, hypridle,
#           hyprlock, aquamarine, and related Hyprland ecosystem packages.
# ---------------------------------------------------------------------------
if ! dnf copr list 2>/dev/null | grep -q 'lionheartp/Hyprland'; then
  dnf copr enable -y lionheartp/Hyprland
fi

# ---------------------------------------------------------------------------
# solopasha/hyprland -- optional supplementary COPR
# If enabled, excludepkgs prevents solopasha from overriding the packages
# provided by lionheartp/Hyprland (pattern from malik-na/omarchy-mac-fedora).
# Disabled by default. Uncomment if a specific package requires it.
# ---------------------------------------------------------------------------
# if ! dnf copr list 2>/dev/null | grep -q 'solopasha/hyprland'; then
#   dnf copr enable -y solopasha/hyprland
#   dnf config-manager --save --setopt='copr:copr.fedorainfracloud.org:solopasha:hyprland.excludepkgs=hyprland,xdg-desktop-portal-hyprland,hyprsunset,hypridle,hyprlock,aquamarine'
# fi
