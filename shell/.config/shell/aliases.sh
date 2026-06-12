alias webui='cd ~/.config/open-webui && podman-compose'
alias uiup='podman-compose -f ~/.config/open-webui/docker-compose.yml up -d'
alias uidown='podman-compose -f ~/.config/open-webui/docker-compose.yml down'
alias uilog='podman logs -f open-webui'
alias pgup='podman-compose -f ~/.config/dev-db/compose.yml up -d postgres'
alias myup='podman-compose -f ~/.config/dev-db/compose.yml up -d mysql'
alias dbdown='podman-compose -f ~/.config/dev-db/compose.yml stop'
alias nblog='podman logs -f jupyterlab'
# nbup/nbdown are defined as Fish functions in config.fish so they can
# auto-start the podman socket before invoking compose. In other shells,
# ensure the socket is active (systemctl --user start podman.socket) first.
