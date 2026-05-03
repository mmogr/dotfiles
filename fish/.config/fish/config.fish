source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/matt/.local/share/miniconda3/bin/conda
    eval /home/matt/.local/share/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/matt/.local/share/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/matt/.local/share/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/matt/.local/share/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

alias webui='cd ~/.config/open-webui && podman-compose'
alias uiup='podman-compose -f ~/.config/open-webui/docker-compose.yml up -d'
alias uidown='podman-compose -f ~/.config/open-webui/docker-compose.yml down'
alias uilog='podman logs -f open-webui'
alias pgup='podman-compose -f ~/.config/dev-db/compose.yml up -d postgres'
alias myup='podman-compose -f ~/.config/dev-db/compose.yml up -d mysql'
alias dbdown='podman-compose -f ~/.config/dev-db/compose.yml stop'

if not abbr --query uiup
    abbr -a uiup 'podman-compose -f ~/.config/open-webui/docker-compose.yml up -d'
end

if not abbr --query uidown
    abbr -a uidown 'podman-compose -f ~/.config/open-webui/docker-compose.yml down'
end

if not abbr --query uilog
    abbr -a uilog 'podman logs -f open-webui'
end

if not abbr --query pgup
    abbr -a pgup 'podman-compose -f ~/.config/dev-db/compose.yml up -d postgres'
end

if not abbr --query myup
    abbr -a myup 'podman-compose -f ~/.config/dev-db/compose.yml up -d mysql'
end

if not abbr --query dbdown
    abbr -a dbdown 'podman-compose -f ~/.config/dev-db/compose.yml stop'
end
