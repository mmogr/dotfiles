# Stow the shared shell aliases package

stow:
    stow -d {{justfile_directory()}} -R shell
