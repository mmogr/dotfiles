# Neovim (LazyVim) — install neovim + lazygit dependency, then stow config

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    $PM neovim lazygit

stow:
    stow -d {{justfile_directory()}} -R nvim
