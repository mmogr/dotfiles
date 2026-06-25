# Git — stow config and ensure local identity file exists

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} git

# Create ~/.gitconfig-local if it doesn't already exist, prompting for the
# user's name and email interactively. Re-prompts if the placeholder values
# are still present. Safe to re-run — skips if already configured.
# Falls back to writing placeholders with a warning when no TTY is available
# (e.g. CI), so just setup never hangs in non-interactive environments.
init:
    #!/usr/bin/env sh
    LOCAL="$HOME/.gitconfig-local"

    # Needs configuration if the file is missing or still has the placeholder email.
    needs_config() {
        [ ! -f "$LOCAL" ] || grep -q 'you@example\.com' "$LOCAL"
    }

    if needs_config; then
        if [ -c /dev/tty ]; then
            printf 'Git identity — these go into ~/.gitconfig-local (never committed).\n'
            printf 'Full name:  ' > /dev/tty
            read -r NAME < /dev/tty
            printf 'Email:      ' > /dev/tty
            read -r EMAIL < /dev/tty
            git config -f "$LOCAL" user.name  "$NAME"
            git config -f "$LOCAL" user.email "$EMAIL"
            echo "Written to $LOCAL"
        else
            printf '[user]\n\tname  = YOUR NAME\n\temail = you@example.com\n' > "$LOCAL"
            echo "WARNING: no TTY available — placeholder values written to $LOCAL"
            echo "         Fill in your name and email before committing:"
            echo "           git config -f ~/.gitconfig-local user.name  'Your Name'"
            echo "           git config -f ~/.gitconfig-local user.email 'you@example.com'"
        fi
    else
        echo "$LOCAL already configured — skipping."
    fi
    echo ""
    cat "$LOCAL"
