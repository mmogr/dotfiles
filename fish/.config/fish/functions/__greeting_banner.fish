function __greeting_banner --argument-names cols --description 'One-line greeting for windows too small for the fastfetch splash'
    set -l sep (set_color brblack)' · '(set_color normal)
    set -l line (set_color cyan)󰣇(set_color normal) (set_color -o green)$USER@(prompt_hostname)(set_color normal)

    # Most useful first; anything that does not fit is skipped.
    set -l parts
    test -n "$GREETING_BATTERY"; and set -a parts $GREETING_BATTERY
    test -n "$GREETING_LAST"; and set -a parts "last: "(string replace ' · ' ' (' -- $GREETING_LAST)")"
    if read -l uptime </proc/uptime
        set -a parts "up "(__greeting_duration (string split -f1 ' ' -- $uptime))
    end
    set -l mem
    test -r /proc/meminfo; and set mem (string match -rg '^Mem(?:Total|Available):\s+(\d+)' </proc/meminfo)
    if set -q mem[2]
        set -a parts "mem "(math -s1 "($mem[1] - $mem[2]) / 1048576")/(math -s0 "$mem[1] / 1048576")G
    end

    for part in $parts
        set -l longer "$line$sep$part"
        test (string length --visible -- $longer) -le $cols; and set line $longer
    end
    echo $line
end
