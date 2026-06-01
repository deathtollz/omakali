. /etc/os-release

gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Use Papirus-Dark icon theme (papirus-icon-theme is installed on all distros)
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

# Update Papirus icon cache
if [[ -d /usr/share/icons/Papirus-Dark ]]; then
  sudo gtk-update-icon-cache /usr/share/icons/Papirus-Dark
fi
