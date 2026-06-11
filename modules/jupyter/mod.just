# JupyterLab — stow config and create local notebook storage

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} jupyter

# Create local data directories under XDG data home (never tracked in git).
# conda-envs is mounted into /opt/conda/envs inside the container so user-created
# conda environments persist across container restarts.
dirs:
    mkdir -p "$HOME/.local/share/jupyter/notebooks" \
             "$HOME/.local/share/jupyter/conda-envs"

# Build (or rebuild) the custom polyglot container image.
# Only needed when the Containerfile changes; subsequent runs use the layer cache.
build:
    podman compose -f "$HOME/.config/jupyter/compose.yml" build
