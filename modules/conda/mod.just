# Conda — install and initialize for all shells
# Primary path (AUR/CachyOS): /opt/miniconda3
# Fallback path (manual/macOS): ~/.local/share/miniconda3

# Install via AUR using paru (primary — CachyOS/Arch; managed by paru -Syu)
install-aur:
    #!/usr/bin/env sh
    set -e
    paru -S --noconfirm miniconda3
    # Prevent base env from hijacking system Python (user-level setting)
    /opt/miniconda3/bin/conda config --set auto_activate_base false
    echo "miniconda3 installed to /opt/miniconda3"
    echo "Run: just conda::init"

# Install manually (non-Arch / macOS fallback) to ~/.local/share/miniconda3
install-manual:
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
    "$HOME/.local/share/miniconda3/bin/conda" config --set auto_activate_base false
    echo "miniconda3 installed to ~/.local/share/miniconda3"
    echo "Run: just conda::init"

# Primary install (calls install-aur); override by calling install-manual directly
install: install-aur

# Initialize conda hooks for bash, zsh, and fish — detects AUR vs manual prefix
init:
    #!/usr/bin/env sh
    set -e
    if [ -x /opt/miniconda3/bin/conda ]; then
        PREFIX=/opt/miniconda3
    elif [ -x "$HOME/.local/share/miniconda3/bin/conda" ]; then
        PREFIX="$HOME/.local/share/miniconda3"
    else
        echo "No conda installation found. Run: just conda::install" >&2
        exit 1
    fi
    echo "Initializing conda from $PREFIX ..."
    "$PREFIX/bin/conda" init bash zsh
    echo "Done. Restart your shell or run: exec \$SHELL"
