# Bash — stow config only (bash is pre-installed on all supported platforms)

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} bash
