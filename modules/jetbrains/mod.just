# JetBrains Toolbox — install via the appropriate method per platform
# Arch: AUR (jetbrains-toolbox)
# macOS: Homebrew cask
# Ubuntu/Debian: download latest tarball from JetBrains CDN

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $AUR_PM jetbrains-toolbox
    elif command -v brew > /dev/null 2>&1; then
        brew install --cask jetbrains-toolbox
    elif command -v apt > /dev/null 2>&1; then
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
    else
        echo "Unsupported platform for JetBrains Toolbox install" >&2 && exit 1
    fi
