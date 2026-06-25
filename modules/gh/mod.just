# GitHub CLI (gh) — install via the detected package manager

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v brew > /dev/null 2>&1; then
        brew install gh
    else
        $PM github-cli
    fi
