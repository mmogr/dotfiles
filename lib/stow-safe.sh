#!/usr/bin/env sh
# lib/stow-safe.sh <dotfiles-dir> <package> [target-dir]
#
# Stow a package. If real (non-symlink) files would conflict, prompt:
#   [y] back them up to .bak and stow
#   [N] skip this package
# Without a terminal on stdin the backup happens automatically.
#
# target-dir is optional and defaults to $HOME. It is always passed to stow
# explicitly, so the repo can live anywhere (stow's own default, the parent of
# <dotfiles-dir>, is only $HOME when the repo is cloned to ~/.dotfiles). Use it
# for packages whose real destination lives outside the $HOME-relative layout.
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
    (cd "$DOTFILES" && stow -n -R -t "$BASE" "$PKG") 2>&1
}

stow_real_run() {
    (cd "$DOTFILES" && stow -R -t "$BASE" "$PKG")
}

# Dry-run to detect conflicts (real files, not symlinks). The wording differs
# between stow releases, so match both:
#   2.3.x:  * existing target is neither a link nor a directory: <path>
#   2.4.x:  * cannot stow <pkg>/<path> over existing target <path> since neither a link nor a directory ...
conflict_paths() {
    sed -n \
        -e 's/.*existing target is neither a link nor a directory: //p' \
        -e 's/.*over existing target \(.*\) since .*/\1/p'
}
# -R (restow) reports each conflict for both the unstow and stow phases, hence sort -u.
conflicts=$(stow_dry_run | conflict_paths | sort -u || true)

if [ -z "$conflicts" ]; then
    stow_real_run
    exit 0
fi

echo ""
echo "Package '$PKG': conflicting files already exist:"
echo "$conflicts" | while IFS= read -r rel; do
    echo "  $BASE/$rel"
done
if [ -t 0 ]; then
    printf "Back up and overwrite? [y/N] "
    read -r answer
else
    # No terminal (CI, piped setup): back up automatically. A backup is never
    # destructive, and stopping here would hang a non-interactive bootstrap.
    echo "No terminal attached — backing up automatically."
    answer=y
fi

case "$answer" in
    y|Y)
        echo "$conflicts" | while IFS= read -r rel; do
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
