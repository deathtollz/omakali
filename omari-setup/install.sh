#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Reset to the default OMARI_BRAND to avoid issues with Retry
OMARI_BRAND="${OMARI_BRAND:-Omari}"

# Define Omari locations
export OMARI_PATH="$HOME/.local/share/omari"
export OMARI_INSTALL="$OMARI_PATH/install"
export OMARI_INSTALL_LOG_FILE="/var/log/${OMARI_BRAND,,}-install.log"
export PATH="$OMARI_PATH/bin:$PATH"

# Install
source "$OMARI_INSTALL/helpers/all.sh"
source "$OMARI_INSTALL/preflight/all.sh"
source "$OMARI_INSTALL/packaging/all.sh"
source "$OMARI_INSTALL/config/all.sh"
# source "$OMARI_INSTALL/login/all.sh"
source "$OMARI_INSTALL/post-install/all.sh"