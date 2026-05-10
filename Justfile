# Dotfiles bootstrap and management
# Run `just` or `just --list` to see all available recipes.
# Run `just --choose` for an interactive picker (requires fzf or skim).

# Declare all modules (optional: missing module files never cause errors)
mod? bash    'modules/bash/mod.just'
mod? conda   'modules/conda/mod.just'
mod? dev-db  'modules/dev-db/mod.just'
mod? fish    'modules/fish/mod.just'
mod? gh      'modules/gh/mod.just'
mod? jetbrains 'modules/jetbrains/mod.just'
mod? lazygit 'modules/lazygit/mod.just'
mod? node    'modules/node/mod.just'
mod? nvim    'modules/nvim/mod.just'
mod? open-webui 'modules/open-webui/mod.just'
mod? podman  'modules/podman/mod.just'
mod? rust    'modules/rust/mod.just'
mod? shell   'modules/shell/mod.just'
mod? vscode  'modules/vscode/mod.just'
mod? zed     'modules/zed/mod.just'
mod? zsh     'modules/zsh/mod.just'

# ── Meta-recipes ───────────────────────────────────────────────────────────────

# Bootstrap a brand-new machine from scratch (one-shot, fully non-interactive)
setup: stow-all
    #!/usr/bin/env sh
    set -e
    cd {{justfile_directory()}}
    just conda::install
    just conda::init
    just rust::install
    just node::install
    just lazygit::install
    just nvim::install
    just gh::install
    just podman::install
    just podman::enable-socket
    just podman::machine-init
    just vscode::install
    just zed::install
    just jetbrains::install
    just open-webui::secrets

# Re-link all stow packages and create required data directories (safe to re-run)
stow-all: backup-defaults
    just shell::stow
    just fish::stow
    just zsh::stow
    just bash::stow
    just nvim::stow
    just dev-db::stow
    just dev-db::dirs
    just open-webui::stow
    just open-webui::dirs

# Back up any pre-existing default shell files that would collide with stow
backup-defaults:
    #!/usr/bin/env sh
    for f in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
        if [ -e "$f" ] && [ ! -L "$f" ]; then
            echo "Backing up $f -> $f.bak"
            mv "$f" "$f.bak"
        fi
    done
