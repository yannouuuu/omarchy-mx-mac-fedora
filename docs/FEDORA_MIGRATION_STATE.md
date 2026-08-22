# Omarchy Fedora Asahi Remix Migration — State & Handover Document

This document provides complete context, architectural decisions, file changes, and instructions for continuing development of the **Omarchy Fedora Asahi Remix** port.

---

## 1. Project Overview & Architecture

- **Goal:** Port **Omarchy 4 "Quattro"** (originally Arch Linux ARM with `pacman`/AUR) to **Fedora Asahi Remix** (`dnf`/RPM) on Apple Silicon (ARM64).
- **Target Distribution:** Fedora Asahi Remix 41+ (aarch64).
- **Window Manager:** Hyprland (Wayland) via COPR `lionheartp/Hyprland`.
- **Desktop Shell:** Quickshell (`quickshell` package).
- **Display Manager:** SDDM with custom Omarchy theme + Wayland greeter.
- **Bootloader:** `m1n1` + `U-Boot` + GRUB/Btrfs (Limine is x86 Arch only).
- **GPG Signing Key:** `054BDF38F9C8208EDAF66FCBD64CF9AD7ABB2D60` (`Omarchy Fedora Releases <releases@omarchy-fedora.local>`).

---

## 2. Repositories

### Primary Repo: `omarchy-mx-mac-fedora`
- **GitHub URL:** `https://github.com/yannouuuu/omarchy-mx-mac-fedora`
- **Branch:** `main`
- **Contains:** Complete Omarchy runtime (`bin/`, `install/`, `shell/`, `themes/`, `config/`, `default/`, `migrations/`).

### Packages & CI Repo: `omarchy-pkgs-fedora`
- **GitHub URL:** `https://github.com/yannouuuu/omarchy-pkgs-fedora`
- **Branch:** `asahi-quattro`
- **Contains:** Release pipeline (`.github/workflows/release-asahi-quattro.yml`), installer (`bin/install-asahi-quattro`), release scripts, and Arch PKGBUILD recipes used by the bootstrap CI.

---

## 3. Work Accomplished

### Component 1: Package Management Abstractions (`bin/omarchy-pkg-*`)
| Script | Change |
|---|---|
| `bin/omarchy-pkg-add` | `pacman -S --noconfirm --needed` → `dnf install -y`; `pacman -Q` → `rpm -q` |
| `bin/omarchy-pkg-drop` | `pacman -Qq` → `rpm -qa --qf '%{NAME}\n'`; `pacman -Rns` → `dnf remove -y` |
| `bin/omarchy-pkg-missing` | `pacman -Q` → `rpm -q` |
| `bin/omarchy-pkg-present` | `pacman -Q` → `rpm -q` |
| `bin/omarchy-pkg-install` | `pacman -Slq` / `-Sii` → `dnf repoquery --available` / `dnf info` |
| `bin/omarchy-pkg-remove` | `yay -Qqe` / `pacman -Rns` → `rpm -qa` / `dnf remove -y` |
| `bin/omarchy-pkg-aur-*` | Explicit error ("AUR not available on Fedora Asahi Remix") |

### Component 2: System Updates (`bin/omarchy-update-*`)
- `bin/omarchy-update-system-pkgs`: `dnf upgrade --refresh -y`, `OMARCHY_UPDATE_DNF=1`, excludes platform kernel overrides.
- `bin/omarchy-update-keyring`: Verifies `054BDF38F9C8208EDAF66FCBD64CF9AD7ABB2D60` in RPM keyring (`rpm -q gpg-pubkey`), refreshes DNF cache (`dnf makecache --refresh`).
- `bin/omarchy-update-pkg-prune`: `paccache` → `dnf clean packages`.
- `bin/omarchy-update-orphan-pkgs`: `pacman -Qtdq` → `dnf repoquery --extras --installed --qf '%{NAME}'` + `dnf remove -y`.
- `bin/omarchy-update-pacman-guard`: Adapted for `OMARCHY_UPDATE_DNF` / `OMARCHY_ALLOW_DIRECT_DNF`.

