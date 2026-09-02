# Dotfiles

GNU Stow packages with XDG paths, so config is tracked in git while secrets and app data stay local.
Bootstrap is driven by [just](https://github.com/casey/just). CLI dev tools are pinned and installed by
[mise](https://mise.jdx.dev). Pinned versions are kept fresh by [Renovate](https://docs.renovatebot.com).

Supported platforms: macOS, Ubuntu/Debian, Arch/CachyOS.

## Layout

- `<package>/` — a stow package. Files sit in their real `$HOME`-relative shape (e.g. `nvim/.config/nvim/`).
- `modules/<tool>/mod.just` — install/init recipes for one tool.
- `lib/` — helpers sourced by recipes: `detect.sh` (OS + package manager), `paths.sh` (OS-dependent
  targets), `stow-safe.sh` (stow with conflict backup).
- `packages` in `Justfile` — the single list of stow packages, used by `stow-all` and `check`.

Adding a stow-only tool: create the package folder and add its name to `packages`.
Adding a tool that needs installing: also add `modules/<tool>/mod.just` and a `mod` line in `Justfile`.

## Stow packages

| Package | Symlinks into |
|---|---|
| `shell` | `~/.config/shell/{aliases.sh,env.sh}`, `~/.local/bin/{podman-stack,pgup,myup,dbdown,nbup,nbdown,uiup,uidown}` |
| `bash` | `~/.bashrc`, `~/.bash_profile` |
| `zsh` | `~/.zshrc` |
| `fish` | `~/.config/fish/config.fish` |
| `git` | `~/.gitconfig` (identity lives in untracked `~/.gitconfig-local`) |
| `direnv` | `~/.config/direnv/direnvrc` |
| `mise` | `~/.config/mise/config.toml` |
| `nvim` | `~/.config/nvim/` |
| `dev-db` | `~/.config/dev-db/compose.yml` |
| `open-webui` | `~/.config/open-webui/{docker-compose.yml,docker-compose.gpu.yml,.env.example}` |
| `jupyter` | `~/.config/jupyter/{Containerfile,compose.yml,environment.yml}` |
| `vscode` (desktop tier; source `vscode/agents/`) | macOS: `~/Library/Application Support/Code/User/prompts/*.agent.md`<br>Linux: `${XDG_CONFIG_HOME:-~/.config}/Code/User/prompts/*.agent.md` |

`~/.bashrc` and `~/.zshrc` are thin: prompt, history, completion. Everything shared (PATH, conda,
direnv, mise) is in `~/.config/shell/env.sh`. Fish has the same logic in its own syntax.

## Tracked vs local

Tracked: compose/config files, shell configs, editor config, template env files (`.env.example`),
the Neovim plugin lock file.

Local only (never tracked):

- `~/.config/dotfiles/profile` — which tiers this machine gets (written by `just profile`)
- `~/.config/mise/conf.d/local.toml` — per-machine mise tools such as Ruby (written by `just profile`)
- `~/.gitconfig-local` — git identity (written by `just git::init`)
- `~/.config/open-webui/.env` — secrets
- Runtime data under `~/.local/share/`: `open-webui/data`, `dev-db/{postgres,mysql}`,
  `jupyter/{notebooks,conda-envs}`. Created on demand by the `podman-stack` helper.

## Bootstrap

1. Install `git`, `stow`, and `just` (1.31 or newer, for modules):

   **Arch/CachyOS:** `sudo pacman -S just stow git` (plus `paru` or `yay` for AUR packages)
   **macOS:** `brew install just stow git`
   **Ubuntu/Debian:** `sudo apt install stow git`, then the packaged `just` is too old, so:
   `curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin`

2. Clone:

       git clone https://github.com/mmogr/dotfiles.git ~/.dotfiles

3. Run setup:

       cd ~/.dotfiles
       just setup

   The first run asks three questions and saves the answers to `~/.config/dotfiles/profile`.
   Every later run is silent and safe to repeat. With no terminal attached (CI, piped) it
   installs the core tier only. Change the answers any time with `just profile`.

4. If you chose containers, fill in the secrets file:

       $EDITOR ~/.config/open-webui/.env

### Tiers

| Tier | Always? | Installs |
|---|---|---|
| core | yes | fish, zsh, conda, mise + its tools (node, rust, gh, lazygit, direnv, neovim), git identity |
| Ruby | asked | `ruby = "3"` via mise (compiled from source, several minutes) |
| desktop | asked | VS Code (+ agent files), Zed, JetBrains Toolbox |
| containers | asked | podman (+ rootless socket, or a podman machine on macOS), Open WebUI secrets, JupyterLab image build (~15 min first time) |

Each tier is also a recipe: `just setup-core`, `just setup-desktop`, `just setup-containers`.

## Tools managed by mise

`mise/.config/mise/config.toml` pins node, rust, gh, lazygit, direnv, and neovim to exact versions
on every platform. This replaces per-distro package names and keeps Neovim current on Ubuntu,
whose packaged version is too old for the `vim.pack`-based config in `nvim/`.

- `just mise::install` — install mise (if missing) and every pinned tool
- `just mise::outdated` — see what has newer releases
- `just mise::upgrade` — upgrade within the pins; Renovate PRs move the pins themselves

Neovim must be 0.12 or newer. If a release ever lags behind what `init.lua` needs, set
`"aqua:neovim/neovim" = "nightly"` in the mise config.

Shells, podman, conda, and GUI apps stay with the system package manager.

## Daily commands

Open WebUI: `uiup` / `uidown` / `uilog`
Databases on demand: `pgup` (Postgres), `myup` (MySQL), `dbdown` (stop both)
JupyterLab (Python, Rust, Java, SQL, SoS; Quarto + TinyTeX): `nbup` / `nbdown` / `nblog`,
`just jupyter::build` after changing the Containerfile or `environment.yml`

All of these wrap `podman-stack <dev-db|jupyter|open-webui> <compose args>`, which starts the
podman socket on Linux, creates the data directories, and adds the AMD GPU overlay for Open WebUI
when `/dev/dri` and `/dev/kfd` exist.

Every service binds to `127.0.0.1` only. Jupyter runs without a token, Open WebUI without auth,
and the databases with default passwords, so nothing is reachable from the network.

In any notebook, connect to dev-db with two lines:

    %load_ext sql
    %sql $POSTGRES_URL   # or $MYSQL_URL or $SQLITE_URL

JupyterLab serves at http://localhost:8890, Open WebUI at http://localhost:3000.

## Keeping versions fresh

Every pin in this repo is watched by Renovate: compose image tags, the Containerfile build args
(`JJAVA_VERSION`, `EVCXR_VERSION`, `QUARTO_VERSION`), the Jupyter base image digest, the mise tool
versions, and GitHub Actions. Config is in `renovate.json`: one grouped PR per week for minor and
patch bumps, separate PRs for majors, releases must be at least three days old.

One-time setup: install the [Renovate GitHub app](https://github.com/apps/renovate) on this
repo. It opens an onboarding PR and a "Dependency Dashboard" issue listing everything it tracks.

Neovim plugins are the exception: `nvim/.config/nvim/nvim-pack-lock.json` is updated from inside
Neovim with `:lua vim.pack.update()` and committed like any other change.

## Verify

    just check

Confirms the repo is clean and every stow package (plus the VS Code agents, once the desktop tier
is installed) is correctly linked. CI runs the same check on Ubuntu and macOS, plus shellcheck and
a mise install of the pinned tools.

## VS Code Rust tasks

`vscode/tasks/rust-tasks.json` is a per-project template, not stowed. Copy it into a Rust
project as `.vscode/tasks.json` for build, test, clippy, and format tasks.
