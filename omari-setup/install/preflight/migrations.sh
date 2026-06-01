omari_migrations_state_path=~/.local/state/omari/migrations
mkdir -p $omari_migrations_state_path

for file in ~/.local/share/omari/migrations/*.sh; do
  touch "$omari_migrations_state_path/$(basename "$file")"
done
