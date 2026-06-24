# Node.js + npm — pin to version 22 via mise (preferred) or system package manager.
# Run `just mise::install` first if mise is not yet available on a fresh machine.

install:
    #!/usr/bin/env sh
    set -e
    if command -v mise > /dev/null 2>&1; then
        echo "Installing Node.js 22 via mise..."
        mise use --global node@22
        echo "Node.js $(node --version) active via mise"
    else
        echo "WARNING: mise not found. For version-pinned installs run: just mise::install"
        echo "Falling back to system package manager (version not pinned)..."
        . "{{justfile_directory()}}/lib/detect.sh"
        if command -v pacman > /dev/null 2>&1; then
            $PM nodejs npm
        elif command -v apt > /dev/null 2>&1; then
            $PM nodejs npm
        elif command -v brew > /dev/null 2>&1; then
            $PM node
        fi
    fi
