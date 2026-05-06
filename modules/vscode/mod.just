# VS Code — install via the appropriate method per platform
# Arch: AUR (visual-studio-code-bin)
# macOS: Homebrew cask
# Ubuntu/Debian: snap

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $AUR_PM visual-studio-code-bin
    elif command -v brew > /dev/null 2>&1; then
        brew install --cask visual-studio-code
    elif command -v apt > /dev/null 2>&1; then
        sudo snap install code --classic
    else
        echo "Unsupported platform for VS Code install" >&2 && exit 1
    fi
