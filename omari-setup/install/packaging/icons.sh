# Copy all bundled icons to the applications/icons directory
ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"
shopt -s nullglob
cp "$HOME/.local/share/omari/applications/desktop/icons/"*.png "$ICON_DIR/"
shopt -u nullglob
