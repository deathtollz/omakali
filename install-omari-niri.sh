#!/bin/bash
# ============================================================================
# install-omari-niri.sh
# ----------------------------------------------------------------------------
# Install Niri (built from source) + the Omari styling/theme files on a fresh
# install of Kali Linux.
#
# This is the standalone, post-install counterpart to the live-build chroot
# hook used to bake the Omari Kali ISO. It performs the same proven steps, but
# targets a normally-installed Kali system and the *invoking* user's $HOME:
#
#   1. Configure the omakasui APT repositories (cleanly pinned vs Kali libs).
#   2. Install the Omari base + lock packages (Kali-native).
#   3. Install the omakasui-sourced packages (walker, elephant, swayosd, ...).
#   4. Build and install Niri from source (libdisplay-info1/2 not in Kali).
#   5. Lay down the Omari configuration + themes into the user's home.
#   6. Link the Elephant menu providers so the theme selector is populated.
#   7. De-duplicate the waybar/mako/hypridle session daemons.
#   8. Make the "niri" session selectable at the login screen
#      (optionally enable autologin into niri with --autologin).
#
# Usage:
#   ./install-omari-niri.sh [--autologin] [--skel] [-y] [-h]
#
#   --autologin   Configure SDDM to autologin the invoking user into niri.
#   --skel        Also populate /etc/skel so new users get Omari by default.
#   -y, --yes     Don't prompt for confirmation; assume "yes".
#   -h, --help    Show this help and exit.
#
# Run it as your normal user (NOT root); it calls sudo where needed.
# Safe to re-run (idempotent).
# ============================================================================
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Presentation
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi
step() { echo; echo "${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }
info() { echo "    $*"; }
warn() { echo "${C_YELLOW}    WARNING:${C_RESET} $*" >&2; }
die()  { echo "${C_RED}${C_BOLD}ERROR:${C_RESET} $*" >&2; exit 1; }
on_err() { die "installation failed at line $1 (see output above)."; }
trap 'on_err $LINENO' ERR

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
WANT_AUTOLOGIN=0
WANT_SKEL=0
ASSUME_YES=0
usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --autologin) WANT_AUTOLOGIN=1 ;;
    --skel)      WANT_SKEL=1 ;;
    -y|--yes)    ASSUME_YES=1 ;;
    -h|--help)   usage 0 ;;
    *) die "unknown option: $1 (use --help)";;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Preflight guards
# ---------------------------------------------------------------------------
step "Preflight checks"

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "do NOT run this as root. Run as your normal user; it will sudo when needed."
command -v sudo >/dev/null 2>&1 || die "sudo is required but not installed."

# Confirm we're on Kali/Debian (the omakasui repos + Niri build target this).
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  die "/etc/os-release not found; cannot identify the distribution."
fi
case "${ID:-}${ID_LIKE:-}" in
  *kali*|*debian*) info "Distribution: ${PRETTY_NAME:-$ID} (ok)";;
  *) warn "this script targets Kali/Debian; '${ID:-unknown}' is untested. Continuing.";;
esac

[[ "$(dpkg --print-architecture)" == "amd64" ]] || \
  warn "architecture is '$(dpkg --print-architecture)'; Niri build deps are validated on amd64."

# Resolve the Omari source tree shipped alongside this script (omari-setup/).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMARI_SRC="$SCRIPT_DIR/omari-setup"
[[ -d "$OMARI_SRC" && -f "$OMARI_SRC/install/packaging/niri-build.sh" ]] || \
  die "Omari source tree not found at:
       $OMARI_SRC
     Run this script from inside a clone of the omari-niri-installer repo."
info "Omari source: $OMARI_SRC"

# Per-user Omari install location (matches config/environment.d/20-omari.conf).
export OMARI_PATH="$HOME/.local/share/omari"
export OMARI_INSTALL="$OMARI_PATH/install"
export OMARI_CHANNEL="${OMARI_CHANNEL:-stable}"
export PATH="$OMARI_PATH/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

