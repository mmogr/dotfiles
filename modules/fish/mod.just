# Fish shell — install and stow config

# Install fish via the detected package manager
install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM fish

# Stow fish config
stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} fish
