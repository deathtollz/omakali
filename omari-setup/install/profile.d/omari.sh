# Omari PATH setup for all login shells (sourced by /etc/profile)
# Ensures niri keybinds (Mod+Space, etc.) can find omari-* scripts.
# This file is deployed by install-omari-niri.sh.

OMARI_PATH="${HOME:-$XDG_DATA_HOME}/.local/share/omari"
if [ -d "$OMARI_PATH/bin" ]; then
    PATH="$OMARI_PATH/bin:$PATH"
    export OMARI_PATH
fi
