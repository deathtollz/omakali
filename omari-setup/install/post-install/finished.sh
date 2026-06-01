stop_install_log

# Clean up temporary environment file
rm -f "$HOME/.local/state/omari/.env_update"

echo_in_style() {
  local message="$1"
  if [[ -t 0 && "${OMARI_NONINTERACTIVE:-0}" != "1" ]]; then
    local padding="0 $((PADDING_LEFT + 32)) 0 0"
    gum style --padding "$padding" --border-foreground "#00FF00" --border "thick" --margin "1" <<<"$message"
  else
    echo "$message"
  fi
}

echo
echo "=== Omari Installation Complete ==="

if [[ -f $OMARI_INSTALL_LOG_FILE ]] && grep -q "Total:" "$OMARI_INSTALL_LOG_FILE" 2>/dev/null; then
  TOTAL_TIME=$(tail -n 20 "$OMARI_INSTALL_LOG_FILE" | grep "^Total:" | sed 's/^Total:[[:space:]]*//')
  [[ -n $TOTAL_TIME ]] && echo_in_style "Installed in $TOTAL_TIME"
else
  echo_in_style "Finished installing"
fi

# Skip reboot prompt in non-interactive/build mode
if [[ ! -t 0 || "${OMARI_NONINTERACTIVE:-0}" == "1" ]]; then
  echo "Build mode: skipping reboot prompt."
  exit 0
fi

if gum confirm --padding "0 0 0 $((PADDING_LEFT + 32))" --show-help=false --default --affirmative "Reboot Now" --negative "" ""; then
  clear
  if command -v systemctl &>/dev/null; then
    sudo systemctl reboot --no-wall 2>/dev/null
  else
    sudo reboot 2>/dev/null
  fi
fi
