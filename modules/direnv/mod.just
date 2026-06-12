# direnv — install and stow config

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $PM direnv
    elif command -v apt-get > /dev/null 2>&1; then
        $PM direnv
    elif command -v brew > /dev/null 2>&1; then
        brew install direnv
    else
        echo "Unsupported platform — install direnv manually: https://direnv.net" >&2
        exit 1
    fi

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} direnv
