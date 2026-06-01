# Set identification from install inputs
if [[ -n ${OMARI_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$OMARI_USER_NAME"
fi

if [[ -n ${OMARI_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$OMARI_USER_EMAIL"
fi
