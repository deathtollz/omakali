# Ensure we have curl available
if ! command -v curl &> /dev/null; then
  omari-pkg-add curl
fi

# Ensure we have gpg available
if ! command -v gpg &> /dev/null; then
  omari-pkg-add gpg
fi

. /etc/os-release

# ── Debian-only: repair broken APT sources ──────────────────────────────────
if [[ $ID == "debian" ]]; then
  if [ -f /etc/apt/sources.list.d/debian.sources ] || [ -f /etc/apt/sources.list.d/proxmox.sources ]; then
    echo "Found an APT sources file in /etc/apt/sources.list.d/"
  else
    SOURCESLIST=/etc/apt/sources.list
    if ! grep -q "debian.org" $SOURCESLIST >/dev/null 2>&1; then
      echo "$SOURCESLIST does not have any debian.org references."
      if [ -f $SOURCESLIST ]; then
        echo "Renaming $SOURCESLIST to $SOURCESLIST.orig"
        sudo mv $SOURCESLIST $SOURCESLIST.orig
      fi
      DEBIANSOURCES=/etc/apt/sources.list.d/debian.sources
      if [ ! -f $DEBIANSOURCES ]; then
        echo "Creating $DEBIANSOURCES"
        cat <<DEBEOF | sudo tee -a $DEBIANSOURCES
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
DEBEOF
      fi
    fi
  fi
fi

# ── Add Omakasui APT repositories ───────────────────────────────────────────
curl -fsSL https://keyrings.omakasui.org/omakasui-core.gpg.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/omakasui-core.gpg > /dev/null

curl -fsSL https://keyrings.omakasui.org/omakasui-packages.gpg.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/omakasui-packages.gpg > /dev/null

# Kali uses kali-rolling which isn't in the omakasui repo — target trixie instead
if [[ $ID == "kali" ]]; then
  OMAKASUI_CODENAME="trixie"
else
  OMAKASUI_CODENAME="$VERSION_CODENAME"
fi

if [[ ${OMARI_CHANNEL:-stable} == "dev" ]]; then
  suite="${OMAKASUI_CODENAME}-dev"
else
  suite="${OMAKASUI_CODENAME}"
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/omakasui-core.gpg] \
  https://core.omakasui.org $suite main" \
  | sudo tee /etc/apt/sources.list.d/omakasui-core.list

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/omakasui-packages.gpg] \
  https://packages.omakasui.org $suite main" \
  | sudo tee /etc/apt/sources.list.d/omakasui.list

# ── Install APT preferences to prevent omakasui from overriding Kali libs ───
# Resolve the repo root relative to this script so it works both during
# a full install (OMARI_PATH set) and when run standalone
_OMARI_ROOT="${OMARI_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
sudo install -Dm644 "$_OMARI_ROOT/install/apt/omakasui-pin.pref" \
  /etc/apt/preferences.d/omakasui-pin

# Refresh the APT cache
sudo apt-get update
