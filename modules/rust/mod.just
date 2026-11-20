# Rust — installed by rustup itself, not through mise.
#
# rustup already runs the toolchain a project names in rust-toolchain.toml.
# mise's rust tool gets in the way of that twice: it exports RUSTUP_TOOLCHAIN in
# every shell, which overrides the project's file, and it counts ~/.cargo/bin as
# its own install, so every binary there gets a shim that stays behind (and
# fails) once the binary is removed.

# Install rustup and the stable toolchain if missing; take Rust back from mise if it had it
install:
    #!/usr/bin/env sh
    set -e
    # A shell started while mise still managed Rust carries this until it restarts.
    unset RUSTUP_TOOLCHAIN
    . "{{justfile_directory()}}/lib/detect.sh"
    # rustc links with the system C compiler, which bare Debian/Ubuntu doesn't ship.
    if [ "$OS" = debian ]; then
        $PM build-essential
    fi
    # A machine set up while mise managed Rust has installs/rust, a link to
    # ~/.cargo/bin, and a shim for everything in it. (Where rustup came from a
    # package manager, the link points at that rustup instead and only its
    # proxies have shims.) The shims are ahead of ~/.cargo/bin on PATH and now
    # fail with "No version is set for shim", so drop the link and rebuild
    # them. Not `mise uninstall rust`: that removes the stable toolchain from
    # rustup.
    MISE="$HOME/.local/bin/mise"
    MISE_RUST="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/installs/rust"
    if [ -e "$MISE_RUST" ] || [ -L "$MISE_RUST" ]; then
        echo "Taking Rust back from mise (removing its link to rustup's binaries and the shims)..."
        rm -rf "$MISE_RUST"
        if [ -x "$MISE" ]; then
            "$MISE" reshim
        fi
    fi
    RUSTUP="$HOME/.cargo/bin/rustup"
    if [ ! -x "$RUSTUP" ]; then
        echo "Installing rustup..."
        # --no-modify-path: the shell configs in this repo already put ~/.cargo/bin
        # on PATH, and rustup fails on macOS when it tries to amend files such as ~/.tcshrc.
        # A rustup from a package manager (Homebrew, pacman) does not count: this
        # installs a second one beside it, because ~/.cargo/bin is where those
        # shell configs look. The two share ~/.rustup, so its toolchains stay,
        # but its profile goes back to "default". -y is what lets the installer
        # continue past "cannot install while Rust is installed".
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
    fi
    # A rustup that mise installed may have no default toolchain, since mise named
    # one in RUSTUP_TOOLCHAIN instead. Without a default, cargo fails outside a project.
    if ! "$RUSTUP" default 2>/dev/null | grep -q '(default)'; then
        "$RUSTUP" default stable
    fi
    "$HOME/.cargo/bin/rustc" --version
    "$HOME/.cargo/bin/cargo" --version

# Update rustup and the stable toolchain (a project's pinned toolchain is left alone)
upgrade:
    #!/usr/bin/env sh
    set -e
    unset RUSTUP_TOOLCHAIN
    "$HOME/.cargo/bin/rustup" update stable
