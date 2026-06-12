# Git — stow config and ensure local identity file exists

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} git

# Create ~/.gitconfig-local if it doesn't already exist, then open it for editing.
# This file is git-ignored and holds identity (name, email) and any machine-specific
# overrides that should never be committed to a public repo.
init:
    #!/usr/bin/env sh
    LOCAL="$HOME/.gitconfig-local"
    if [ ! -f "$LOCAL" ]; then
        printf '[user]\n\tname  = YOUR NAME\n\temail = you@example.com\n' > "$LOCAL"
        echo "Created $LOCAL — please fill in your name and email:"
    else
        echo "$LOCAL already exists."
    fi
    echo ""
    cat "$LOCAL"
