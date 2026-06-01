#!/bin/bash
# Build and install niri from source on Kali.
# Required because the omakasui niri binary links against libdisplay-info1/2
# which are not packaged in Kali's repos (only libdisplay-info-dev exists).

set -euo pipefail

NIRI_VERSION="26.04"  # Latest stable tag
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Building niri $NIRI_VERSION from source..."

# Install build dependencies
sudo apt-get -y install --no-install-recommends \
  cargo rustc \
  libdisplay-info-dev \
  libseat-dev \
  libpipewire-0.3-dev \
  libpango1.0-dev \
  libegl-dev \
  libgbm-dev \
  libxkbcommon-dev \
  libinput-dev \
  libdbus-1-dev \
  libsystemd-dev \
  libwayland-dev \
  wayland-protocols \
  clang \
  pkg-config

# Clone and build
git clone --depth 1 --branch "v${NIRI_VERSION}" \
  https://github.com/YaLTeR/niri.git "$BUILD_DIR/niri"

cd "$BUILD_DIR/niri"
cargo build --release

# Install the binary
sudo install -Dm755 target/release/niri /usr/bin/niri

# Install session files
# niri-session MUST be executable (755): SDDM/login execs it to start the session.
sudo install -Dm755 resources/niri-session \
  /usr/bin/niri-session
sudo install -Dm644 resources/niri.desktop \
  /usr/share/wayland-sessions/niri.desktop
sudo install -Dm644 resources/niri-portals.conf \
  /usr/share/xdg-desktop-portal/niri-portals.conf

# Install the systemd user units. niri-session runs
#   systemctl --user --wait start niri.service
# so without these units the session exits immediately and SDDM bounces back
# to the greeter (autologin appears to "fail"). niri.service also pulls up
# graphical-session.target, which starts waybar/mako.
sudo install -Dm644 resources/niri.service \
  /usr/lib/systemd/user/niri.service
sudo install -Dm644 resources/niri-shutdown.target \
  /usr/lib/systemd/user/niri-shutdown.target

echo "niri installed: $(niri --version 2>/dev/null || echo 'done')"
