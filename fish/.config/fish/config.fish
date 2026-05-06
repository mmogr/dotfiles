source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

source ~/.config/shell/aliases.sh

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
