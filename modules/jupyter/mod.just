# JupyterLab — stow config and create local notebook storage

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} jupyter

# Create the local notebook directory under XDG data home (never tracked in git)
dirs:
    mkdir -p "$HOME/.local/share/jupyter/notebooks"

# Build (or rebuild) the custom polyglot container image.
# Only needed when the Containerfile changes; subsequent runs use the layer cache.
build:
    podman compose -f "$HOME/.config/jupyter/compose.yml" build
