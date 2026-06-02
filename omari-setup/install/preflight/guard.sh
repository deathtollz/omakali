# Ensure we have bc available
if ! command -v bc &> /dev/null; then
  omari-pkg-add bc
fi

abort() {
  echo -e "\e[31m$OMARI_BRAND install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must be a valid OS
[[ -f /etc/os-release ]] || abort "/etc/os-release"

. /etc/os-release

# Accept Kali Linux or Debian 13+
if [[ $ID == "kali" ]]; then
  echo "Detected Kali Linux — OK"
elif [[ $ID == "debian" ]]; then
  [[ $(echo "$VERSION_ID >= 13" | bc) != "1" ]] && abort "Debian 13 or higher"
else
  abort "Kali Linux or Debian 13+"
fi

# Must be x86 only to fully work
ARCH=$(uname -m)
if [[ $ARCH != "x86_64" ]] && [[ $ARCH != "i686" ]]; then
  abort "x86_64 CPU"
fi

# Must not have a desktop environment installed
[[ -n "$XDG_CURRENT_DESKTOP" ]] && abort "No desktop environment should be installed"

# Cleared all guards
echo "Guards: OK"
