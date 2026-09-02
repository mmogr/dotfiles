# Dotfiles bootstrap and management
# Run `just` or `just --list` to see all available recipes.
# Run `just --choose` for an interactive picker (requires fzf or skim).
#
# Layout:
#   <package>/          stow package — files in their real $HOME-relative shape
#   modules/<tool>/     just module — install/init recipes for one tool
#   lib/                helpers sourced by recipes (detect.sh, paths.sh, stow-safe.sh)
#
# Adding a stow-only tool: create the package folder and add its name to `packages`.
# Adding a tool that needs installing: also add modules/<tool>/mod.just + a `mod` line.

# Stow packages, in stow order. Single source of truth for stow-all and check.
packages := "shell bash zsh fish git direnv mise nvim dev-db open-webui jupyter"

mod conda      'modules/conda/mod.just'
mod fish       'modules/fish/mod.just'
mod git        'modules/git/mod.just'
mod jetbrains  'modules/jetbrains/mod.just'
mod jupyter    'modules/jupyter/mod.just'
mod mise       'modules/mise/mod.just'
mod open-webui 'modules/open-webui/mod.just'
mod podman     'modules/podman/mod.just'
mod vscode     'modules/vscode/mod.just'
mod zed        'modules/zed/mod.just'
mod zsh        'modules/zsh/mod.just'

# ── Setup ──────────────────────────────────────────────────────────────────────
#
# Tiers:
#   core        every machine — shells, conda, mise-managed CLI tools, git identity
#   desktop     VS Code, Zed, JetBrains Toolbox, VS Code agent files
#   containers  podman, dev databases, JupyterLab image, Open WebUI
#
# `just setup` asks once which tiers this machine gets (saved to
# ~/.config/dotfiles/profile) and is silent on every later run.

# Bootstrap this machine: stow, ask once what it is for, install the chosen tiers
setup: stow-all
    #!/usr/bin/env sh
    set -e
    cd "{{justfile_directory()}}"
    PROFILE="$HOME/.config/dotfiles/profile"
    if [ ! -f "$PROFILE" ]; then
        if ( : < /dev/tty ) 2>/dev/null; then
            just profile
        else
            just profile-default
        fi
    fi
    . "$PROFILE"
    just setup-core
    if [ "${DESKTOP:-no}" = yes ]; then
        just setup-desktop
    fi
    if [ "${CONTAINERS:-no}" = yes ]; then
        just setup-containers
    fi
    echo ""
    echo "Setup complete. Restart your shell or run: exec \$SHELL"

# Tier: every machine — shells, conda, mise tools (node, rust, gh, lazygit, direnv, neovim), git identity
setup-core:
    just fish::install
    just zsh::install
    just conda::install
    just conda::init
    just mise::install
    just git::init

# Tier: VS Code (+ agent files), Zed, JetBrains Toolbox
setup-desktop:
    just vscode::install
    just vscode::stow
    just zed::install
    just jetbrains::install

# Tier: podman, Open WebUI secrets, JupyterLab image (slow on first build)
setup-containers:
    just podman::install
    just podman::enable-socket
    just podman::machine-init
    just open-webui::secrets
    just jupyter::build

# Ask what this machine is for and save the answers (re-run any time to change them)
profile:
    #!/usr/bin/env sh
    set -e
    PROFILE="$HOME/.config/dotfiles/profile"
    MISE_LOCAL="$HOME/.config/mise/conf.d/local.toml"
    if ! ( : < /dev/tty ) 2>/dev/null; then
        echo "just profile needs a terminal. Without one, setup uses core-only defaults (just profile-default)." >&2
        exit 1
    fi
    # Current answers become the defaults
    RUBY=no; DESKTOP=yes; CONTAINERS=yes
    if [ -f "$PROFILE" ]; then
        . "$PROFILE"
    fi
    ask() {
        # $1 question, $2 current default (yes|no); prints the answer
        if [ "$2" = yes ]; then hint="[Y/n]"; else hint="[y/N]"; fi
        printf '%s %s ' "$1" "$hint" > /dev/tty
        read -r reply < /dev/tty
        case "$reply" in
            y|Y|yes|YES) echo yes ;;
            n|N|no|NO)   echo no ;;
            *)           echo "$2" ;;
        esac
    }
    echo "Machine profile — core (shells, conda, mise tools incl. Rust, git) is always installed."
    RUBY=$(ask "Ruby via mise? (compiled from source, several minutes)" "$RUBY")
    DESKTOP=$(ask "Desktop apps? (VS Code, Zed, JetBrains Toolbox, VS Code agents)" "$DESKTOP")
    CONTAINERS=$(ask "Containers? (podman, dev databases, JupyterLab image, Open WebUI)" "$CONTAINERS")
    mkdir -p "$(dirname "$PROFILE")" "$(dirname "$MISE_LOCAL")"
    {
        echo "# Written by \`just profile\` — re-run it to change these answers."
        echo "RUBY=$RUBY"
        echo "DESKTOP=$DESKTOP"
        echo "CONTAINERS=$CONTAINERS"
    } > "$PROFILE"
    {
        echo "# Per-machine mise tools — written by \`just profile\`, never tracked."
        echo "[tools]"
        if [ "$RUBY" = yes ]; then echo 'ruby = "3"'; fi
    } > "$MISE_LOCAL"
    echo "Saved $PROFILE"

