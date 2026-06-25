# direnv — install and stow config

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM direnv

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} direnv
