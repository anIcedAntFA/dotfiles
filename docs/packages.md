# Packages

This is a curated tour of the **intentionally installed** tools that make this
setup what it is — grouped by purpose, with a short _why_ and a link each.

## How packages are tracked

- **`packages/pacman-explicit.txt`** — every explicitly installed native package
  (`pacman -Qqe`). The reproducible source of truth.
- **`packages/aur.txt`** — AUR / foreign packages (`pacman -Qqm`).
- **`packages/vscode-extensions.txt`** — VS Code extension IDs (`code
  --list-extensions`), installed via
  [`run_onchange_install-vscode-extensions.sh.tmpl`](../home/.chezmoiscripts/run_onchange_install-vscode-extensions.sh.tmpl).
  VS Code's own settings live as a real chezmoi dotfile at
  [`home/dot_config/Code/User/settings.json`](../home/dot_config/Code/User/settings.json).
- **This file** — the human-readable subset worth explaining. It deliberately
  omits the base system, firmware, filesystem tools, Xorg, and dependencies that
  come with a stock install.

The baseline is an [EndeavourOS](https://endeavouros.com/) **"no desktop"**
install (minimal Arch, no DE) — everything below sits on top of that.

## Installing

Everything is installed with [`yay`](https://github.com/Jguer/yay), an AUR helper
(native `pacman` packages work too):

```sh
# From the snapshots (idempotent — --needed skips what you already have):
yay -S --needed - < packages/pacman-explicit.txt
yay -S --needed - < packages/aur.txt
```

Or let chezmoi do it on `chezmoi apply` — answer **yes** to the
`installPackages` prompt during `chezmoi init` (see the top-level README).

---

## Wayland desktop (niri + Noctalia)

| Package                                                                               | Why                                                               |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [`niri`](https://github.com/YaLTeR/niri)                                              | Scrollable-tiling Wayland compositor — the core of the desktop.   |
| [`noctalia-shell`](https://github.com/noctalia-dev/noctalia-shell) / `noctalia-qs`    | Sleek minimal shell (bar, launcher, widgets) built on Quickshell. |
| [`xwayland-satellite`](https://github.com/Supreeeme/xwayland-satellite)               | Runs X11 apps under niri without a rootful Xwayland.              |
| [`fuzzel`](https://codeberg.org/dnkl/fuzzel)                                          | Wayland application launcher.                                     |
| [`swaybg`](https://github.com/swaywm/swaybg)                                          | Wallpaper setter for wlroots compositors.                         |
| [`swaylock`](https://github.com/swaywm/swaylock)                                      | Screen locker.                                                    |
| [`wlsunset`](https://sr.ht/~kennylevinsen/wlsunset/)                                  | Day/night color-temperature shifting.                             |
| [`cliphist`](https://github.com/sentriz/cliphist)                                     | Wayland clipboard history.                                        |
| [`nwg-look`](https://github.com/nwg-piotr/nwg-look)                                   | GTK theme/settings editor for wlroots.                            |
| [`xdg-desktop-portal-{gnome,gtk,wlr}`](https://github.com/flatpak/xdg-desktop-portal) | Portals for screenshare, file pickers, etc.                       |
| [`greetd`](https://sr.ht/~kennylevinsen/greetd/) + `greetd-tuigreet`                  | Minimal login daemon + TUI greeter.                               |

## Terminals & shell

| Package                                               | Why                                                                            |
| ----------------------------------------------------- | ------------------------------------------------------------------------------ |
| [`ghostty`](https://ghostty.org/)                     | Primary GPU-accelerated terminal (with cursor shaders).                        |
| [`alacritty`](https://github.com/alacritty/alacritty) | Fallback/second terminal.                                                      |
| [`fish`](https://fishshell.com/)                      | Interactive shell.                                                             |
| [`fisher`](https://github.com/jorgebucaran/fisher)    | fish plugin manager.                                                           |
| [`starship`](https://starship.rs/)                    | Cross-shell prompt. Installed via the official script (see below), not pacman. |
| [`peco`](https://github.com/peco/peco)                | Interactive filtering (history / cd).                                          |
| [`ghq`](https://github.com/x-motemen/ghq)             | Clone & organize repos under `~/workspace`.                                    |

## Modern CLI tools

| Package                                                                                            | Why                                                       |
| -------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| [`bat`](https://github.com/sharkdp/bat)                                                            | `cat` with syntax highlighting.                           |
| [`eza`](https://github.com/eza-community/eza)                                                      | Modern `ls`.                                              |
| [`fd`](https://github.com/sharkdp/fd)                                                              | Modern `find` — fast, ergonomic.                          |
| [`ripgrep`](https://github.com/BurntSushi/ripgrep) (`rg`)                                          | Modern `grep` — `.gitignore`-aware, recursive, SIMD-fast. |
| [`fastfetch`](https://github.com/fastfetch-cli/fastfetch)                                          | System info readout.                                      |
| [`btop`](https://github.com/aristocratos/btop) / [`glances`](https://github.com/nicolargo/glances) | Resource monitors.                                        |
| [`duf`](https://github.com/muesli/duf)                                                             | Disk usage/free.                                          |
| [`tree`](http://mama.indstate.edu/users/ice/tree/)                                                 | Directory tree view.                                      |
| [`jq`](https://jqlang.github.io/jq/)                                                               | JSON processor.                                           |
| [`curlie`](https://github.com/rs/curlie)                                                           | `curl` with httpie ergonomics.                            |
| [`hyperfine`](https://github.com/sharkdp/hyperfine)                                                | Command benchmarking.                                     |
| [`tldr`](https://tldr.sh/)                                                                         | Simplified man pages.                                     |
| [`yazi`](https://github.com/sxyazi/yazi)                                                           | Terminal file manager.                                    |
| [`tuxedo`](https://github.com/webstonehq/tuxedo)                                                   | todo.txt task TUI — see [tuxedo.md](tuxedo.md).           |
| [`dos2unix`](https://waterlan.home.xs4all.nl/dos2unix.html)                                        | Line-ending conversion.                                   |
| [`plocate`](https://plocate.sesse.net/)                                                            | Fast `locate`.                                            |

## Development

| Package                                                                                                                                | Why                                                                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| [`git`](https://git-scm.com/) + [`git-cliff`](https://git-cliff.org/) + [`git-filter-repo`](https://github.com/newren/git-filter-repo) | VCS, changelog generation, history rewriting.                                                                            |
| [`gitleaks`](https://github.com/gitleaks/gitleaks)                                                                                     | Secret scanning (wired into this repo's hooks/CI).                                                                       |
| [`github-cli`](https://cli.github.com/) (`gh`)                                                                                         | GitHub from the terminal — PRs, issues, releases. See [git.md](git.md).                                                  |
| [`gopass`](https://www.gopass.pw/) + `gnupg`                                                                                           | Terminal password manager (GPG + git). See [gopass.md](gopass.md) · [ADR](adr/0004-terminal-password-manager-gopass.md). |
| [`direnv`](https://direnv.net/)                                                                                                        | Per-directory env / auto-`.envrc`. See [direnv.md](direnv.md).                                                           |
| [`turbo`](https://turborepo.com/)                                                                                                      | Monorepo build system / task runner.                                                                                     |
| [`bruno-bin`](https://www.usebruno.com/)                                                                                               | Git-friendly, offline API client (Postman alternative).                                                                  |
| [`mise`](https://mise.jdx.dev/)                                                                                                        | Runtime version manager (node, pnpm, bun, go…).                                                                          |
| [`uv`](https://github.com/astral-sh/uv)                                                                                                | Fast Python package manager.                                                                                             |
| [`docker`](https://www.docker.com/) + `docker-compose` + `docker-buildx` + [`lazydocker`](https://github.com/jesseduffield/lazydocker) | Containers + TUI. See [docker.md](docker.md).                                                                            |
| [`neovim`](https://neovim.io/)                                                                                                         | Editor.                                                                                                                  |
| [`visual-studio-code-bin`](https://code.visualstudio.com/)                                                                             | Editor/IDE.                                                                                                              |
| [`jetbrains-toolbox`](https://www.jetbrains.com/toolbox-app/)                                                                          | JetBrains IDE manager.                                                                                                   |
| [`go`](https://go.dev/)                                                                                                                | Go toolchain.                                                                                                            |
| [`postman-bin`](https://www.postman.com/)                                                                                              | API client.                                                                                                              |
| [`postgresql`](https://www.postgresql.org/) + [`pgadmin4-bin`](https://www.pgadmin.org/) + `navicat-premium-lite-en`                   | Database + GUIs.                                                                                                         |
| [`flyctl`](https://fly.io/docs/flyctl/)                                                                                                | fly.io deployment CLI.                                                                                                   |
| [`gemini-cli`](https://github.com/google-gemini/gemini-cli)                                                                            | Terminal AI agent.                                                                                                       |

## Browsers & communication

| Package                                                                                                                                                                                         | Why                             |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [`firefox`](https://www.mozilla.org/firefox/) · [`google-chrome`](https://www.google.com/chrome/) · [`waterfox-bin`](https://www.waterfox.net/) · [`zen-browser-bin`](https://zen-browser.app/) | Browsers (testing + daily use). |
| [`slack-desktop-wayland`](https://slack.com/) · [`teams-for-linux-bin`](https://github.com/IsmaelMartinez/teams-for-linux)                                                                      | Work chat.                      |
| [`discord`](https://discord.com/)                                                                                                                                                               | Community chat.                 |

## Input method (Vietnamese)

| Package                                                                             | Why                        |
| ----------------------------------------------------------------------------------- | -------------------------- |
| [`fcitx5`](https://github.com/fcitx/fcitx5) + `fcitx5-bamboo` + `fcitx5-configtool` | Vietnamese (Bamboo) input. |

## Files, media & theming

| Package                                                                                                           | Why                                       |
| ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| [`thunar`](https://docs.xfce.org/xfce/thunar/start) + `tumbler` + `ffmpegthumbnailer`                             | File manager + thumbnails.                |
| [`meld`](https://meldmerge.org/)                                                                                  | Visual diff/merge.                        |
| [`mpv`](https://mpv.io/)                                                                                          | Media player.                             |
| [`pavucontrol`](https://freedesktop.org/software/pulseaudio/pavucontrol/)                                         | Audio control (PipeWire).                 |
| [`zathura`](https://pwmt.org/projects/zathura/)                                                                   | Minimal document viewer.                  |
| [`satty`](https://github.com/gabm/Satty) + [`gpu-screen-recorder`](https://git.dec05eba.com/gpu-screen-recorder/) | Screenshot annotation + screen recording. |
| `papirus-icon-theme` + `papirus-folders-git`                                                                      | Icons.                                    |
| `bibata-cursor-theme-bin` / `banana-cursor-bin`                                                                   | Cursors.                                  |
| `ttf-jetbrains-mono-nerd`, `noto-fonts{,-cjk,-emoji,-extra}`                                                      | Fonts.                                    |

## Networking & VPN

| Package                                                                             | Why                                          |
| ----------------------------------------------------------------------------------- | -------------------------------------------- |
| [`firewalld`](https://firewalld.org/)                                               | Firewall (see [firewalld.md](firewalld.md)). |
| [`blueman`](https://github.com/blueman-project/blueman) + `bluez`                   | Bluetooth.                                   |
| `globalprotect-openconnect`, `networkmanager-openconnect`, `networkmanager-openvpn` | Corporate VPN clients.                       |

## System & pacman helpers

| Package                                                                         | Why                            |
| ------------------------------------------------------------------------------- | ------------------------------ |
| [`yay`](https://github.com/Jguer/yay)                                           | AUR helper.                    |
| [`rate-mirrors-bin`](https://github.com/westandskif/rate-mirrors) / `reflector` | Mirror ranking.                |
| `downgrade`, `pacman-contrib`, `pkgfile`, `rebuild-detector`                    | Package maintenance utilities. |

## Installed outside pacman

Some tools come from an upstream script, source build, or vendor installer rather
than pacman/AUR, so they **won't** show up in the snapshots. Track them here:

| Tool                                                                            | Install method                                                         |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [starship](https://starship.rs/)                                                | Auto-installed — see below.                                            |
| [Claude Code](https://claude.com/claude-code)                                   | Auto-installed — see below.                                            |
| [Nix (Determinate)](https://determinate.systems/)                               | Determinate Nix installer (`determinate-nixd`) — manual, not automated |
| [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect) | Built from source — manual, not automated                              |

Unlike Nix and GlobalProtect (heavier, riskier to run unattended — a system
daemon install and a from-source build, respectively), starship and claude are
auto-installed by
[`run_once_after_install-external-tools.sh.tmpl`](../home/.chezmoiscripts/run_once_after_install-external-tools.sh.tmpl)
on `chezmoi apply`, gated by the same `installPackages` prompt as the
pacman/AUR script. Each install is guarded by `command -v`, so it's a no-op if
the tool is already present.

> [!TIP]
> To find hand-installed binaries not owned by pacman (pacman owns `/usr/bin`;
> these dirs hold manual installs):
>
> ```sh
> for d in /usr/local/bin ~/.local/bin; do echo "# $d"; ls "$d"; done
> pacman -Qo /usr/local/bin/* 2>&1 | grep -i 'No package owns'
> ```

---

> [!NOTE]
> The full, authoritative lists are in [`packages/`](../packages/). This page is
> curated for humans — when in doubt, the snapshots win.
