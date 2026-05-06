# Zsh — install and stow config

# Install zsh via the detected package manager
install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM zsh

# Stow zsh config
stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} zsh
