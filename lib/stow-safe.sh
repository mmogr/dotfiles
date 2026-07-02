#!/usr/bin/env sh
# lib/stow-safe.sh <dotfiles-dir> <package> [target-dir]
#
# Stow a package. If real (non-symlink) files would conflict, prompt:
#   [y] back them up to .bak and stow
#   [N] skip this package
#
# target-dir is optional and overrides stow's default target (normally the
# parent of <dotfiles-dir>, i.e. $HOME). Use it for packages whose real
# destination lives outside the usual $HOME-relative layout.
#
# Usage from a mod.just stow recipe:
#   stow:
#       sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} <pkg>
#   # or, with a custom target:
#   stow:
#       sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} <pkg> "$TARGET_DIR"

set -e

DOTFILES="$1"
PKG="$2"
TARGET_DIR="$3"

if [ -z "$DOTFILES" ] || [ -z "$PKG" ]; then
    echo "Usage: stow-safe.sh <dotfiles-dir> <package> [target-dir]" >&2
    exit 1
fi

if [ -n "$TARGET_DIR" ]; then
    BASE="$TARGET_DIR"
else
    BASE="$HOME"
fi

stow_dry_run() {
    if [ -n "$TARGET_DIR" ]; then
        (cd "$DOTFILES" && stow -n -R -t "$TARGET_DIR" "$PKG") 2>&1
    else
        (cd "$DOTFILES" && stow -n -R "$PKG") 2>&1
    fi
}

stow_real_run() {
    if [ -n "$TARGET_DIR" ]; then
        (cd "$DOTFILES" && stow -R -t "$TARGET_DIR" "$PKG")
    else
        (cd "$DOTFILES" && stow -R "$PKG")
    fi
}

# Dry-run to detect conflicts (real files, not symlinks)
conflicts=$(stow_dry_run | grep "cannot stow" || true)

if [ -z "$conflicts" ]; then
    stow_real_run
    exit 0
fi

echo ""
echo "Package '$PKG': conflicting files already exist:"
echo "$conflicts" | sed 's/.*existing target //; s/ since.*//' | while IFS= read -r rel; do
    echo "  $BASE/$rel"
done
printf "Back up and overwrite? [y/N] "
read -r answer

case "$answer" in
    y|Y)
        echo "$conflicts" | sed 's/.*existing target //; s/ since.*//' | while IFS= read -r rel; do
            target="$BASE/$rel"
            echo "  $target -> $target.bak"
            mv "$target" "$target.bak"
        done
        stow_real_run
        ;;
    *)
        echo "Skipping '$PKG'."
        ;;
esac
