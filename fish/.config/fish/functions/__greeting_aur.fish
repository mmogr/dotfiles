function __greeting_aur --description 'Count foreign (AUR) packages, cached until pacman changes its databases'
    command -q pacman; or return
    set -l dir ~/.cache
    set -q XDG_CACHE_HOME[1]; and set dir $XDG_CACHE_HOME
    set -l cache $dir/fish-greeting-aur

    # `pacman -Qm` takes ~0.3s. Installs and removals touch local/, and a
    # `-Sy` can change what counts as foreign, so recount when either is
    # newer than the cache.
    set -l cached (path mtime $cache); or set cached 0
    for changed in (path mtime /var/lib/pacman/local /var/lib/pacman/sync)
        if test $changed -gt $cached
            mkdir -p $dir
            pacman -Qmq | count >$cache
            break
        end
    end

    read -l n <$cache; and echo $n
end
