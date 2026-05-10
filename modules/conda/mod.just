# Miniconda — install and initialize for all shells

# Download and silently install Miniconda3 to ~/.local/share/miniconda3
install:
    #!/usr/bin/env sh
    set -e
    OS=$(uname -s)
    ARCH=$(uname -m)
    case "$OS-$ARCH" in
        Linux-x86_64)  INSTALLER="Miniconda3-latest-Linux-x86_64.sh" ;;
        Linux-aarch64) INSTALLER="Miniconda3-latest-Linux-aarch64.sh" ;;
        Darwin-arm64)  INSTALLER="Miniconda3-latest-MacOSX-arm64.sh" ;;
        Darwin-x86_64) INSTALLER="Miniconda3-latest-MacOSX-x86_64.sh" ;;
        *) echo "Unsupported platform: $OS-$ARCH" >&2 && exit 1 ;;
    esac
    TMPFILE=$(mktemp)
    curl -fsSL "https://repo.anaconda.com/miniconda/$INSTALLER" -o "$TMPFILE"
    bash "$TMPFILE" -b -p "$HOME/.local/share/miniconda3"
    rm "$TMPFILE"

# Initialize conda for bash, zsh, and fish
init:
    "$HOME/.local/share/miniconda3/bin/conda" init bash zsh fish
