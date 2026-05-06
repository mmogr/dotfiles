# Dev databases (Postgres + MySQL) — stow config and create data directories

stow:
    stow -d {{justfile_directory()}} -R dev-db

dirs:
    mkdir -p "$HOME/.local/share/dev-db/postgres"
    mkdir -p "$HOME/.local/share/dev-db/mysql"
