# Copy over Omari configs
mkdir -p ~/.config
shopt -s nullglob dotglob
cp -R ~/.local/share/omari/config/* ~/.config/
shopt -u nullglob dotglob

# Configure the bash shell using Omari defaults
[[ -f ~/.local/share/omari/default/bashrc ]]       && cp ~/.local/share/omari/default/bashrc ~/.bashrc
[[ -f ~/.local/share/omari/default/bash_profile ]] && cp ~/.local/share/omari/default/bash_profile ~/.bash_profile