# Greeting — fastfetch sized to the window. The info column is ~48 chars and
# ~22 rows; fastfetch truncates rather than wraps, so pick the biggest logo
# that still fits beside it and skip the greeting entirely in windows too
# small to hold it.
#
# The AUR row in fastfetch/.config/fastfetch/config.jsonc prints the
# GREETING_AUR variable exported here, which is cached.
function fish_greeting
    command -q fastfetch; or return
    set -l cols $COLUMNS
    set -l rows $LINES
    test -n "$cols"; or set cols (tput cols)
    test -n "$rows"; or set rows (tput lines)

    set -lx GREETING_AUR (__greeting_aur)

    if test $cols -lt 50 -o $rows -lt 25
        return
    else if test $cols -ge 108
        fastfetch
    else if test $cols -ge 78
        fastfetch --logo CachyOS_small
    else
        fastfetch --logo none
    end
end
