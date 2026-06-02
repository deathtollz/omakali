# Allow the user to change the branding
mkdir -p "$HOME/.config/omari/branding"
cp "$HOME/.local/share/omari/brand" "$HOME/.config/omari/branding/brand"
cp "$HOME/.local/share/omari/logo.txt" "$HOME/.config/omari/branding/screensaver.txt" 2>/dev/null || true
