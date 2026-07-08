<h1 align="center">🏠 dotfiles</h1>

<p align="center">
  A personal EndeavourOS desktop — niri + Noctalia, managed with chezmoi.
</p>
<p align="center">
  <sub>Reproducible on a fresh machine, and safe to share publicly.</sub>
</p>

<p align="center">
  <a href="https://github.com/anIcedAntFA/dotfiles/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/anIcedAntFA/dotfiles/ci.yml?branch=main&logo=githubactions&logoColor=white&label=CI&style=flat"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue?style=flat"></a>
  <a href="https://www.chezmoi.io/"><img alt="managed with chezmoi" src="https://img.shields.io/badge/managed%20with-chezmoi-1673ff?style=flat"></a>
</p>
<p align="center">
  <a href="https://archlinux.org"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch%20Linux-1793D1?logo=archlinux&logoColor=white&style=flat"></a>
  <a href="https://github.com/niri-wm/niri"><img alt="niri" src="https://img.shields.io/badge/niri-D55C44?logo=niri&logoColor=white&style=flat"></a>
  <a href="https://github.com/noctalia-dev/noctalia-shell"><img alt="Noctalia" src="https://img.shields.io/badge/Noctalia-0e0e43?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2Ny43IDY3LjciPjxnIHN0eWxlPSJmaWxsOiNmZmY7c3Ryb2tlOiMwZTBlNDM7c3Ryb2tlLXdpZHRoOjYuMjE3NiI%2BPGcgc3R5bGU9ImZpbGw6I2ZmZjtzdHJva2U6IzBlMGU0MztzdHJva2Utd2lkdGg6MTcuOTgyMyI%2BPGcgc3R5bGU9ImZpbGw6I2ZmZjtzdHJva2U6IzBlMGU0MztzdHJva2Utd2lkdGg6MS40Nzg1Ij48cGF0aCBkPSJNMTEuNiA0My42YTcuMyA3LjMgMCAxIDAgNy4yIDguOCA2IDYgMCAwIDEtMy40IDMuNHYuOHEtMSAwLTItLjNIMTNhNi4yIDYuMiAwIDEgMSAuNi0xMi40cS0xLS4zLTItLjNtLTMgMy4xcTAgLjkuNyAxVjQ5cTAgMS41IDEuNSAybC0uOS0uM3EtLjYuMi0uNiAxLjFjLjMgNCAyLjggMy44IDIuOSAzLjgtMS45LTEtMS42LTIuNC0xLjYtMi45IDAgLjguOSAzIDQgMyAwLS45IDAtMy4zLS4zLTQgMC0uNC0uMy0xLjItLjYtMS4zcS0uNS41LTEuMS42IDEuMy0uNiAxLjQtMnYtMS4xcS41LS40LjgtMWwtMiAuMS0xLjItLjEtMS4yLjF6IiBzdHlsZT0iZmlsbDojZmZmO3N0cm9rZTojMGUwZTQzO3N0cm9rZS13aWR0aDoxLjQ3ODU7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuOCAtMTgwLjQpc2NhbGUoNC4yMDU2KSIvPjwvZz48L2c%2BPC9nPjxnIHN0eWxlPSJmaWxsOiNmZmY1OWIiPjxwYXRoIGQ9Ik0xMS42IDQzLjZBNy4zIDcuMyAwIDAgMCA0LjMgNTFhNy4zIDcuMyAwIDAgMCA3LjMgNy4zIDcgNyAwIDAgMCA3LjItNiA2IDYgMCAwIDEtMy40IDMuNXYuOHEtMSAwLTItLjNIMTNhNiA2IDAgMCAxLTYuMi02LjJBNiA2IDAgMCAxIDEzIDQ0aC42eiIgc3R5bGU9ImZpbGw6I2ZmZjU5YjtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6MTtzdHJva2UtbGluZWNhcDpyb3VuZDtzdHJva2UtbGluZWpvaW46cm91bmQiIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xNC44IC0xODAuNClzY2FsZSg0LjIwNTYpIi8%2BPC9nPjxwYXRoIGQ9Ik00Mi43IDMxLjNjLTEuOCAyLTUgMi41LTguNiAyLjUtMi43IDAtNS40LS4xLTcuMi0xLjQtMS44LjMtMi42IDIuMy0yLjQgNC43QzI1LjYgNTQgMzYuMyA1Mi44IDM2LjQgNTIuOGMtNy44LTMuOC02LjYtMTAtNi44LTEyIC4zIDMuNCAzLjkgMTIuOSAxNy4yIDEyLjkgMC00IDAtMTQuMy0xLjMtMTcuNS0uNC0xLjItMS41LTQuNS0yLjgtNSIgc3R5bGU9ImZpbGw6I2E5YWVmZTtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6MS4zNDYwOCIvPjxwYXRoIGQ9Ik0yNS45IDE5LjdoMTYuM3YxMC41SDI1Ljl6IiBzdHlsZT0iZmlsbDojZjNlZGY3O3N0cm9rZS13aWR0aDo2LjI5ODM5O3N0cm9rZS1saW5lY2FwOnNxdWFyZTtzdHJva2UtbGluZWpvaW46cm91bmQiLz48cGF0aCBkPSJNMjEgMTZjLjYgMiAxLjggMy44IDMuNSA0LjVxLS42IDIuMS0uNSA0LjhjMCA0LjkgNC41IDguOSAxMC4xIDkgNS42LS4xIDEwLjItNC4xIDEwLjItOXEuMS0yLjctLjUtNC44YzEuNy0uNyAyLjktMi41IDMuNS00LjQtMiAwLTUuMi43LTcuOS44cS0xLjktLjYtNS4zLS42LTMuMyAwLTUuMy42Yy0yLjctLjEtNS44LS44LTcuOC0uOG02LjggNC43IDIuMy4zIDIgLjdjMSAuNiAxIDEuMiAyIDEuMnMxLjEtLjYgMi0xLjJsMi4xLS43YzQuNi0uOSAzLjguNSAzLjggMi44YTQuMyA0LjMgMCAwIDEtNi41IDMuN3YuMWwtMSAxLjZxMCAuMy0uNC4zbC0uMy0uMy0xLTEuNmE0LjMgNC4zIDAgMCAxLTYuNS0zLjhjMC0xLjgtLjUtMyAxLjUtMyIgc3R5bGU9ImZpbGw6I2E5YWVmZTtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6My43NjU2NSIvPjxwYXRoIGQ9Ik0zMi4zIDI1LjNhMiAyIDAgMCAxLTEuNyAxIDIgMiAwIDAgMS0xLjctMU0zOS40IDI1LjNhMiAyIDAgMCAxLTEuNyAxIDIgMiAwIDAgMS0xLjctMSIgc3R5bGU9ImZpbGw6bm9uZTtzdHJva2U6IzBlMGU0MztzdHJva2Utd2lkdGg6MS4yMjA1MjtzdHJva2UtbGluZWNhcDpyb3VuZCIvPjwvc3ZnPg%3D%3D&style=flat"></a>
  <a href="https://fishshell.com/"><img alt="fish" src="https://img.shields.io/badge/fish-34C534?logo=fishshell&logoColor=white&style=flat"></a>
  <a href="https://ghostty.org/"><img alt="Ghostty" src="https://img.shields.io/badge/Ghostty-3551F3?logo=ghostty&logoColor=white&style=flat"></a>
