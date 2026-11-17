#!/usr/bin/env sh
# lib/backup.sh — sourced by lib/stow-safe.sh and the backup-defaults recipe.
#
# Defines:
#   backup_path <file>  — print a name to move <file> to that is not taken:
#                         <file>.bak, or <file>.bak.1, <file>.bak.2, ... when
#                         earlier backups are still there. A second backup
#                         must never replace the first, which holds the
#                         original file.

backup_path() {
    candidate="$1.bak"
    n=1
    while [ -e "$candidate" ] || [ -L "$candidate" ]; do
        candidate="$1.bak.$n"
        n=$((n + 1))
    done
    printf '%s\n' "$candidate"
}
