function __greeting_session --description 'Print the last command and how long ago, then today'\''s command count and most-used commands'
    set -l entries (history search --null --show-time='%s ' --max 1000 | string split0)
    set -q entries[1]; or return

    # Seconds since midnight from one `date` call, the only process this spawns.
    set -l clock (string split ' ' -- (date '+%s %H %M %S'))
    set -l now $clock[1]
    set -l midnight (math "$now - $clock[2] * 3600 - $clock[3] * 60 - $clock[4]")

    set -l last (string split -m1 ' ' -- $entries[1])
    set -l command (string split -f1 \n -- $last[2] | string shorten -m 26)
    set -l age (math $now - $last[1])
    if test $age -lt 60
        echo "$command · just now"
    else
        echo "$command · "(__greeting_duration $age)" ago"
    end

    # History is newest first, so stop at the first entry from before today.
    set -l names
    set -l counts
    set -l total 0
    for entry in $entries
        set -l e (string split -m1 ' ' -- $entry)
        test $e[1] -ge $midnight; or break
        set total (math $total + 1)
        set -l name (string split -f1 ' ' -- $e[2])
        if set -l i (contains -i -- $name $names)
            set counts[$i] (math $counts[$i] + 1)
        else
            set -a names $name
            set -a counts 1
        end
    end
    test $total -gt 0; or return

    set -l top
    for rank in 1 2 3
        set -q counts[1]; or break
        set -l i (contains -i -- (math "max("(string join , $counts)")") $counts)
        set -a top $names[$i]
        set -e names[$i] counts[$i]
    end
    echo "$total cmds · $top"
end
