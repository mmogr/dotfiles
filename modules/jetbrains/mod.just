# JetBrains Toolbox — install per platform
# Arch: AUR (jetbrains-toolbox)
# macOS: Homebrew cask
# Ubuntu/Debian: download the latest tarball from the JetBrains CDN

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v jetbrains-toolbox > /dev/null 2>&1 || [ -d "/Applications/JetBrains Toolbox.app" ]; then
        echo "JetBrains Toolbox already installed — skipping"
        exit 0
    fi
    case "$OS" in
        arch)  aur_install jetbrains-toolbox ;;
        macos) brew install --cask jetbrains-toolbox ;;
        debian)
            LATEST_URL=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" \
                | grep -o '"linux":{"link":"[^"]*"' \
                | grep -o 'https://[^"]*')
            TMPTAR=$(mktemp)
            TMPDIR=$(mktemp -d)
            curl -fsSL "$LATEST_URL" -o "$TMPTAR"
            tar -xzf "$TMPTAR" -C "$TMPDIR"
            TOOLBOX_BIN=$(find "$TMPDIR" -name 'jetbrains-toolbox' -type f)
            mkdir -p "$HOME/.local/bin"
            mv "$TOOLBOX_BIN" "$HOME/.local/bin/jetbrains-toolbox"
            rm -rf "$TMPTAR" "$TMPDIR"
            echo "JetBrains Toolbox installed to ~/.local/bin/jetbrains-toolbox"
            ;;
    esac
