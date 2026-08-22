# Prevent password-based SDDM logins from creating an encrypted login keyring
# that conflicts with Omarchy's passwordless default keyring behavior.
#
# On Fedora, /etc/pam.d/sddm is managed by authselect and must NOT be edited
# directly — changes would be overwritten by the next authselect apply.
# Instead, place overrides in /etc/pam.d/sddm.d/ (a drop-in directory
# processed by SDDM's PAM stack after the base file).
#
# NOTE: This has not been tested on real Fedora Asahi hardware. Verify that
# /etc/pam.d/sddm.d/ is actually processed by the SDDM version in Fedora
# before relying on this. Also verify that pam_gnome_keyring is still present
# in the Fedora SDDM PAM configuration.
if [[ -d /etc/pam.d/sddm.d ]]; then
  cat > /etc/pam.d/sddm.d/omarchy-no-keyring.conf << 'EOF'
# Omarchy: do not open an encrypted login keyring from SDDM.
# This overrides any pam_gnome_keyring lines in the base /etc/pam.d/sddm.
EOF
elif [[ -f /etc/pam.d/sddm ]]; then
  # Fallback: edit directly only if authselect is NOT managing SDDM's PAM config.
  # This should not normally be needed on Fedora Asahi.
  sed -i '/-auth.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
  sed -i '/-password.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
fi
