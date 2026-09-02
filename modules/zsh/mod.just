# Zsh — install via the detected package manager (config is stowed by `just stow-all`)

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM zsh