### Component 3: Package Manifests
- `install/omarchy-base-asahi.packages.fedora`: Full RPM package list for core system and Hyprland stack.
- `install/omarchy-other-asahi.packages.fedora`: Supplementary packages (`@development-tools`, `dkms`, `pipewire`, `zram-generator`, `lsp-plugins-lv2`, `firewalld`).
- Key equivalences mapped:
  - `fd` → `fd-find`
  - `tldr` → `tealdeer`
  - `nvim` → `neovim`
  - `imagemagick` → `ImageMagick`
  - `docker` → `moby-engine`
  - `noto-fonts` → `google-noto-fonts-common`
  - `noto-fonts-cjk` → `google-noto-sans-cjk-fonts`
  - `noto-fonts-emoji` → `google-noto-emoji-fonts`
  - `fcitx5-qt` → `fcitx5-qt5`
  - `github-cli` → `gh`
  - `base-devel` → `@development-tools`
  - `jdk-openjdk` → `java-21-openjdk`
  - `ttf-cascadia-mono-nerd` → `cascadia-mono-nf-fonts`
  - `kvantum-qt5` → `kvantum`
  - `dust` → `du-dust`
  - `hyprland-guiutils`, `quickshell`, `xdg-terminal-exec` enabled.

### Component 4: SDDM, PAM, and System Boot
- `install/login/sddm.sh`: Uses `/etc/pam.d/sddm.d/omarchy-no-keyring.conf` drop-in to prevent breaking `authselect`.
- `bin/omarchy-install-fedora-fresh`:
  - Sets default boot target: `systemctl set-default graphical.target`.
  - Seeds `/var/lib/sddm/state.conf` with `$target_user` (fixes empty-user PAM bug).
  - Deploys SDDM theme to `/usr/share/sddm/themes/omarchy`.
  - Deploys Wayland session to `/usr/share/wayland-sessions/omarchy.desktop`.
  - Provisions user config `~/.config` from `/usr/share/omarchy/config`.
  - Restores SELinux contexts with `restorecon`.

### Component 5: Installation Flow
- Single entry-point installer: `install-omarchy-mx-mac.sh` / `install-omarchy-mx-mac`
- Command:
  ```bash
  curl -fL https://raw.githubusercontent.com/yannouuuu/omarchy-mx-mac-fedora/main/install-omarchy-mx-mac.sh | sudo bash -s -- --user yann
  ```

---

## 4. Key Decisions & Conventions

1. **Bash Style (from `AGENTS.md`):**
   - 2 spaces indentation, no tabs.
   - Shebang: `#!/bin/bash` exclusively.
   - Conditionals: `[[ ]]` for string/file tests, `(( ))` for numeric tests.
   - Quotes: `[[ $var == "literal" ]]`, `"quoted/paths with spaces"`.
2. **Environment Variable:**
   - `$OMARCHY_PATH` is always `/usr/share/omarchy` (or dev path). Never re-export manually in runtime scripts.
3. **Hardware Preservation:**
   - Fedora Asahi base packages (`linux-asahi`, `asahi-desktop-meta`, Mesa, PipeWire) are preserved and never overwritten.

---

## 5. Next Steps to Verify in Live Session

Once logged into the Omarchy desktop session on the Mac:
1. **Hyprland Keybindings:** Test `Super + Return` (Terminal), `Super + Space` / App launcher, `Super + Shift + B` (Browser).
2. **Quickshell Desktop:** Verify top bar, battery indicator, clock, volume control, and workspaces display correctly.
3. **Theme Switcher:** Test `omarchy theme` commands.
4. **Hardware Specifics:** Verify display brightness (`brightnessctl`), audio/speakers (`omarchy-audio-tuning`), Wi-Fi and Bluetooth applets.
5. **System Updates:** Test running `omarchy update` in terminal to ensure `dnf upgrade --refresh -y` and keyring updates run without error.