</p>

<!-- TODO: replace with a current desktop screenshot (niri + Noctalia). -->
<!-- <img alt="desktop" src="images/screenshot/desktop-01.png"> -->

<p align="center">
  <img alt="terminal" src="images/screenshot/terminal-desktop-light.png">
</p>

> [!NOTE]
> This is tuned for **my personal laptop**. Read each config before applying it —
> don't copy blindly. Everything private (emails, work host, hostnames) is
> templated, so you supply your own values on first run.

## Table of contents

- [Table of contents](#table-of-contents)
- [What I use](#what-i-use)
- [Quick start](#quick-start)
- [How it's organized](#how-its-organized)
- [Guides](#guides)
- [Packages](#packages)
- [Development](#development)
- [Credits](#credits)
- [License](#license)

## What I use

| Layer               | Choice                                                                              |
| ------------------- | ----------------------------------------------------------------------------------- |
| **Distro**          | [EndeavourOS](https://endeavouros.com/) (Arch-based), "no desktop" base             |
| **AUR helper**      | [yay](https://github.com/Jguer/yay)                                                 |
| **Compositor**      | [niri](https://github.com/niri-wm/niri) — scrollable tiling, Wayland                |
| **Shell (desktop)** | [Noctalia](https://github.com/noctalia-dev/noctalia-shell)                          |
| **Login**           | [greetd](https://sr.ht/~kennylevinsen/greetd/) + tuigreet — [guide](docs/greetd.md) |
| **Terminal**        | [Ghostty](https://ghostty.org/) — [guide](docs/ghostty.md)                          |
| **Shell**           | [fish](https://fishshell.com/) — [guide](docs/fish.md)                              |
| **Prompt**          | [starship](https://starship.rs/)                                                    |
| **Dotfile manager** | [chezmoi](https://www.chezmoi.io/) — [why (ADR)](docs/adr/0001-adopt-chezmoi.md)    |

<details>
<summary>A note on the base install</summary>

I install EndeavourOS in **"no desktop"** mode (minimal Arch, no DE) and build the
niri + Noctalia environment on top. See [docs/packages.md](docs/packages.md) for
the full package story.

</details>

## Quick start

> [!WARNING]
> Applying these dotfiles overwrites files in your `$HOME`. Review first, and
> ideally test in a VM or a fresh user account.

```sh
# 1. Install chezmoi
yay -S --needed chezmoi

# 2. Pull this repo and apply it. You'll be prompted for your email, name,
#    work git host/port, ghq roots, and whether to auto-install packages.
chezmoi init --apply https://github.com/anIcedAntFA/dotfiles.git
```

Your answers are stored in `~/.config/chezmoi/chezmoi.toml` (never committed) and
injected into templates like `~/.gitconfig` and `~/.ssh/config`. To preview
changes before applying: `chezmoi diff`.

Then, if you didn't opt into package auto-install, install them manually:

```sh
yay -S --needed - < packages/pacman-explicit.txt
yay -S --needed - < packages/aur.txt
```

System files under [`etc/`](etc/) (hosts, greetd) are **not** managed by chezmoi —
copy them by hand with `sudo` where noted in the guides.

## How it's organized

```text
dotfiles/
├── home/            ← chezmoi source (.chezmoiroot points here)
│   ├── dot_config/          → ~/.config/*
│   ├── dot_local/           → ~/.local/*
│   ├── private_dot_ssh/     → ~/.ssh/*  (0600)
│   ├── dot_gitconfig.tmpl   → ~/.gitconfig  (templated)
│   └── .chezmoi.toml.tmpl   prompts for your private values
├── docs/            per-tool guides + Architecture Decision Records (adr/)
├── packages/        reproducible package snapshots
├── etc/             system files (/etc/*) — applied manually
├── images/          screenshots & wallpapers
└── justfile, lefthook.yml, .oxfmtrc.json, .github/  tooling
```

## Guides

Each tool has a focused guide covering **what it is, why, and how to set it up**:

| Guide                                             | About                                                   |
| ------------------------------------------------- | ------------------------------------------------------- |
| [chezmoi.md](docs/chezmoi.md)                     | Dotfile manager — workflows, templates, add/re-add      |
| [niri.md](docs/niri.md)                           | The scrollable-tiling compositor + Noctalia shell (hub) |
| ⤷ [niri-concepts.md](docs/niri-concepts.md)       | niri's mental model — columns, workspaces, outputs      |
| ⤷ [niri-config.md](docs/niri-config.md)           | Config walkthrough + one-file-three-machines template   |
| ⤷ [niri-keybindings.md](docs/niri-keybindings.md) | Full Keybind ↔ Action tables                            |
| [ghostty.md](docs/ghostty.md)                     | Terminal, cursor shaders, theming                       |
| [fish.md](docs/fish.md)                           | Shell, plugins, keybindings, secrets pattern            |
| [fastfetch.md](docs/fastfetch.md)                 | System-info banner — random Arch logo, per-machine      |
| [ghq.md](docs/ghq.md)                             | Organized repo cloning + fuzzy jumping                  |
| [ssh.md](docs/ssh.md)                             | SSH keys per host (personal + work auth)                |
| [git.md](docs/git.md)                             | Git identities, `includeIf`, SSH commit signing         |
| [gopass.md](docs/gopass.md)                       | Terminal password manager (GPG + git)                   |
| [certs.md](docs/certs.md)                         | Corporate CA certs — trust store restore                |
| [vpn.md](docs/vpn.md)                             | Corporate VPN (GlobalProtect / `gpclient`)              |
| [docker.md](docs/docker.md)                       | Engine setup, rootless usage, daemon config             |
| [firewalld.md](docs/firewalld.md)                 | Exposing a dev server to your LAN                       |
| [greetd.md](docs/greetd.md)                       | Login manager + tuigreet + quiet boot                   |
| [fcitx5.md](docs/fcitx5.md)                       | Vietnamese input (Bamboo)                               |
| [screenshot.md](docs/screenshot.md)               | Screenshot pipeline (grim/slurp/satty)                  |
| [screen-recording.md](docs/screen-recording.md)   | GPU screen recording (wl-screenrec)                     |
| [mise.md](docs/mise.md)                           | Runtime / dev-env version management                    |
| [direnv.md](docs/direnv.md)                       | Per-directory environments (`.envrc`)                   |
| [tuxedo.md](docs/tuxedo.md)                       | todo.txt task TUI + niri float keybind                  |

Bigger design decisions are recorded as [ADRs](docs/adr/).

## Packages

The full, reproducible lists live in [`packages/`](packages/); a curated,
grouped, and explained subset is in [docs/packages.md](docs/packages.md).

## Development

This repo lints and formats itself. See [CONTRIBUTING.md](CONTRIBUTING.md).

```sh
just setup    # install tooling + git hooks
just check    # format check + lint + secret scan (what CI runs)
just fmt      # auto-format everything
```

- **Format:** [oxfmt](https://oxc.rs/docs/guide/usage/formatter.html) (md/json/yaml/toml),
  `shfmt` (shell), `fish_indent` (fish)
- **Lint:** [markdownlint](https://github.com/DavidAnson/markdownlint), `shellcheck`
- **Secrets:** [gitleaks](https://github.com/gitleaks/gitleaks) in the pre-commit hook and CI

## Credits

Heavy inspiration from:

- [devaslife](https://github.com/craftzdog/dotfiles-public) — Takuya Matsuyama
- [mantran1611](https://github.com/manhtran1611/dotfiles) — Manh Tran
- [lazarus2019](https://github.com/lazarus2019) — Thai Son
- [nickjj](https://github.com/nickjj/dotfriedrice) — Nick Janetakis

Many thanks to my colleagues at **NDVN** for introducing me to Linux and guiding
me along the way. You're amazing and kind. 🙏

## License

[MIT](LICENSE) © ngockhoi96

Read /tmp/niri-fastfetch-handoff.md, and continue with:
