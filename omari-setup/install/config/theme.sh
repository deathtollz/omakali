# Set links for Nautilus action icons
# Use Papirus-Dark icon theme (available via papirus-icon-theme on all supported distros)
ICON_THEME_DIR=""
for candidate in /usr/share/icons/Papirus-Dark /usr/share/icons/Adwaita; do
  if [[ -d "$candidate" ]]; then
    ICON_THEME_DIR="$candidate"
    break
  fi
done

if [[ -n "$ICON_THEME_DIR" ]]; then
  sudo ln -snf "$ICON_THEME_DIR/symbolic/actions/go-previous-symbolic.svg" \
    "$ICON_THEME_DIR/scalable/actions/go-previous-symbolic.svg" 2>/dev/null || true
  sudo ln -snf "$ICON_THEME_DIR/symbolic/actions/go-next-symbolic.svg" \
    "$ICON_THEME_DIR/scalable/actions/go-next-symbolic.svg" 2>/dev/null || true
fi

# Setup user theme folder
mkdir -p "$HOME/.config/omari/themes"

# Set initial theme
omari-theme-set "Tokyo Night"

# Set specific app links for current theme
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$HOME/.config/omari/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"

mkdir -p "$HOME/.config/mako"
ln -snf "$HOME/.config/omari/current/theme/mako.ini" "$HOME/.config/mako/config"
