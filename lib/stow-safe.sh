#!/usr/bin/env sh
# lib/stow-safe.sh <dotfiles-dir> <package>
#
# Stow a package. If real (non-symlink) files would conflict, prompt:
#   [y] back them up to .bak and stow
#   [N] skip this package
#
# Usage from a mod.just stow recipe:
#   stow:
#       sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} <pkg>

set -e

DOTFILES="$1"
PKG="$2"

if [ -z "$DOTFILES" ] || [ -z "$PKG" ]; then
    echo "Usage: stow-safe.sh <dotfiles-dir> <package>" >&2
    exit 1
fi

# Dry-run to detect conflicts (real files, not symlinks)
conflicts=$(cd "$DOTFILES" && stow -n -R "$PKG" 2>&1 | grep "cannot stow" || true)

if [ -z "$conflicts" ]; then
    cd "$DOTFILES" && stow -R "$PKG"
    exit 0
fi

echo ""
echo "Package '$PKG': conflicting files already exist:"
echo "$conflicts" | sed 's/.*existing target //; s/ since.*//' | while IFS= read -r rel; do
    echo "  $HOME/$rel"
done
printf "Back up and overwrite? [y/N] "
read -r answer

case "$answer" in
    y|Y)
        echo "$conflicts" | sed 's/.*existing target //; s/ since.*//' | while IFS= read -r rel; do
            target="$HOME/$rel"
            echo "  $target -> $target.bak"
            mv "$target" "$target.bak"
        done
        cd "$DOTFILES" && stow -R "$PKG"
        ;;
    *)
        echo "Skipping '$PKG'."
        ;;
esac
