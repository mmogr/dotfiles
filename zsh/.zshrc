# ~/.zshrc — tracked in dotfiles, managed by stow

# Source shared aliases
[ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

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

# PATH additions
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# >>> conda initialize >>>
# Tries AUR path (/opt/miniconda3) first, then manual install fallback
for __conda_prefix in /opt/miniconda3 "$HOME/.local/share/miniconda3"; do
    if [ -x "$__conda_prefix/bin/conda" ]; then
        __conda_setup="$("$__conda_prefix/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
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

# direnv — per-directory env var loading (must come after conda)
if command -v direnv > /dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# mise — universal tool version manager (node, python, ruby, etc.)
[ -x "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate zsh)"

