# Zed editor — install per platform
# Arch: pacman (zed is in the extra repo)
# macOS: Homebrew
# Ubuntu/Debian: official install script from zed.dev (no apt package available)

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v zed > /dev/null 2>&1 || [ -d "/Applications/Zed.app" ]; then
        echo "Zed already installed — skipping"
        exit 0
    fi
    case "$OS" in
        arch)   $PM zed ;;
        macos)  brew install zed ;;
        debian) curl -fsSL https://zed.dev/install.sh | sh ;;
    esac
