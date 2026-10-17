function __greeting_duration --argument-names seconds --description 'Format seconds as 2d 3h, 3h 59m or 27m'
    set -l s (math -s0 $seconds)
    if test $s -ge 86400
        echo (math -s0 $s / 86400)d (math -s0 $s % 86400 / 3600)h
    else if test $s -ge 3600
        echo (math -s0 $s / 3600)h (math -s0 $s % 3600 / 60)m
    else
        echo (math -s0 $s / 60)m
    end
end
