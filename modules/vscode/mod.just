# VS Code — install via the appropriate method per platform
# Arch: AUR (visual-studio-code-bin)
# macOS: Homebrew cask
# Ubuntu/Debian: snap

install:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/detect.sh"
    if command -v code > /dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then
        echo "VS Code already installed — skipping"
        exit 0
    fi
    if command -v pacman > /dev/null 2>&1; then
        $AUR_PM visual-studio-code-bin
    elif command -v brew > /dev/null 2>&1; then
        brew install --cask visual-studio-code
    elif command -v apt > /dev/null 2>&1; then
        sudo snap install code --classic
    else
        echo "Unsupported platform for VS Code install" >&2 && exit 1
    fi

# Symlink custom agent files (vscode/agents/*.agent.md) into the VS Code
# User profile prompts folder. That path differs by OS (not by distro —
# every Linux distro follows the same XDG convention):
#   macOS: ~/Library/Application Support/Code/User/prompts
#   Linux: ${XDG_CONFIG_HOME:-~/.config}/Code/User/prompts
stow:
    #!/usr/bin/env sh
    set -e
    if [ "$(uname -s)" = "Darwin" ]; then
        TARGET="$HOME/Library/Application Support/Code/User/prompts"
    else
        TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/prompts"
    fi
    mkdir -p "$TARGET"
    sh "{{justfile_directory()}}/lib/stow-safe.sh" "{{justfile_directory()}}/vscode" agents "$TARGET"
