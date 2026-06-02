# Ensure Walker service is started automatically on boot
mkdir -p "$HOME/.config/autostart/"
cp "$OMARI_PATH/default/walker/walker.desktop" "$HOME/.config/autostart/"

# And is restarted if it crashes or is killed
mkdir -p "$HOME/.config/systemd/user/app-walker@autostart.service.d/"
cp "$OMARI_PATH/default/walker/restart.conf" "$HOME/.config/systemd/user/app-walker@autostart.service.d/restart.conf"

# Create apt hook to restart walker after updates
sudo mkdir -p /etc/apt/apt.conf.d
sudo tee /etc/apt/apt.conf.d/99restart-walker << EOF
DPkg::Post-Invoke {
    "if dpkg -l walker 2>/dev/null | grep -q '^ii'; then $OMARI_PATH/bin/omari-restart-walker; fi";
};
EOF

# Link the visual theme menu config
mkdir -p "$HOME/.config/elephant/menus"
ln -snf "$OMARI_PATH/default/elephant/omari_themes.lua" "$HOME/.config/elephant/menus/omari_themes.lua"
ln -snf "$OMARI_PATH/default/elephant/omari_background_selector.lua" "$HOME/.config/elephant/menus/omari_background_selector.lua"
