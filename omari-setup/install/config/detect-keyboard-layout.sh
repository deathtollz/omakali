# Copy over the keyboard layout that's been set in Arch during install to niri
CONF="/etc/vconsole.conf"
NIRICONF="$HOME/.config/niri/input.kdl"

if grep -q '^XKBLAYOUT=' "$CONF"; then
  layout=$(grep '^XKBLAYOUT=' "$CONF" | cut -d= -f2 | tr -d '"')
  sed -i '/^[[:space:]]*xkb[[:space:]]*{/,/^[[:space:]]*}/{/^[[:space:]]*layout[[:space:]]\+".*"[[:space:]]*$/d}' "$NIRICONF"
  sed -i "/^[[:space:]]*options[[:space:]]/i\            layout \"$layout\"" "$NIRICONF"
fi

if grep -q '^XKBVARIANT=' "$CONF"; then
  variant=$(grep '^XKBVARIANT=' "$CONF" | cut -d= -f2 | tr -d '"')
  sed -i '/^[[:space:]]*xkb[[:space:]]*{/,/^[[:space:]]*}/{/^[[:space:]]*variant[[:space:]]\+".*"[[:space:]]*$/d}' "$NIRICONF"
  sed -i "/^[[:space:]]*options[[:space:]]/i\            variant \"$variant\"" "$NIRICONF"
fi
