# Window and tab title, e.g. `~/.dotfiles · (ml) · main` at the prompt and
# `nvim init.lua · ~/.dotfiles` while a command runs. Replaces the pure theme's
# title from CachyOS. Plain text only: the title bar uses the system font, which
# has no Nerd Font icons.
function fish_title --description 'Title: directory, conda env or venv and git branch, or the running command'
    set -l dir (prompt_pwd --dir-length 0)

    # fish passes the running command line; lead with it so busy tabs say what they are doing.
    if set -q argv[1]
        echo (string split -f1 \n -- $argv[1] | string shorten -m 40) · $dir
        return
    end

    set -l parts $dir
    set -q CONDA_DEFAULT_ENV[1]; and set -a parts "($CONDA_DEFAULT_ENV)"
    set -q VIRTUAL_ENV[1]; and set -a parts "("(path basename -- $VIRTUAL_ENV)")"
    if command -q git
        set -l branch (git branch --show-current 2>/dev/null)
        set -q branch[1]; and set -a parts $branch
    end
    string join ' · ' -- $parts
end
