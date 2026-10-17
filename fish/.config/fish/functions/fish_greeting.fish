# Greeting — fastfetch splash sized to the window, or a one-line banner when
# the window is too small for it. The splash's info column is ~48 chars and
# 22 rows; fastfetch truncates rather than wraps, so pick the biggest logo
# that still fits beside it.
#
# The AUR, battery and session rows in fastfetch/.config/fastfetch/config.jsonc
# print the GREETING_* variables exported here. Everything is read from files
# and fish builtins; the only slow part, the AUR count, is cached.
function fish_greeting
    command -q fastfetch; or return
    set -l cols $COLUMNS
    set -l rows $LINES
    test -n "$cols"; or set cols (tput cols)
    test -n "$rows"; or set rows (tput lines)

    set -l session (__greeting_session)
    set -lx GREETING_AUR (__greeting_aur)
    set -lx GREETING_BATTERY (__greeting_battery)
    set -lx GREETING_LAST $session[1]
    set -lx GREETING_TODAY $session[2]

    if test $cols -lt 50 -o $rows -lt 25
        __greeting_banner $cols
    else if test $cols -ge 108
        fastfetch
    else if test $cols -ge 78
        fastfetch --logo CachyOS_small
    else
        fastfetch --logo none
    end
end
