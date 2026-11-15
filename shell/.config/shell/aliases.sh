# Log tails — read-only, no socket management needed
alias uilog='podman logs -f open-webui'
alias nblog='podman logs -f jupyterlab'

# uiup, uidown, pgup, myup, dbdown, nbup, nbdown: start/stop services, bringing
# up the podman socket (Linux) or podman machine (macOS) first and stopping the
# machine again after the last one goes down. Defined as portable scripts in
# shell/.local/bin/ (stowed to ~/.local/bin/), available in all shells via PATH.