info "Install target: $OMARI_PATH (user: $(id -un))"
info "Autologin: $([[ $WANT_AUTOLOGIN -eq 1 ]] && echo yes || echo no)   /etc/skel: $([[ $WANT_SKEL -eq 1 ]] && echo yes || echo no)"

if [[ $ASSUME_YES -ne 1 ]]; then
  echo
  read -r -p "Proceed with installing Niri + Omari for '$(id -un)'? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || die "aborted by user."
fi

# Prime sudo once so long unattended steps don't stall on a password prompt.
sudo -v

# ---------------------------------------------------------------------------
# 1. Stage the Omari payload into the user's home
# ---------------------------------------------------------------------------
step "Staging Omari payload into $OMARI_PATH"
install -d "$(dirname "$OMARI_PATH")"
rm -rf "$OMARI_PATH"
cp -a "$OMARI_SRC" "$OMARI_PATH"
chmod +x "$OMARI_PATH"/bin/omari-* 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Base tooling required by the repo scripts
# ---------------------------------------------------------------------------
step "Installing base tooling (curl/gpg/git/...)"
sudo apt-get update
sudo apt-get install -y curl gpg gnupg ca-certificates dbus git

# ---------------------------------------------------------------------------
# 3. Configure the omakasui APT repositories (pinned vs Kali libs)
# ---------------------------------------------------------------------------
step "Configuring omakasui APT repositories"
# shellcheck source=/dev/null
source "$OMARI_INSTALL/helpers/keyrings.sh"
# shellcheck source=/dev/null
source "$OMARI_INSTALL/helpers/mirror.sh"
sudo apt-get update

# ---------------------------------------------------------------------------
# 4. Base + lock packages (Kali-native)
# ---------------------------------------------------------------------------
step "Installing Omari base + lock packages"
# base.sh installs the "lock" packages via an APT_EXTRA_OPTS bash array that
# cannot survive being exported to the external omari-pkg-add command, so
# --no-install-recommends is dropped and recommends (e.g. gdm3) sneak in.
# Install them here first with --no-install-recommends; base.sh's lock call
# then becomes a harmless no-op (already installed).
mapfile -t lock_packages < <(grep -v '^#' "$OMARI_INSTALL/omari-base.lock.packages" | grep -v '^$')
sudo apt-get install -y --no-install-recommends "${lock_packages[@]}"
bash "$OMARI_INSTALL/packaging/base.sh"

# ---------------------------------------------------------------------------
# 5. omakasui-sourced packages (best-effort, one at a time)
# ---------------------------------------------------------------------------
step "Installing omakasui packages (walker, elephant-all, swayosd, ...)"
bash "$OMARI_INSTALL/packaging/omakasui.sh"
# walker ships an APT hook that restarts walker on every apt run; it can wedge
# subsequent apt operations. Drop it (omari relaunches walker via autostart).
sudo rm -f /etc/apt/apt.conf.d/99restart-walker

# ---------------------------------------------------------------------------
# 6. Build and install Niri from source (mandatory)
# ---------------------------------------------------------------------------
step "Building Niri from source (this can take several minutes)"
if [[ -x /usr/bin/niri ]]; then
  info "Niri already present: $(/usr/bin/niri --version 2>/dev/null || echo unknown) — rebuilding to stay current."
fi
bash "$OMARI_INSTALL/packaging/niri-build.sh"
[[ -x /usr/bin/niri ]] || die "Niri binary missing after build."
[[ -f /usr/share/wayland-sessions/niri.desktop ]] || die "niri.desktop session file missing after build."
info "Niri installed: $(/usr/bin/niri --version 2>/dev/null || echo built)"

