#!/usr/bin/env sh
# lib/detect.sh — sourced by module install recipes to set PM and AUR_PM.
# Usage in a just shebang recipe:
#   . "{{justfile_directory()}}/lib/detect.sh"
#
# Sets:
#   PM     — full install command including sudo where required
#   AUR_PM — AUR helper (Arch only); empty string on other platforms

if command -v pacman > /dev/null 2>&1; then
    PM="sudo pacman -S --noconfirm"
elif command -v apt > /dev/null 2>&1; then
    PM="sudo apt install -y"
elif command -v brew > /dev/null 2>&1; then
    PM="brew install"
else
    echo "Error: no supported package manager found (expected pacman, apt, or brew)" >&2
    exit 1
fi

if command -v paru > /dev/null 2>&1; then
    AUR_PM="paru --noconfirm"
elif command -v yay > /dev/null 2>&1; then
    AUR_PM="yay --noconfirm"
else
    AUR_PM=""
fi
