# Greeting — fastfetch splash sized to the window, or a one-line banner when
# the window is too small for it. The splash's info column is ~48 chars and
# 22 rows; fastfetch truncates rather than wraps, so pick the biggest logo
# that still fits beside it.
#
# The AUR, battery and session rows in fastfetch/.config/fastfetch/config.jsonc
# print the GREETING_* variables exported by __greeting_draw. Everything is
# read from files and fish builtins; the only slow part, the AUR count, is
# cached.
#
# This file is sourced from config.fish rather than autoloaded, which also
# registers the resize handler below at startup.
function fish_greeting
    command -q fastfetch; or return
    set -l session (__greeting_session)
    # Quoted so an empty value keeps its slot.
    set -g __greeting_info "$(__greeting_aur)" "$(__greeting_battery)" "$session[1]" "$session[2]"
    set -g __greeting_layout (__greeting_layout)
    __greeting_draw $__greeting_layout
end

function __greeting_layout --description 'Pick the greeting layout that fits the window'
    set -l cols $COLUMNS
    set -l rows $LINES
    test -n "$cols"; or set cols (tput cols)
    test -n "$rows"; or set rows (tput lines)

    if test $cols -lt 50 -o $rows -lt 25
        echo banner
    else if test $cols -ge 108
        echo full
    else if test $cols -ge 78
        echo small
    else
        echo none
    end
end

function __greeting_draw --argument-names layout
    set -lx GREETING_AUR $__greeting_info[1]
    set -lx GREETING_BATTERY $__greeting_info[2]
    set -lx GREETING_LAST $__greeting_info[3]
    set -lx GREETING_TODAY $__greeting_info[4]
    switch $layout
        case banner
            __greeting_banner $COLUMNS
        case full
            fastfetch
        case small
            fastfetch --logo CachyOS_small
        case none
            fastfetch --logo none
    end
end

# A resize reflows the splash into a mess, and Konsole can start the shell
# before it settles on its real size. While the greeting is still the only
# thing on screen, redraw it whenever the window needs a different layout.
function __greeting_resize --on-signal WINCH
    set -q __greeting_layout; or return
    set -l layout (__greeting_layout)
    test $layout = banner -o $layout != $__greeting_layout; or return
    set -g __greeting_layout $layout
    printf '\e[H\e[2J\e[3J'
    __greeting_draw $layout
    commandline -f repaint
end

function __greeting_settle --on-event fish_preexec
    set -e __greeting_layout
end
