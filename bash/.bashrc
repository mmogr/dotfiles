# ~/.bashrc — tracked in dotfiles, managed by stow

# Source shared aliases
[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"

# Prompt
PS1='\u@\h:\w\$ '

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups

# PATH additions
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
