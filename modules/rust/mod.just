# Rust — install via rustup (same script on all platforms, fully non-interactive)

install:
    #!/usr/bin/env sh
    set -e
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
