# ~/.zshrc — tracked in dotfiles, managed by stow

# Shared aliases and environment (PATH, conda, direnv, mise) — see ~/.config/shell/
[ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"
[ -f "$HOME/.config/shell/env.sh" ] && source "$HOME/.config/shell/env.sh"

# Prompt
autoload -Uz promptinit && promptinit
prompt walters

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit && compinit
