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
# activations triggered by .envrc work against the already-initialised conda).
# direnv is installed by mise, whose PATH hook only runs at the first prompt,
# so resolve it through mise when it is not on PATH yet.
if command -q direnv
    direnv hook fish | source
else if test -x $HOME/.local/bin/mise; and set -l direnv_bin ($HOME/.local/bin/mise which direnv 2>/dev/null)
    $direnv_bin hook fish | source
end

# Greeting — fastfetch sized to the window (overrides CachyOS's plain
# `fastfetch`). The info column is ~35 chars and ~22 rows; fastfetch truncates
# rather than wraps, so pick the biggest logo that still fits beside it and
# skip the greeting entirely in windows too small to hold it.
function fish_greeting
    command -q fastfetch; or return
    set -l cols $COLUMNS
    set -l rows $LINES
    test -n "$cols"; or set cols (tput cols)
    test -n "$rows"; or set rows (tput lines)

    if test $cols -lt 40 -o $rows -lt 24
        return
    else if test $cols -ge 100
        fastfetch
    else if test $cols -ge 72
        fastfetch --logo CachyOS_small
    else
        fastfetch --logo none
    end
end

source ~/.config/shell/aliases.sh

# mise — universal tool version manager (node, python, ruby, etc.)
if test -x $HOME/.local/bin/mise
    $HOME/.local/bin/mise activate fish | source
end
