# Zed editor — install via the appropriate method per platform
# Arch: pacman (zed is in the extra repo)
# macOS: Homebrew
# Ubuntu/Debian: official install script from zed.dev (no apt package available)

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $PM zed
    elif command -v brew > /dev/null 2>&1; then
        brew install zed
    elif command -v apt > /dev/null 2>&1; then
        curl -fsSL https://zed.dev/install.sh | sh
    else
        echo "Unsupported platform for Zed install" >&2 && exit 1
    fi
