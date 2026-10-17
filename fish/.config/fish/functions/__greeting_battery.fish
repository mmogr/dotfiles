function __greeting_battery --description 'Battery charge, state and time left, e.g. 46% · discharging · 3h 59m left'
    set -l bat /sys/class/power_supply/BAT*
    set -q bat[1]; or return
    set bat $bat[1]
    read -l capacity <$bat/capacity; or return
    read -l state <$bat/status

    set -l colour green
    test $capacity -lt 50; and set colour yellow
    test $capacity -lt 20; and set colour red
    set -l parts (set_color $colour)$capacity%(set_color normal) (string lower -- $state)

    # Drivers report energy (µWh, µW) or charge (µAh, µA); the ratios are the same.
    set -l now
    set -l full
    set -l rate
    for kind in energy:power charge:current
        set -l f (string split : $kind)
        if test -r $bat/$f[1]_now -a -r $bat/$f[1]_full -a -r $bat/$f[2]_now
            read now <$bat/$f[1]_now
            read full <$bat/$f[1]_full
            read rate <$bat/$f[2]_now
            break
        end
    end

    if test -n "$rate"; and test "$rate" -gt 0
        switch $state
            case Discharging
                set -a parts (__greeting_duration (math "$now / $rate * 3600"))' left'
            case Charging
                set -a parts (__greeting_duration (math "($full - $now) / $rate * 3600"))' to full'
        end
    end

    string join ' · ' -- $parts
end
