# Copy over Omari configs
mkdir -p ~/.config
shopt -s nullglob dotglob
cp -R ~/.local/share/omari/config/* ~/.config/
shopt -u nullglob dotglob

# Fix foot include path for current user
if [[ -f ~/.config/foot/foot.ini ]]; then
  sed -i "s|/home/[^/]*/\.config|$HOME/.config|g" ~/.config/foot/foot.ini
fi

# Configure the bash shell using Omari defaults
[[ -f ~/.local/share/omari/default/bashrc ]]       && cp ~/.local/share/omari/default/bashrc ~/.bashrc
[[ -f ~/.local/share/omari/default/bash_profile ]] && cp ~/.local/share/omari/default/bash_profile ~/.bash_profile

# Configure zsh if it is the current shell
if [[ $SHELL == *zsh ]] || [[ -f ~/.zshrc ]]; then
  if ! grep -q "OMARI_PATH" ~/.zshrc 2>/dev/null; then
    cat ~/.local/share/omari/default/zshrc >> ~/.zshrc
  fi
fi