# ---------------------------------------------------------------------------
# 7. De-duplicate session daemons
# ---------------------------------------------------------------------------
# Kali/Debian's waybar, mako-notifier and hypridle packages ship *enabled*
# systemd user services. Omari already starts these from niri's autostart.kdl,
# so leaving the packaged services enabled launches each one twice (most
# visibly two stacked waybars). Disable them so autostart is the single source.
step "Disabling duplicate systemd user services"
for unit in waybar.service mako.service hypridle.service; do
  sudo systemctl --global disable "$unit" 2>/dev/null || true
  sudo rm -f "/etc/systemd/user/graphical-session.target.wants/$unit"
done

# ---------------------------------------------------------------------------
# 8. Lay down the Omari configuration into the user's home
# ---------------------------------------------------------------------------
# Mirrors the /etc/skel population from the ISO hook, but writes into the
# invoking user's $HOME so it takes effect immediately on next login.
lay_down_omari() {
  local home="$1"

  # App configs under ~/.config
  install -d "$home/.config"
  cp -a "$OMARI_PATH/config/." "$home/.config/"

  # Shell defaults
  [[ -f "$OMARI_PATH/default/bashrc" ]]       && cp -a "$OMARI_PATH/default/bashrc"       "$home/.bashrc"
  [[ -f "$OMARI_PATH/default/bash_profile" ]] && cp -a "$OMARI_PATH/default/bash_profile" "$home/.bash_profile"

  # Pre-apply Tokyo Night as the "current" theme (deterministic; interactive
  # omari-theme-set needs a running session).
  install -d "$home/.config/omari/current/theme" "$home/.config/omari/themes"
  cp -a "$OMARI_PATH/themes/tokyo-night/." "$home/.config/omari/current/theme/"
  echo "tokyo-night" > "$home/.config/omari/current/theme.name"

  # Current background -> first background of the theme (relative symlink)
  local bgdir="$home/.config/omari/current/theme/backgrounds"
  if [[ -d "$bgdir" ]]; then
    local bg
    for bg in "$bgdir"/*.{jpg,jpeg,png,gif,bmp,webp,JPG,JPEG,PNG}; do
      [[ -e "$bg" ]] || continue
      ln -snf "theme/backgrounds/$(basename "$bg")" "$home/.config/omari/current/background"
      break
    done
  fi

  # Themed app symlinks
  install -d "$home/.config/btop/themes" "$home/.config/mako"
  ln -snf ../../omari/current/theme/btop.theme "$home/.config/btop/themes/current.theme"
  ln -snf ../omari/current/theme/mako.ini      "$home/.config/mako/config"

  # Elephant dynamic menus (the Style > Theme / Background selectors). Without
  # these links the walker theme selector comes up empty. Link every provider.
  install -d "$home/.config/elephant/menus"
  local menu
  for menu in "$OMARI_PATH"/default/elephant/*.lua; do
    [[ -e "$menu" ]] || continue
    ln -snf "$menu" "$home/.config/elephant/menus/$(basename "$menu")"
  done

  # Walker autostart + crash-restart drop-in
  install -d "$home/.config/autostart"
  [[ -f "$OMARI_PATH/default/walker/walker.desktop" ]] && \
    cp -a "$OMARI_PATH/default/walker/walker.desktop" "$home/.config/autostart/"
  install -d "$home/.config/systemd/user/app-walker@autostart.service.d"
  [[ -f "$OMARI_PATH/default/walker/restart.conf" ]] && \
    cp -a "$OMARI_PATH/default/walker/restart.conf" \
       "$home/.config/systemd/user/app-walker@autostart.service.d/restart.conf"

  # XDG user dirs
  cat > "$home/.config/user-dirs.dirs" <<'UDIRS'
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
UDIRS
  install -d "$home/Desktop" "$home/Documents" "$home/Downloads" \
    "$home/Music" "$home/Pictures" "$home/Videos"
}

step "Laying down Omari configuration into $HOME"
lay_down_omari "$HOME"

# Papirus action-icon symlinks (best-effort, system-wide; matches config/theme.sh)
for ICON_THEME_DIR in /usr/share/icons/Papirus-Dark /usr/share/icons/Adwaita; do
  [[ -d "$ICON_THEME_DIR" ]] || continue
  sudo ln -snf "$ICON_THEME_DIR/symbolic/actions/go-previous-symbolic.svg" \
    "$ICON_THEME_DIR/scalable/actions/go-previous-symbolic.svg" 2>/dev/null || true
  sudo ln -snf "$ICON_THEME_DIR/symbolic/actions/go-next-symbolic.svg" \
    "$ICON_THEME_DIR/scalable/actions/go-next-symbolic.svg" 2>/dev/null || true
  break
done

# ---------------------------------------------------------------------------
# 8b. Optionally populate /etc/skel for future users
# ---------------------------------------------------------------------------
if [[ $WANT_SKEL -eq 1 ]]; then
  step "Populating /etc/skel for future users"
  TMP_SKEL="$(mktemp -d)"
  # Build the payload in a staging dir, then copy in as root. Relative symlinks
  # keep working for any future user's $HOME.
  install -d "$TMP_SKEL/.local/share"
  cp -a "$OMARI_PATH" "$TMP_SKEL/.local/share/omari"
  lay_down_omari "$TMP_SKEL"
  # Re-point the elephant menu links to be relative (portable across homes).
  for menu in "$TMP_SKEL"/.config/elephant/menus/*.lua; do
    [[ -e "$menu" ]] || continue
    ln -snf "../../../.local/share/omari/default/elephant/$(basename "$menu")" "$menu"
  done
  sudo cp -a "$TMP_SKEL/." /etc/skel/
  rm -rf "$TMP_SKEL"
  info "/etc/skel populated."
fi

# ---------------------------------------------------------------------------
# 9. Display manager / session wiring
# ---------------------------------------------------------------------------
step "Configuring the login session"
# Install the Omari SDDM theme (harmless if SDDM isn't the active greeter).
omari-refresh-sddm 2>/dev/null || warn "could not install the Omari SDDM theme (continuing)."

# On distros where the greeter ships as sddm-greeter-qt6
if [[ ! -e /usr/bin/sddm-greeter && -f /usr/bin/sddm-greeter-qt6 ]]; then
  sudo ln -snf /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter
fi

if [[ $WANT_AUTOLOGIN -eq 1 ]]; then
  info "Enabling SDDM autologin into niri for $(id -un)."
  sudo install -d /etc/sddm.conf.d
  sudo tee /etc/sddm.conf.d/omari.conf >/dev/null <<SDDM
[Theme]
Current=omari

[Autologin]
User=$(id -un)
Session=niri.desktop
SDDM
  # Make SDDM the active display manager if it's installed.
  if [[ -x /usr/bin/sddm ]]; then
    echo "/usr/bin/sddm" | sudo tee /etc/X11/default-display-manager >/dev/null 2>&1 || true
    sudo systemctl enable sddm.service 2>/dev/null || true
  fi
else
  info "Added a selectable 'niri' session. Pick 'Niri' at your login screen."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
echo "${C_GREEN}${C_BOLD}============================================================${C_RESET}"
echo "${C_GREEN}${C_BOLD}  Omari + Niri install complete${C_RESET}"
echo "${C_GREEN}${C_BOLD}============================================================${C_RESET}"
echo "  Niri:   $(/usr/bin/niri --version 2>/dev/null || echo unknown)"
echo "  Omari:  $OMARI_PATH"
echo "  Theme:  Tokyo Night (change it in-session: Mod+Shift+Ctrl+Space)"
echo
echo "  Next steps:"
if [[ $WANT_AUTOLOGIN -eq 1 ]]; then
  echo "    • Reboot, or restart your display manager, to autologin into Niri."
else
  echo "    • Log out, then choose the ${C_BOLD}Niri${C_RESET} session at the login screen."
fi
echo "    • Key binds: Mod+Space (launcher), Mod+Return (foot), Mod+A (alacritty),"
echo "      Mod+K (keybindings cheat-sheet), Mod+Shift+Ctrl+Space (theme picker)."
echo
