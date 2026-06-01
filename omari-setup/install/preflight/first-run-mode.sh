#!/bin/bash
# Set first-run mode marker so we can install stuff post-installation
mkdir -p ~/.local/state/omari
touch ~/.local/state/omari/first-run.mode

# Register systemd user service to auto-run first-run script on next login
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/omari-first-run.service <<SVCEOF
[Unit]
Description=Omari first-run setup
After=default.target
[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus
ExecStart=/bin/bash $OMARI_PATH/bin/omari-cmd-first-run
ExecStartPost=systemctl --user disable omari-first-run.service
RemainAfterExit=no
[Install]
WantedBy=default.target
SVCEOF

# systemctl --user doesn't work in a chroot — skip daemon-reload/enable here.
# The service file is in place; it will be enabled on first login instead.
if [[ ! -e /run/systemd/private ]]; then
  echo "Running in chroot — skipping systemctl --user commands, service will activate on first login."
else
  systemctl --user daemon-reload
  systemctl --user enable omari-first-run.service
fi

# Setup sudo-less access for first-run
# /etc/sudoers.d must exist (it does on a real system; pre-created in chroot hook)
mkdir -p /etc/sudoers.d
cat > /etc/sudoers.d/first-run <<SUDOEOF
Defaults:${USER:-root} !use_pty
Cmnd_Alias FIRST_RUN_CLEANUP = /usr/bin/rm -f /etc/sudoers.d/first-run
${USER:-root} ALL=(ALL) NOPASSWD: /usr/bin/systemctl *
${USER:-root} ALL=(ALL) NOPASSWD: /usr/bin/ufw *
${USER:-root} ALL=(ALL) NOPASSWD: /usr/sbin/ufw *
${USER:-root} ALL=(ALL) NOPASSWD: /usr/local/bin/ufw-docker *
${USER:-root} ALL=(ALL) NOPASSWD: /usr/bin/gtk-update-icon-cache
${USER:-root} ALL=(ALL) NOPASSWD: FIRST_RUN_CLEANUP
SUDOEOF
chmod 440 /etc/sudoers.d/first-run
