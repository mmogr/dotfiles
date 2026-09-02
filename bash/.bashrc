# ~/.bashrc — tracked in dotfiles, managed by stow

# Shared aliases and environment (PATH, conda, direnv, mise) — see ~/.config/shell/
[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"
[ -f "$HOME/.config/shell/env.sh" ] && . "$HOME/.config/shell/env.sh"

# Prompt
PS1='\u@\h:\w\$ '

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
