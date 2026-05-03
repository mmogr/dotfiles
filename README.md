# Dotfiles

This repo uses GNU Stow with XDG paths so config is tracked in git, while secrets and app data stay local.

## Strategy

- Stow package roots are top-level folders in this repo.
- Each package contains files in their real destination shape (for example `.config/...`).
- `stow -R <package>` creates symlinks into `$HOME`.

Current packages:

- `open-webui` -> `~/.config/open-webui/docker-compose.yml`, `~/.config/open-webui/.env.example`
- `fish` -> `~/.config/fish/config.fish`
- `dev-db` -> `~/.config/dev-db/compose.yml`

## What Is Tracked vs Local

Tracked:

- Compose/config files and shell config.
- Template env files like `.env.example`.

Local only (not tracked):

- `~/.config/open-webui/.env` (secrets)
- Runtime data under `~/.local/share/...`
  - `~/.local/share/open-webui/data`
  - `~/.local/share/dev-db/postgres`
  - `~/.local/share/dev-db/mysql`

## Fresh CachyOS Bootstrap

1. Install base tools:

   sudo pacman -S --needed git stow podman podman-compose

2. Clone dotfiles:

   git clone https://github.com/mmogr/dotfiles.git ~/.dotfiles

3. Apply symlinks:

   cd ~/.dotfiles
   stow -R open-webui fish dev-db

4. Create required local dirs:

   mkdir -p ~/.config/open-webui
   mkdir -p ~/.local/share/open-webui/data
   mkdir -p ~/.local/share/dev-db/postgres ~/.local/share/dev-db/mysql

5. Create local secrets file:

   cp -n ~/.config/open-webui/.env.example ~/.config/open-webui/.env
   chmod 600 ~/.config/open-webui/.env
   # then edit ~/.config/open-webui/.env and set real keys

6. Enable rootless Podman socket and auto-update timer:

   systemctl --user enable --now podman.socket
   systemctl --user enable --now podman-auto-update.timer

7. Reload fish config (or relogin):

   source ~/.config/fish/config.fish

## Daily Commands

OpenWebUI:

- `webui up -d`
- `webui down`
- `uiup`
- `uidown`
- `uilog`

Databases on demand:

- `pgup` (start Postgres)
- `myup` (start MySQL)
- `dbdown` (stop both)

## Verify Stow State

Run:

readlink -f ~/.config/open-webui/docker-compose.yml
readlink -f ~/.config/fish/config.fish
readlink -f ~/.config/dev-db/compose.yml

Each path should resolve into `~/.dotfiles/...`.