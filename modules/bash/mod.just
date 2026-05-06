# Bash — stow config only (bash is pre-installed on all supported platforms)

stow:
    stow -d {{justfile_directory()}} -R bash
