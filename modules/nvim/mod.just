# Neovim (kickstart.nvim) — install neovim + lazygit dependency, then stow config

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM neovim lazygit

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} nvim
