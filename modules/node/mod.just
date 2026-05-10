# Node.js + npm — install via the detected package manager

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $PM nodejs npm
    elif command -v apt > /dev/null 2>&1; then
        $PM nodejs npm
    elif command -v brew > /dev/null 2>&1; then
        $PM node
    fi
