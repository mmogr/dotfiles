# Rust — install via rustup (same script on all platforms, fully non-interactive)

install:
    #!/usr/bin/env sh
    set -e
    if command -v cargo >/dev/null 2>&1; then
        echo "Rust already installed ($(rustc --version))"
        exit 0
    fi
    # --no-modify-path: shell configs in this repo already export ~/.cargo/bin;
    # letting rustup also patch profiles causes Permission denied on macOS system
    # files such as /Users/$USER/.tcshrc that rustup tries to amend.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
