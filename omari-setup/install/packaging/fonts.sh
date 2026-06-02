mkdir -p "$HOME/.local/share/fonts"
if [[ -f "$HOME/.local/share/omari/config/fonts/niri.ttf" ]]; then
  cp "$HOME/.local/share/omari/config/fonts/niri.ttf" "$HOME/.local/share/fonts/"
fi
fc-cache -f