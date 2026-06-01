# Install omari SDDM theme
omari-refresh-sddm

# Setup SDDM login service
sudo mkdir -p /etc/sddm.conf.d
if [[ ! -f /etc/sddm.conf.d/theme.conf ]]; then
  cat <<EOF2 | sudo tee /etc/sddm.conf.d/theme.conf
[Theme]
Current=omari
EOF2
fi

# On Debian 13, the greeter ships as sddm-greeter-qt6 but SDDM looks for sddm-greeter.
# On Kali the same may apply depending on the installed sddm version.
if [[ ! -e /usr/bin/sddm-greeter ]] && [[ -f /usr/bin/sddm-greeter-qt6 ]]; then
  sudo ln -s /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter
fi

# Don't use --now here as it will cause issues for manual installs
sudo systemctl enable sddm.service
