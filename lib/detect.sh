#!/usr/bin/env sh
# shellcheck disable=SC2034  # variables are consumed by the recipe that sources this file
# lib/detect.sh — sourced by module install recipes.
# Usage in a just shebang recipe:
#   . "{{justfile_directory()}}/lib/detect.sh"
#
# Sets:
#   OS      — arch | debian | macos
#   PM      — package install command, sudo included where required
#   AUR_PM  — AUR helper command (Arch only); empty elsewhere
# Defines:
#   aur_install <pkg>...  — install from the AUR, or fail with a clear message
#
# Adding a distro: add a branch to the Linux case below that sets OS, and a
# matching PM line. Modules branch on "$OS", never on which binaries exist.

case "$(uname -s)" in
    Darwin)
        OS=macos
        ;;
    Linux)
        # ID and ID_LIKE from os-release, read in a subshell so the file's
        # other variables (NAME, VERSION, ...) don't leak into the recipe.
        os_ids=$( (. /etc/os-release && printf '%s %s' "$ID" "${ID_LIKE:-}") 2>/dev/null )
        case " $os_ids " in
            *" arch "*)                OS=arch ;;
            *" debian "*|*" ubuntu "*) OS=debian ;;
            *)                         OS="" ;;
        esac
        unset os_ids
        ;;
    *)
        OS=""
        ;;
esac

case "$OS" in
    arch)   PM="sudo pacman -S --noconfirm --needed" ;;
    debian) PM="sudo apt-get install -y" ;;
    macos)
        if ! command -v brew > /dev/null 2>&1; then
            echo "Error: Homebrew not found — install it from https://brew.sh first" >&2
            exit 1
        fi
        PM="brew install"
        ;;
    *)
        echo "Error: unsupported platform (expected Arch-based, Debian-based, or macOS)" >&2
        exit 1
        ;;
esac

AUR_PM=""
if [ "$OS" = arch ]; then
    if command -v paru > /dev/null 2>&1; then
        AUR_PM="paru -S --noconfirm --needed"
    elif command -v yay > /dev/null 2>&1; then
        AUR_PM="yay -S --noconfirm --needed"
    fi
fi

aur_install() {
    if [ -z "$AUR_PM" ]; then
        echo "Error: no AUR helper found — install paru or yay, then re-run" >&2
        return 1
    fi
    $AUR_PM "$@"
}
