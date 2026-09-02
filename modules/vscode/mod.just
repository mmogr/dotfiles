# VS Code — install per platform and link the custom agent files
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
    case "$OS" in
        arch)   aur_install visual-studio-code-bin ;;
        macos)  brew install --cask visual-studio-code ;;
        debian) sudo snap install code --classic ;;
    esac

# Symlink custom agent files (vscode/agents/*.agent.md) into the VS Code
# User profile prompts folder (path from lib/paths.sh).
stow:
    #!/usr/bin/env sh
    set -e
    . "{{justfile_directory()}}/lib/paths.sh"
    mkdir -p "$VSCODE_PROMPTS_DIR"
    sh "{{justfile_directory()}}/lib/stow-safe.sh" "{{justfile_directory()}}/vscode" agents "$VSCODE_PROMPTS_DIR"
