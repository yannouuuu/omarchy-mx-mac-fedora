# Enable services only. Installs are followed by reboot, so don't start/reload
# daemons mid-install. UFW and hardware-gated services stay in their own scripts.
systemctl enable cups.service 2>/dev/null || true
systemctl enable cups-browsed.service 2>/dev/null || true
systemctl enable avahi-daemon.service 2>/dev/null || true
if ! omarchy-hw-apple-silicon; then
  systemctl enable linux-modules-cleanup.service 2>/dev/null || true
fi
systemctl enable docker.socket 2>/dev/null || true
systemctl enable systemd-resolved.service 2>/dev/null || true
systemctl enable NetworkManager.service 2>/dev/null || true
# Don't let network-online.target (pulled in by cups-browsed) hold up
# graphical.target waiting for DHCP/Wi-Fi association. Nothing in the session
# needs to block on the network. Mirrors the systemd-networkd-wait-online mask
# in install/hardware/network.sh.
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true
systemctl enable power-profiles-daemon.service 2>/dev/null || true
systemctl enable sddm.service 2>/dev/null || true
if ! omarchy-hw-apple-silicon; then
  # [Install] also enables the socket that reports app.slice candidacy.
  systemctl enable systemd-oomd.service 2>/dev/null || true
fi
