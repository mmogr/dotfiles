# Zsh — install and stow config

# Install zsh via the detected package manager
install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM zsh

# Stow zsh config
stow:
    stow -d {{justfile_directory()}} -R zsh
