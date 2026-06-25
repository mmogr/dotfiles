# Podman + podman-compose — install and configure rootless socket
#
# Linux: install via pm, enable the rootless user socket
# macOS: install via brew, initialize and start a podman machine (required on macOS)

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v pacman > /dev/null 2>&1; then
        $PM podman podman-compose
    elif command -v apt > /dev/null 2>&1; then
        $PM podman podman-compose
    elif command -v brew > /dev/null 2>&1; then
        brew install podman podman-compose
    else
        echo "Unsupported platform for podman install" >&2 && exit 1
    fi

# Enable the rootless Podman socket (Linux only — not needed on macOS)
enable-socket:
    #!/usr/bin/env sh
    set -e
    if [ "$(uname -s)" = "Linux" ]; then
        systemctl --user enable --now podman.socket
        echo "Podman user socket enabled."
    else
        echo "Skipping socket setup (not Linux)."
    fi

# Initialize and start a Podman machine (macOS only)
machine-init:
    #!/usr/bin/env sh
    set -e
    if [ "$(uname -s)" = "Darwin" ]; then
        if podman machine inspect podman-machine-default > /dev/null 2>&1; then
            echo "Podman machine already exists — ensuring it is running..."
            podman machine start 2>/dev/null || true
        else
            # 4 GB RAM: the default 2 GB is too small to compile evcxr_jupyter
            # (rust-analyzer crates are OOM-killed during cargo install)
            podman machine init --memory 4096
            podman machine start
            echo "Podman machine initialized and started."
        fi
    else
        echo "Skipping machine init (not macOS)."
    fi
