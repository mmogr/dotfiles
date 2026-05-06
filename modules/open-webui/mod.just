# Open WebUI — stow config, create data directories, and initialize secrets

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} open-webui

dirs:
    mkdir -p "$HOME/.config/open-webui"
    mkdir -p "$HOME/.local/share/open-webui/data"

# Copy .env.example to local .env (never overwrites an existing file)
secrets:
    #!/usr/bin/env sh
    set -e
    TARGET="$HOME/.config/open-webui/.env"
    EXAMPLE="$HOME/.config/open-webui/.env.example"
    if [ -f "$TARGET" ]; then
        echo ".env already exists, skipping."
    else
        cp "$EXAMPLE" "$TARGET"
        chmod 600 "$TARGET"
        echo "Created $TARGET — edit it to set real secrets."
    fi
