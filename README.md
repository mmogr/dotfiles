# Dotfiles

This repo uses GNU Stow with XDG paths so config is tracked in git, while secrets and app data stay local.
Bootstrap automation is handled by [just](https://github.com/casey/just).

## Strategy

- Stow package roots are top-level folders in this repo.
- Each package contains files in their real destination shape (e.g. `.config/...`).
- `stow -R <package>` creates symlinks into `$HOME`.
- `modules/<name>/mod.just` contains install/stow recipes for each tool.
- Adding a new tool: create `modules/<name>/mod.just` + one `mod?` line in `Justfile`.

## Stow Packages

| Package | Symlinks into |
|---|---|
| `shell` | `~/.config/shell/aliases.sh` |
| `fish` | `~/.config/fish/config.fish` |
| `zsh` | `~/.zshrc` |
| `bash` | `~/.bashrc` |
| `nvim` | `~/.config/nvim/` |
| `dev-db` | `~/.config/dev-db/compose.yml` |
| `open-webui` | `~/.config/open-webui/docker-compose.yml`, `.env.example` |

## What Is Tracked vs Local

Tracked:

- Compose/config files, shell configs, editor config.
- Template env files like `.env.example`.

Local only (never tracked):

- `~/.config/open-webui/.env` (secrets)
- Runtime data under `~/.local/share/...`
  - `~/.local/share/open-webui/data`
  - `~/.local/share/dev-db/postgres`
  - `~/.local/share/dev-db/mysql`

## Bootstrap (any supported platform)

Supported platforms: Arch/CachyOS, Ubuntu/Debian, macOS.

1. Install `just` and `stow`:

   **Arch:**   `sudo pacman -S just stow git`
   **Ubuntu:** `sudo apt install just stow git`
   **macOS:**  `brew install just stow git`

2. Clone dotfiles:

   git clone https://github.com/mmogr/dotfiles.git ~/.dotfiles

3. Run one-shot setup (non-interactive, backs up any conflicting default files automatically):

   cd ~/.dotfiles
   just setup

4. Edit secrets file:

   # ~/.config/open-webui/.env was created by setup — add real keys
   $EDITOR ~/.config/open-webui/.env

## Useful just Commands

   just --list        # show all available recipes
   just --choose      # interactive picker (requires fzf or skim)
   just stow-all      # re-link all packages without reinstalling tools

Individual module recipes:

   just conda::install
   just conda::init
   just nvim::install
   just rust::install

## Daily Commands

OpenWebUI:

- `uiup` / `uidown` / `uilog`

Databases on demand:

- `pgup` (start Postgres)
- `myup` (start MySQL)
- `dbdown` (stop both)

## Verify Stow State

   readlink -f ~/.config/open-webui/docker-compose.yml
   readlink -f ~/.config/fish/config.fish
   readlink -f ~/.config/dev-db/compose.yml
   readlink -f ~/.config/nvim/init.lua
   readlink -f ~/.zshrc
   readlink -f ~/.bashrc

Each path should resolve into `~/.dotfiles/...`.