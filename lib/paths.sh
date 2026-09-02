#!/usr/bin/env sh
# shellcheck disable=SC2034  # variables are consumed by the recipe that sources this file
# lib/paths.sh — sourced by recipes that need OS-dependent target paths.
#
# Sets:
#   VSCODE_PROMPTS_DIR — VS Code user prompts folder (custom agents live here).
#     The path differs by OS, not by distro: every Linux distro follows XDG.
#       macOS: ~/Library/Application Support/Code/User/prompts
#       Linux: ${XDG_CONFIG_HOME:-~/.config}/Code/User/prompts

if [ "$(uname -s)" = "Darwin" ]; then
    VSCODE_PROMPTS_DIR="$HOME/Library/Application Support/Code/User/prompts"
else
    VSCODE_PROMPTS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/prompts"
fi
