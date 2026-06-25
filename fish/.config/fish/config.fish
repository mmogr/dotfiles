# CachyOS-specific config (Linux only — not present on macOS or other distros)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# PATH — local tools (mise, scripts) and cargo binaries
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin

# Conda — source native fish hook for full activate/deactivate support
# Tries AUR install path (/opt/miniconda3) first, then manual install fallback
for _conda_prefix in /opt/miniconda3 $HOME/.local/share/miniconda3
    if test -f $_conda_prefix/etc/fish/conf.d/conda.fish
        source $_conda_prefix/etc/fish/conf.d/conda.fish
        break
    end
end

# direnv — per-directory env var loading (must come after conda so conda env
# activations triggered by .envrc work against the already-initialised conda)
if command -q direnv
    direnv hook fish | source
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

source ~/.config/shell/aliases.sh

# mise — universal tool version manager (node, python, ruby, etc.)
if test -x $HOME/.local/bin/mise
    $HOME/.local/bin/mise activate fish | source
end
