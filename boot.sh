#!/bin/bash
# ============================================================================
# boot.sh — curl|bash bootstrap for the Omari Kali (Niri) installer
# ----------------------------------------------------------------------------
# Installs git if needed, clones (or updates) the omakali repo, then runs the
# installer. Designed to be piped straight from curl:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/deathtollz/omakali/main/boot.sh)
#
# Pass installer flags through after the process substitution, e.g.:
#
#   bash <(curl -fsSL .../boot.sh) --autologin
#
# or, if your shell lacks process substitution:
#
#   curl -fsSL .../boot.sh | bash -s -- --autologin
#
# Overridable via environment:
#   OMAKALI_REPO    git URL to clone   (default: deathtollz/omakali)
#   OMAKALI_BRANCH  branch to use      (default: main)
#   OMAKALI_DIR     local clone path   (default: ~/.local/share/omakali)
# ============================================================================
set -Eeuo pipefail

REPO="${OMAKALI_REPO:-https://github.com/deathtollz/omakali.git}"
BRANCH="${OMAKALI_BRANCH:-main}"
DEST="${OMAKALI_DIR:-$HOME/.local/share/omakali}"

red()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
blue() { printf '\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

# Refuse root (the installer sudo's where needed and targets the real user's home).
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  red "ERROR: run this as your normal user, not root. It will sudo when needed."
  exit 1
fi

# Ensure git + curl/ca-certificates are present.
if ! command -v git >/dev/null 2>&1; then
  blue "Installing git..."
  sudo apt-get update
  sudo apt-get install -y git ca-certificates
fi

# Clone or update the repo.
if [[ -d "$DEST/.git" ]]; then
  blue "Updating existing clone at $DEST"
  git -C "$DEST" remote set-url origin "$REPO" 2>/dev/null || true
  git -C "$DEST" fetch --depth 1 origin "$BRANCH"
  git -C "$DEST" checkout -q "$BRANCH"
  git -C "$DEST" reset --hard "origin/$BRANCH"
else
  blue "Cloning $REPO -> $DEST"
  rm -rf "$DEST"
  install -d "$(dirname "$DEST")"
  git clone --depth 1 --branch "$BRANCH" "$REPO" "$DEST"
fi

# Run the installer. Read prompts from the terminal when one is available so
# confirmation still works even though stdin is the curl pipe.
blue "Launching installer"
cd "$DEST"
chmod +x install-omari-niri.sh
if [[ -r /dev/tty ]]; then
  exec ./install-omari-niri.sh "$@" </dev/tty
else
  exec ./install-omari-niri.sh "$@"
fi
