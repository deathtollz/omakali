mkdir -p ~/.config
echo "en_US" > ~/.config/user-dirs.locale

# Create the standard user directories if they don't exist, and set up the XDG user dirs configuration.
mkdir -p ~/Documents ~/Downloads ~/Pictures ~/Videos ~/Music ~/.config/gtk-3.0

cat > ~/.config/user-dirs.dirs << 'EOF'
XDG_DESKTOP_DIR="$HOME"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME"
XDG_PUBLICSHARE_DIR="$HOME"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg_updated=false
  for locale in en_US.UTF-8 en_US C.UTF-8 C; do
    if LC_ALL="$locale" xdg-user-dirs-update --force >/dev/null 2>&1; then
      xdg_updated=true
      break
    fi
  done

  if [[ $xdg_updated == false ]]; then
    xdg-user-dirs-update --force || true
  fi
fi

rmdir ~/Templates ~/Public ~/Desktop 2>/dev/null || true

cat > ~/.config/gtk-3.0/bookmarks << EOF
file://$HOME/Documents Documents
file://$HOME/Downloads Downloads
file://$HOME/Pictures Pictures
file://$HOME/Videos Videos
file://$HOME/Music Music
EOF

