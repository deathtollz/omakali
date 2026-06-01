# Install omakasui-sourced packages individually.
# These are installed separately from the Kali base packages because they target
# a Debian trixie snapshot and have specific dependency requirements.

. /etc/os-release

# ── Pre-install Kali-native dependencies that omakasui packages need ──────────

# libseat1: needed by niri
sudo apt-get -y install libseat1 2>/dev/null || true

# libdisplay-info-dev: headers + .so symlink (runtime soname not packaged on Kali)
sudo apt-get -y install libdisplay-info-dev 2>/dev/null || true

# libgtk4-layer-shell0: needed by walker and swayosd
sudo apt-get -y install libgtk4-layer-shell0 2>/dev/null || true

# ── Install foundational omakasui packages first ──────────────────────────────
for pkg in gum nvim elephant; do
  echo "Pre-installing $pkg..."
  sudo apt-get -y install "$pkg" 2>/dev/null || echo "WARNING: $pkg not available, skipping"
done

# ── Install remaining omakasui packages one at a time ────────────────────────
mapfile -t omakasui_packages < <(grep -v '^#' "$OMARI_PATH/install/omari-omakasui.packages" | grep -v '^$')

failed_packages=()

for pkg in "${omakasui_packages[@]}"; do
  # Skip packages already handled above
  [[ "$pkg" == "gum" || "$pkg" == "nvim" || "$pkg" == "elephant" ]] && continue

  # niri cannot be installed from omakasui on Kali — libdisplay-info1/2 not packaged.
  # Build from source instead.
  if [[ "$pkg" == "niri" ]]; then
    echo "niri: building from source (libdisplay-info1/2 not available on Kali)..."
    bash "$OMARI_PATH/install/packaging/niri-build.sh" || {
      echo "WARNING: niri source build failed"
      failed_packages+=("niri (source build)")
    }
    continue
  fi

  echo "Installing $pkg..."
  if ! sudo apt-get -y install "$pkg" 2>/dev/null; then
    echo "WARNING: $pkg failed to install — skipping"
    failed_packages+=("$pkg")
  fi
done

if [[ ${#failed_packages[@]} -gt 0 ]]; then
  echo ""
  echo "The following packages could not be installed:"
  for pkg in "${failed_packages[@]}"; do
    echo "  - $pkg"
  done
  echo "You can retry these manually after: sudo apt full-upgrade"
fi
