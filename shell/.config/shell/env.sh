# ~/.config/shell/env.sh — environment shared by bash and zsh (fish has its own
# config.fish). Sourced from ~/.bashrc and ~/.zshrc; keep it POSIX.
#
# Order matters: PATH, then conda, then direnv (so .envrc conda activations see
# an initialised conda), then mise last.

if [ -n "$ZSH_VERSION" ]; then
    __shell=zsh
else
    __shell=bash
fi

# PATH — local tools (mise, scripts) and cargo binaries
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# >>> conda initialize >>>
# Tries AUR path (/opt/miniconda3) first, then manual install fallback
for __conda_prefix in /opt/miniconda3 "$HOME/.local/share/miniconda3"; do
    if [ -x "$__conda_prefix/bin/conda" ]; then
        __conda_setup="$("$__conda_prefix/bin/conda" "shell.$__shell" 'hook' 2>/dev/null)"
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

# direnv — per-directory env var loading. direnv is installed by mise, whose
# own PATH hook only runs at the first prompt, so resolve it through mise when
# it is not on PATH yet.
if command -v direnv > /dev/null 2>&1; then
    eval "$(direnv hook "$__shell")"
elif [ -x "$HOME/.local/bin/mise" ] && __direnv=$("$HOME/.local/bin/mise" which direnv 2>/dev/null); then
    eval "$("$__direnv" hook "$__shell")"
fi
unset __direnv

# mise — tool version manager (node, rust, gh, lazygit, neovim, ...)
[ -x "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate "$__shell")"

unset __shell