# Write the core-only profile without asking (used when no terminal is available)
profile-default:
    #!/usr/bin/env sh
    set -e
    PROFILE="$HOME/.config/dotfiles/profile"
    MISE_LOCAL="$HOME/.config/mise/conf.d/local.toml"
    mkdir -p "$(dirname "$PROFILE")" "$(dirname "$MISE_LOCAL")"
    printf '# Written by `just profile-default` (no terminal). Run `just profile` to change.\nRUBY=no\nDESKTOP=no\nCONTAINERS=no\n' > "$PROFILE"
    printf '# Per-machine mise tools — written by `just profile`, never tracked.\n[tools]\n' > "$MISE_LOCAL"
    echo "No terminal — wrote core-only profile to $PROFILE (run: just profile to change it)"

# ── Stow ───────────────────────────────────────────────────────────────────────

# Re-link all stow packages (safe to re-run)
stow-all: backup-defaults
    #!/usr/bin/env sh
    set -e
    for pkg in {{packages}}; do
        sh "{{justfile_directory()}}/lib/stow-safe.sh" "{{justfile_directory()}}" "$pkg"
    done

# Back up pre-existing default files that would collide with stow (only files we replace)
backup-defaults:
    #!/usr/bin/env sh
    for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.gitconfig"; do
        if [ -e "$f" ] && [ ! -L "$f" ]; then
            echo "Backing up $f -> $f.bak"
            mv "$f" "$f.bak"
        fi
    done

# Check that all stow packages are correctly linked and the repo is clean
check:
    #!/usr/bin/env sh
    DOTFILES="{{justfile_directory()}}"
    FAILED=0

    # 1. Git cleanliness
    printf "git status ... "
    DIRTY=$(cd "$DOTFILES" && git status --short)
    if [ -z "$DIRTY" ]; then
        echo "OK (clean)"
    else
        echo "DIRTY"
        printf '%s\n' "$DIRTY" | sed 's/^/  /'
        FAILED=1
    fi

    # 2. Stow packages — dry-run restow; a non-zero exit or conflict output means out of sync
    check_stow() {
        # $1 label, then the stow arguments
        label="$1"; shift
        printf "stow %-12s ... " "$label"
        if OUT=$(cd "$DOTFILES" && stow -n -R "$@" 2>&1) && ! printf '%s\n' "$OUT" | grep -qE "cannot stow|ERROR"; then
            echo "OK"
        else
            echo "OUT OF SYNC"
            printf '%s\n' "$OUT" | grep -v "simulation mode" | sed 's/^/  /'
            FAILED=1
        fi
    }
    for PKG in {{packages}}; do
        check_stow "$PKG" "$PKG"
    done

    # 3. vscode/agents — desktop tier, custom target; only checked once that target exists
    . "$DOTFILES/lib/paths.sh"
    if [ -d "$VSCODE_PROMPTS_DIR" ]; then
        check_stow "vscode" -d "$DOTFILES/vscode" -t "$VSCODE_PROMPTS_DIR" agents
    else
        printf "stow %-12s ... skipped (desktop tier not installed)\n" "vscode"
    fi

    # Summary
    echo ""
    if [ "$FAILED" -eq 0 ]; then
        echo "All checks passed."
    else
        echo "One or more checks failed — run: just stow-all" >&2
        exit 1
    fi
