# mise — universal tool version manager (https://mise.jdx.dev)
# Manages Node.js, Ruby, and other runtime versions across Linux and macOS.
# This must run before node::install so mise is available when node is pinned.

install:
    #!/usr/bin/env sh
    set -e
    if command -v mise > /dev/null 2>&1; then
        echo "mise already installed ($(mise --version))"
        exit 0
    fi
    echo "Installing mise..."
    curl https://mise.run | sh
    echo ""
    echo "mise installed to ~/.local/bin/mise"
    echo "Restart your shell to activate it, or run:"
    echo "  eval \"\$(~/.local/bin/mise activate sh)\""
