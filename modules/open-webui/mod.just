# Open WebUI — initialize local secrets (config is stowed by `just stow-all`;
# the data dir is created on demand by the podman-stack helper behind uiup)

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
