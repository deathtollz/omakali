# In a live-build chroot environment USER/HOME may not be set.
# Pre-set OMARI_USER_NAME and OMARI_USER_EMAIL from env if available,
# otherwise use silent defaults — no interactive prompts during build.
SYSTEM_NAME=$(getent passwd "${USER:-root}" 2>/dev/null | cut -d ':' -f 5 | cut -d ',' -f 1 || echo "Kali User")
SYSTEM_NAME="${SYSTEM_NAME:-Kali User}"

if [[ -t 0 && -n "${TERM:-}" && "${OMARI_NONINTERACTIVE:-0}" != "1" ]]; then
  export OMARI_USER_NAME=$(gum input --placeholder "Enter full name" --value "$SYSTEM_NAME" --prompt "Name> ")
  export OMARI_USER_EMAIL=$(gum input --placeholder "Enter email address" --prompt "Email> ")
else
  export OMARI_USER_NAME="${OMARI_USER_NAME:-${SYSTEM_NAME}}"
  export OMARI_USER_EMAIL="${OMARI_USER_EMAIL:-user@localhost}"
fi
