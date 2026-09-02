# mise — tool version manager (https://mise.jdx.dev). Owns the CLI dev tools:
#   node, rust, gh, lazygit, direnv, neovim   (tracked: mise/.config/mise/config.toml)
#   per-machine extras such as ruby           (~/.config/mise/conf.d/local.toml, from `just profile`)

# Install the mise binary if missing, then every tool from the config files
install:
    #!/usr/bin/env sh
    set -e
    MISE="$HOME/.local/bin/mise"
    if [ ! -x "$MISE" ]; then
        echo "Installing mise..."
        curl -fsSL https://mise.run | sh
    fi
    echo "mise $("$MISE" --version)"
    # Explicit binary path: on a fresh machine the new shell config (which puts
    # ~/.local/bin on PATH and activates mise) has not been loaded yet.
    "$MISE" install --yes
    echo ""
    "$MISE" ls
    echo "Restart your shell so 'mise activate' puts these tools on PATH."

# Upgrade every mise-managed tool to the newest version its pin allows
upgrade:
    "$HOME/.local/bin/mise" upgrade --yes

# Show mise-managed tools that have newer versions available
outdated:
    "$HOME/.local/bin/mise" outdated
