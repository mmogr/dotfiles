# Fish shell — install and stow config

# Install fish via the detected package manager
install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM fish

# Stow fish config
stow:
    stow -d {{justfile_directory()}} -R fish
