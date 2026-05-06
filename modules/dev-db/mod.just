# Dev databases (Postgres + MySQL) — stow config and create data directories

stow:
    sh {{justfile_directory()}}/lib/stow-safe.sh {{justfile_directory()}} dev-db

dirs:
    mkdir -p "$HOME/.local/share/dev-db/postgres"
    mkdir -p "$HOME/.local/share/dev-db/mysql"
