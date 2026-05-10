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

# >>> conda initialize >>>
# Tries AUR path (/opt/miniconda3) first, then manual install fallback
for __conda_prefix in /opt/miniconda3 "$HOME/.local/share/miniconda3"; do
    if [ -x "$__conda_prefix/bin/conda" ]; then
        __conda_setup="$("$__conda_prefix/bin/conda" 'shell.bash' 'hook' 2>/dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        elif [ -f "$__conda_prefix/etc/profile.d/conda.sh" ]; then
            . "$__conda_prefix/etc/profile.d/conda.sh"
        else
            export PATH="$__conda_prefix/bin:$PATH"
        fi
        break
    fi
done
unset __conda_setup __conda_prefix
# <<< conda initialize <<<

