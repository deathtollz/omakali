# omari-niri-installer

Install the [Niri](https://github.com/YaLTeR/niri) scrollable-tiling Wayland
compositor (**built from source**) plus the full
[Omari](https://codeberg.org/omakasui/omari-setup) styling, themes and
keybindings on a **fresh install of Kali Linux** — no ISO build required.

This is the standalone, post-install counterpart to the
[`omari-kali`](https://github.com/deathtollz/omari-kali) Live ISO. It runs the
same proven steps against an already-installed Kali system and the *invoking*
user's home directory.

## Quick start

On a Kali (or Debian) host, **as your normal user** (not root — it `sudo`s where
needed):

```console
git clone https://github.com/deathtollz/omari-niri-installer.git
cd omari-niri-installer
./install-omari-niri.sh
```

Then log out and choose the **Niri** session at your login screen.

## What it does

1. Configures the [omakasui APT repositories](https://packages.omakasui.org),
   cleanly pinned so they can never override Kali system libraries.
2. Installs the Omari base + "lock" packages (Kali-native, incl. SDDM).
3. Installs the omakasui-sourced apps (walker, **elephant-all**, swayosd,
   wiremix, starship, …).
4. **Builds and installs Niri from source** (v26.04) — `libdisplay-info1/2` are
   not packaged for Kali, so the distro/omakasui binary can't be used. Installs
   the binary, `niri-session`, the `niri.desktop` session, and the
   `niri.service` / `niri-shutdown.target` systemd user units.
5. Lays the Omari config + all 10 themes into `~/.local/share/omari` and
   `~/.config` (Tokyo Night pre-applied).
6. Links the Elephant menu providers into `~/.config/elephant/menus` so the
   **theme picker is populated** (`omari_themes.lua`, background selector, …).
7. De-duplicates the waybar/mako/hypridle daemons (the packaged systemd user
   services are disabled so Niri's `autostart.kdl` is the single source — no
   more two stacked waybars).
8. Adds a selectable **Niri** session at the login screen.

## Options

```console
./install-omari-niri.sh --autologin   # also enable SDDM autologin into niri
./install-omari-niri.sh --skel        # also seed /etc/skel for future users
./install-omari-niri.sh -y            # don't prompt for confirmation
./install-omari-niri.sh --help        # full usage
```

The script is **idempotent** — safe to re-run (it re-stages the payload and
rebuilds Niri).

## Default keybindings

| Keys | Action |
| --- | --- |
| `Mod`+`Space` | App launcher (walker) |
| `Mod`+`Return` | Terminal (foot) |
| `Mod`+`A` | Terminal (alacritty) |
| `Mod`+`K` | Keybindings cheat-sheet |
| `Mod`+`Shift`+`Ctrl`+`Space` | Theme picker |

(`Mod` is the Super/Windows key.)

## Requirements

* Kali Linux (or Debian), **amd64**, with internet access.
* Run as a normal user with `sudo` privileges. **Do not run as root.**

## Layout

```
install-omari-niri.sh   # the installer
omari-setup/            # the Omari payload it installs (configs, themes,
                        # bin helpers, install scripts, packaging/niri-build.sh)
```

## Credits

* Omari setup — omakasui (<https://codeberg.org/omakasui/omari-setup>).
* Niri — YaLTeR (<https://github.com/YaLTeR/niri>).
