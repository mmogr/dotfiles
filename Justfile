# Dotfiles bootstrap and management
# Run `just` or `just --list` to see all available recipes.
# Run `just --choose` for an interactive picker (requires fzf or skim).

# Declare all modules (optional: missing module files never cause errors)
mod? bash    'modules/bash/mod.just'
mod? conda   'modules/conda/mod.just'
mod? dev-db  'modules/dev-db/mod.just'
mod? direnv  'modules/direnv/mod.just'
mod? fish    'modules/fish/mod.just'
mod? gh      'modules/gh/mod.just'
mod? git     'modules/git/mod.just'
mod? jupyter 'modules/jupyter/mod.just'
mod? jetbrains 'modules/jetbrains/mod.just'
mod? lazygit 'modules/lazygit/mod.just'
mod? mise    'modules/mise/mod.just'
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
    just mise::install
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
    just git::init
    just direnv::install
    # Build the JupyterLab polyglot image. This is slow on first run (~15 min)
    # due to the Rust/evcxr compile step, but the layer cache makes subsequent
    # runs fast. Must run after podman::enable-socket.
    just jupyter::build

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
    just git::stow
    just direnv::stow
    just jupyter::stow
    just jupyter::dirs

# Back up any pre-existing default shell files that would collide with stow
backup-defaults:
    #!/usr/bin/env sh
    for f in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.gitconfig"; do
        if [ -e "$f" ] && [ ! -L "$f" ]; then
            echo "Backing up $f -> $f.bak"
            mv "$f" "$f.bak"
        fi
    done

# Check that all stow packages are correctly linked and the repo is clean
check:
    #!/usr/bin/env sh
    DOTFILES={{justfile_directory()}}
    FAILED=0

    # 1. Git cleanliness
    printf "git status ... "
    DIRTY=$(cd "$DOTFILES" && git status --short)
    if [ -z "$DIRTY" ]; then
        echo "OK (clean)"
    else
        echo "DIRTY"
        cd "$DOTFILES" && git status --short | sed 's/^/  /'
        FAILED=1
    fi

    # 2. Stow packages — dry-run restow; any output means something is out of sync
    for PKG in shell fish zsh bash nvim dev-db open-webui jupyter git direnv; do
        printf "stow %-12s ... " "$PKG"
        OUT=$(cd "$DOTFILES" && stow -n -R "$PKG" 2>&1 || true)
        ISSUES=$(printf '%s\n' "$OUT" | grep -E "cannot stow|ERROR" || true)
        if [ -z "$ISSUES" ]; then
            echo "OK"
        else
            echo "OUT OF SYNC"
            echo "$ISSUES" | sed 's/^/  /'
            FAILED=1
        fi
    done

    # Summary
    echo ""
    if [ "$FAILED" -eq 0 ]; then
        echo "All checks passed."
    else
        echo "One or more checks failed — run: just stow-all" >&2
        exit 1
    fi
