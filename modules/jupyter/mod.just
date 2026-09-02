# JupyterLab polyglot image (config is stowed by `just stow-all`; data dirs are
# created on demand by the podman-stack helper behind nbup/nbdown)

# Build (or rebuild) the custom polyglot container image.
# Only needed when the Containerfile or environment.yml changes; later runs use
# the layer cache. Slow on first run (~15 min) because of the Rust/evcxr compile.
build:
    "$HOME/.local/bin/podman-stack" jupyter build
