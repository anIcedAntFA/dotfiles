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
  <a href="https://ghostty.org/"><img alt="Ghostty" src="https://img.shields.io/badge/Ghostty-3551F3?logo=ghostty&logoColor=white&style=flat"></a>
  <a href="https://fishshell.com/"><img alt="fish" src="https://img.shields.io/badge/fish-34C534?logo=fishshell&logoColor=white&style=flat"></a>
  <a href="https://zed.dev/"><img alt="Zed" src="https://img.shields.io/badge/Zed-084CCF?logo=zedindustries&logoColor=white&style=flat"></a>
  <a href="https://www.waterfox.com/"><img alt="Waterfox" src="https://img.shields.io/badge/Waterfox-0B1E3F?logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAACXBIWXMAAABVAAAAVQFx6ibxAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm%2B48GgAABj1JREFUWIXll32MXFUZh5%2F33pnZ3S5jd%2BmuW4pgwbSh0GANaIHY2I%2BgjRpjgBoINKKQyFYDFQqmYrNWqxtptFQ%2BwjbgmhoT%2BTBBRUzEpJHGVGs%2FMCBBK7a1pbT71W1nh52555z39Y%2BZOzu7292GJoY%2FvMnJuffOOef5nd%2F7njPnipnxXl7Re0r%2FXwm4azDc0DkUXuocDLefra2cawjuGuJyLKwXkUWC%2FTPE8QM9M3kToHMw9CG0Y5R1VpzvATfVOOfkQOdQuFEs7BPhNrCFBjdEQX9ZayD8tVrv3wZ%2BurHetYDOYeYCvQgN43%2BxS9M7PT%2F%2BvKheXTodLzOY1uLMuxWA%2BrUg%2BYmvzaQ7ve8BR1t2L21nH%2B5cQnD9eDL9IvKVJ2ZF3VO0n%2FY6qwNroLVMcr2S%2B30vDGPSjgBwBPhuqRD%2FrHcupQdhYVPQbzSrzQ9mvki0k1z0nS54Z7rxa6tA9pJtjI9fWFo0%2B3B93G5M%2FJ%2FUuE7Ftv8ql%2F1i55C%2BgtihYhLfur2D4voQbrkE2fJBtY6Jdh5TRl4ZjS%2Fa0sJw%2Bm7j48XZf29v7n9mFQEgIyCZvw1syEZ2f%2FDxeZnd%2FW%2Fl1DYl17z%2FiY8PkI8buU5NUOMkOTCxDRe0xr%2F7Nmik%2BuQtyh3RFHk2O%2BK8WPgo8NL9Wwt3xEJ3JLTPPzFyuusx%2B340kN8s2f199xB42BQIQBAIYIHPhmVtL14%2BGI4qzPGmVx1oy%2B4D%2BALEryu9dwZdfcUUcGfwFyc%2F3NgcrbvnR6c%2FLSIvxIJEAmnJRLImwvM181S2CieVVevBPJsABhzr%2B8ui%2FzqcfTUd%2FLVEu4Oz1RdPsYmVDNtZ0q9ubI7WASTGJqcmiRpODafgFEpq92bMMQuV6uzBqrUoizK%2FHVxx4jOztstBDtlVld3sihIrzGSdKZSykAdOKASEOZFx1KNvlPXOH7RkewFuf%2BjUiozwkQiIRAgCsVjFBZO2DD7aTbBPEWAsDKkYuxf4g13CywBXQzYEe8QUMTWe8nABwr4EUCOP6Nujdut%2F5mZ%2FkbrhlftUIAaiKjiIEAtE2M7IvD1uFcurYUhDIJiXlfL04IJ0sEKBu9XbAvWGOThcFnaNGiVnjDo4cEx3nuxnedr%2Bpu7By5zaSqdGUmd9%2BpyIPBmFZW2%2FkYQ30tjjwZykQiRyshbg0iId6nWDOTAH6q1aQB0kBXu1XGSJKl%2FO70kWAjgffd2pSQqekAMHLizkX4gMTFUexVXA5scSsfLOVsu2Qls8qpvMMXMc2IM5Q50lw2%2FbDJSIYLFZvPlzGwttTrktqc44BafP3vTHXV1oBKAn%2FU%2FNyxCTwgB4mhreF7rU25cmgs1VngvH2WWBD6GAggVWHm%2Fle05tRsXuMeur9p%2BMM0kvVP8LbHVHEce2erDVhAgt82csUU%2BsHsyPgdVDKDNUHtYrUSAYFRHGoQUNy5wS6mNesz%2FQs31dR7EmAEDFHjFPYnUO4IVsQ7yrqS3%2BcA3sqMIN80bhSHgNpRWtrqJqKebjeafy0a4a1Gr2u4A9lnJrAuzmtmPieTYF4wTzlNoXN12kfjLYKsn3D1dkltXPvs6Fg4ub5yVKcSwHjER57sWu849OEgAQR%2FYwTkrpsmyek%2F1zlIs%2BoG4SGHWGen3AjG%2BiVpt5bS9RcA1RR%2F%2Fc3J50CSaB4qnmzJZ65qQz4ew9yTMjB8vtuZa4sfni3DVWHdzSEgxTUJUdfR%2FLLgdoera8g6wslQyQFdKaDEhGaPl3eVfjcCgXLmsYOLE0t6qeN%2Bk8kJ0ZP916ZdNzptUZTwBX46wY943ZGK1T1d2oRATDIkFCxV9TGJ7XcC0ZQTJ200TepBPR0Xnx8%2BbtTfNjMVdXsd6qqyAEtvddm92f9imuyu4lyM%2FrkxC1aihq9cGR1%2BPnzyrAIKjj0RrYVcC1DchRpBy%2BNbGfhPAgwUbTRKwXYwp42WrVQ8i0AgDK5exPzDE8DlxNPoJ1Dyxvemtin3dubjqC2uYaePzsh2YUo6fOxDqjgMHFnDavd6s3TcGVzcd2D85sfOhMfQBKxcZuC7Y%2FDUFVjJmXzr6ljJypz7RfRq07Sp%2BIjDUWaEH5Y04atx7%2FJMUpOwDya%2FKNPlkbNcgSi%2Bi3BukZXZ55ecr2%2F%2Fdfx%2F8FI2BS%2FuuB62MAAAAASUVORK5CYII%3D&style=flat"></a>
</p>

<!-- TODO: desktop screenshots (niri + Noctalia), one per mode, then uncomment.
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="images/screenshot/desktop-dark.png">
    <img alt="niri + Noctalia desktop" src="images/screenshot/desktop-light.png">
  </picture>
</p>
-->

> [!NOTE]
> This is tuned for **my own machines**. Read each config before applying it —
> don't copy blindly. Everything private (emails, work host, location) is
> templated, so you supply your own values on first run.

## Contents

- [At a glance](#at-a-glance)
- [Architecture](#architecture)
- [How a machine gets configured](#how-a-machine-gets-configured)
- [Machine profiles](#machine-profiles)
- [Quick start](#quick-start)
- [Repo layout](#repo-layout)
- [Guides](#guides)
- [Development](#development)
- [Credits](#credits)

## At a glance

| Layer            | Choice                                                                                                                              |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Distro**       | [EndeavourOS](https://endeavouros.com/) (Arch), "no desktop" base · [yay](https://github.com/Jguer/yay) for AUR                     |
| **Login**        | [greetd](https://sr.ht/~kennylevinsen/greetd/) + tuigreet                                                                           |
| **Compositor**   | [niri](https://github.com/niri-wm/niri) — scrollable tiling, Wayland                                                                |
| **Shell (UI)**   | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) — bar, launcher, lock screen, wallpaper                                  |
| **Light / dark** | [darkman](https://darkman.whynothugo.nl/) — sunrise/sunset schedule + keybind, fanned out to every app                              |
| **Terminal**     | [Ghostty](https://ghostty.org/) + [zellij](https://zellij.dev/) · [fish](https://fishshell.com/) + [starship](https://starship.rs/) |
| **Editor**       | [Zed](https://zed.dev/) daily, [VS Code](https://code.visualstudio.com/) alongside                                                  |
| **Browser**      | [Waterfox](https://www.waterfox.com/)                                                                                               |
| **Files**        | [Nautilus](https://apps.gnome.org/Nautilus/) (GUI) · [superfile](https://superfile.dev/) (TUI)                                      |
| **Runtimes**     | [mise](https://mise.jdx.dev/) — node, pnpm, go, bun, yarn                                                                           |
| **Secrets**      | [gopass](https://www.gopass.pw/) (GPG + git) · gnome-keyring for desktop apps                                                       |
| **Dotfiles**     | [chezmoi](https://www.chezmoi.io/) — [why (ADR)](docs/adr/0001-adopt-chezmoi.md)                                                    |

## Architecture

Each layer starts the one above it. **darkman** sits beside the stack: it owns
the light/dark mode and pushes it to every layer
([theme-sync.md](docs/theme-sync.md)).

```mermaid
flowchart BT
    base["<b>EndeavourOS</b> · Arch, no-desktop base<br/>pacman + yay · zram · firewalld"]
    login["<b>greetd</b> + tuigreet<br/>PAM unlocks gnome-keyring"]
    niri["<b>niri</b><br/>scrollable-tiling Wayland compositor"]
    noctalia["<b>Noctalia</b><br/>bar · launcher · lock · wallpaper"]
    apps["<b>Daily apps</b><br/>Ghostty · Zed · Waterfox · Nautilus"]
    term["<b>Terminal</b><br/>zellij · fish · starship · mise"]
    darkman(["<b>darkman</b><br/>light / dark mode"])

    base --> login --> niri
    niri --> noctalia
    niri --> apps
    apps --> term
    darkman -. mode .-> noctalia
    darkman -. mode .-> apps
    darkman -. mode .-> term
```

<details>
<summary>How one light/dark switch reaches every app</summary>

```mermaid
flowchart LR
    trigger["sunrise / sunset<br/>or keybind"] --> darkman(["darkman"])
    darkman --> scheme["set-color-scheme hook"]
    darkman --> wall["set-wallpaper hook"]
    scheme --> gs["gsetting color-scheme"] --> portal["gtk portal"]
    portal --> apps["GTK · Ghostty · Zed · Waterfox<br/>VS Code · Chrome · Discord"]
    scheme --> direct["Noctalia · fish · Papirus<br/>superfile · Zed font weight"]
    wall -- "Noctalia IPC" --> monitors["one image per monitor<br/>*-light / *-dark"]
```

Apps that read the portal follow on their own. The hook drives the rest
directly. The wallpaper has no portal fallback, which is why it gets its own
hook. See [ADR 0019](docs/adr/0019-darkman-owns-mode-noctalia-follows.md).

</details>

## How a machine gets configured

Only `home/` goes through chezmoi. Your private answers live in a gitignored
`chezmoi.toml` on each machine, never in this repo. Files under `etc/` and
`windows/` are copied **by hand**, since they need root or another OS.

```mermaid
flowchart LR
    subgraph repo["dotfiles repo (public)"]
        src["home/<br/>chezmoi source"]
        pkgs["packages/<br/>snapshots"]
        etc["etc/"]
        win["windows/"]
    end
    vars["chezmoi.toml<br/>email · machine · work host<br/><i>gitignored, per box</i>"]
    apply(("chezmoi<br/>apply"))
    home["$HOME<br/>~/.config · ~/.local · ~/.ssh"]
    sys["/etc<br/>greetd · pam · zram · hosts"]
    host["Windows host<br/>GlazeWM · WezTerm · .wslconfig"]

    src --> apply
    vars --> apply
    pkgs -- "installPackages = yes" --> apply
    apply --> home
    etc -. "sudo cp, by hand" .-> sys
    win -. "copy, by hand" .-> host
```

## Machine profiles

One config, three boxes. The `machine` answer picks the **profile**. Templates
such as niri outputs, Noctalia DPI and wallpapers branch on it
([ADR 0006](docs/adr/0006-per-machine-niri-via-chezmoi-template.md)).

| Profile  | Outputs                                | Extras beyond the shared snapshot |
| -------- | -------------------------------------- | --------------------------------- |
| `home`   | `DP-3` landscape + `HDMI-A-1` portrait | NVIDIA driver stack               |
| `work`   | `DP-1` landscape + `HDMI-A-2` portrait | —                                 |
| `laptop` | `eDP-1` internal panel                 | `brightnessctl`                   |

There is a second, independent question: **where** the config runs. On a
**Desktop host** (Linux on the hardware) everything applies. In a **WSL guest**
only the terminal layer applies, and the **Windows host** around it provides
the desktop ([windows.md](docs/windows.md)). Terms are defined in
[CONTEXT.md](CONTEXT.md).

## Quick start

> [!WARNING]
> Applying these dotfiles overwrites files in your `$HOME`. Review first, and
> ideally test in a VM or a fresh user account.

```sh
# 1. Install chezmoi
yay -S --needed chezmoi

# 2. Clone and apply. You'll be asked for your email, name, work git host,
#    ghq roots, machine profile, location (for sunrise/sunset), and whether
#    to install packages.
chezmoi init --apply https://github.com/anIcedAntFA/dotfiles.git

# 3. Preview later changes before applying them
chezmoi diff
```

If you skipped automatic package install, install the shared snapshot yourself,
then any [per-profile extras](docs/packages.md#per-profile-extras):

```sh
yay -S --needed - < packages/pacman-explicit.txt
yay -S --needed - < packages/aur.txt
```

## Repo layout

```text
dotfiles/
├── home/                    chezmoi source (.chezmoiroot points here)
│   ├── .chezmoi.toml.tmpl     first-run prompts → your private chezmoi.toml
│   ├── .chezmoiscripts/       run_onchange: packages, VS Code extensions, darkman
│   ├── dot_config/            → ~/.config  (niri, noctalia, fish, ghostty, zed, …)
│   ├── dot_local/             → ~/.local   (bin/ helpers, darkman hooks)
│   ├── private_dot_ssh/       → ~/.ssh     (0600, templated hosts)
│   └── private_dot_gnupg/     → ~/.gnupg
├── etc/                     /etc files, applied by hand (greetd, pam, zram, pacman)
├── windows/                 Windows-host config, applied by hand (GlazeWM, WezTerm, WSL)
├── packages/                snapshots: desktop, WSL, winget, VS Code extensions
├── docs/                    per-tool guides
│   ├── adr/                   Architecture Decision Records
│   └── research/              source notes behind larger decisions
├── images/
│   ├── wallpaper/             <subject>-light / -dark pairs + CREDITS.md
│   └── thumbnail/             fastfetch logo art sources
├── CONTEXT.md               glossary: the words this repo uses, and the ones it avoids
└── mise.toml · justfile · dprint.json · lefthook.yml · .github/   tooling
```

## Guides

Each guide covers **what the tool is, why it's here, and how it's set up**.
Larger decisions are recorded as [ADRs](docs/adr/).

<details open>
<summary>Desktop — niri, Noctalia, login, theming</summary>

| Guide                                             | About                                                     |
| ------------------------------------------------- | --------------------------------------------------------- |
| [niri.md](docs/niri.md)                           | The compositor + Noctalia shell (start here)              |
| ⤷ [niri-concepts.md](docs/niri-concepts.md)       | Mental model: columns, workspaces, outputs                |
| ⤷ [niri-config.md](docs/niri-config.md)           | Config walkthrough, one file for three machines           |
| ⤷ [niri-keybindings.md](docs/niri-keybindings.md) | Every keybind ↔ action                                    |
| [theme-sync.md](docs/theme-sync.md)               | Light/dark sync: darkman + gtk portal, schedule + keybind |
| [greetd.md](docs/greetd.md)                       | Login manager, tuigreet, quiet boot                       |
| ⤷ [secret-service.md](docs/secret-service.md)     | Desktop keychain: gnome-keyring auto-unlock via PAM       |
| [xdg-environment.md](docs/xdg-environment.md)     | `/etc/environment` vs `environment.d` vs portals          |
| [fcitx5.md](docs/fcitx5.md)                       | Vietnamese input (Bamboo)                                 |
| [screenshot.md](docs/screenshot.md)               | grim + slurp + satty                                      |
| [screen-recording.md](docs/screen-recording.md)   | GPU screen recording                                      |
| [clipboard.md](docs/clipboard.md)                 | Clipboard history (cliphist + Noctalia launcher)          |

</details>

<details>
<summary>Terminal & shell — Ghostty, fish, prompt, search</summary>

| Guide                             | About                                                   |
| --------------------------------- | ------------------------------------------------------- |
| [ghostty.md](docs/ghostty.md)     | Terminal: keybinds, transparency, cursor shaders        |
| ⤷ [zellij.md](docs/zellij.md)     | Multiplexer: sessions, project layouts, the `zj` picker |
| [fish.md](docs/fish.md)           | Shell, plugins, keybindings, secrets pattern            |
| ⤷ [starship.md](docs/starship.md) | Prompt layout, the TOML quoting trap, module cost       |
| ⤷ [zoxide.md](docs/zoxide.md)     | Frecency directory jumping (`z` / `zi`)                 |
| [fastfetch.md](docs/fastfetch.md) | System-info banner with random per-mode logos           |
| [ripgrep.md](docs/ripgrep.md)     | Fast content search, and what a search silently skips   |
| ⤷ [fd.md](docs/fd.md)             | Find files by name; global ignore file                  |
| [ghq.md](docs/ghq.md)             | Organized repo cloning + fuzzy jumping                  |
| [direnv.md](docs/direnv.md)       | Per-directory environments                              |
| [archives.md](docs/archives.md)   | 7zz · ouch · PeaZip                                     |

</details>

<details>
<summary>Editors & development — Zed, VS Code, runtimes, AI agents</summary>

| Guide                                 | About                                                         |
| ------------------------------------- | ------------------------------------------------------------- |
| [zed.md](docs/zed.md)                 | Curated config, per-mode font weight, keymap cheat-sheet      |
| [vscode.md](docs/vscode.md)           | Themes, custom.css font weight, formatter routing, extensions |
| [waterfox.md](docs/waterfox.md)       | Install, pinned profile, policies, vertical tabs              |
| [mise.md](docs/mise.md)               | Global runtimes vs this repo's pinned tooling                 |
| [git.md](docs/git.md)                 | Identities, `includeIf`, SSH commit signing                   |
| [docker.md](docs/docker.md)           | Engine setup, rootless use, daemon config                     |
| [claude-code.md](docs/claude-code.md) | Personal + work accounts, the `rg`/`fd` search rule           |
| [rtk.md](docs/rtk.md)                 | Token proxy for AI agents, and what compression costs         |

</details>

<details>
<summary>Security & network — keys, passwords, certs, VPN</summary>

| Guide                             | About                                      |
| --------------------------------- | ------------------------------------------ |
| [ssh.md](docs/ssh.md)             | SSH keys per host (personal + work)        |
| [gopass.md](docs/gopass.md)       | Terminal password manager (GPG + git)      |
| [certs.md](docs/certs.md)         | Corporate CA certs, trust-store restore    |
| [vpn.md](docs/vpn.md)             | Corporate VPN (GlobalProtect / `gpclient`) |
| [firewalld.md](docs/firewalld.md) | Exposing a dev server to your LAN          |

</details>

<details>
<summary>System — packages, memory, dotfile workflow, Windows</summary>

| Guide                           | About                                                      |
| ------------------------------- | ---------------------------------------------------------- |
| [chezmoi.md](docs/chezmoi.md)   | Daily workflow: templates, add / re-add, diff              |
| [packages.md](docs/packages.md) | What's installed and why; snapshots and per-profile extras |
| [zram.md](docs/zram.md)         | Compressed RAM swap, and why zero swap kills apps          |
| [windows.md](docs/windows.md)   | Windows host + Arch WSL guest: the split and setup order   |

</details>

<details>
<summary>Theory (tiếng Việt)</summary>

| Guide                                                         | About                                                     |
| ------------------------------------------------------------- | --------------------------------------------------------- |
| [memory-swap-concepts.vi.md](docs/memory-swap-concepts.vi.md) | RAM, paging, OOM, zram vs zswap: the _why_ behind zram    |
| [search-concepts.vi.md](docs/search-concepts.vi.md)           | grep vs rg, find vs fd, and what a search silently misses |

</details>

## Development

This repo formats and lints itself. See [CONTRIBUTING.md](CONTRIBUTING.md).

```sh
mise trust    # once: allow this repo's mise.toml
just setup    # install the pinned tooling + git hooks
just check    # format check + lint + secret scan (what CI runs)
just fmt      # auto-format everything
```

Every dev tool is pinned to an exact version in [`mise.toml`](mise.toml), so CI
and every checkout run the same ones. Upgrade on purpose with `mise up --bump`.
There's no Node or pnpm in the repo
([ADR 0007](docs/adr/0007-node-free-toolchain-via-mise.md)).

| Job     | Tools                                                                                            |
| ------- | ------------------------------------------------------------------------------------------------ |
| Format  | [dprint](https://dprint.dev/) (md/json/yaml/toml) · `shfmt` · `fish_indent`                      |
| Lint    | [rumdl](https://github.com/rvben/rumdl) (Markdown) · `shellcheck` · `just validate-niri` (local) |
| Secrets | [gitleaks](https://github.com/gitleaks/gitleaks) in the pre-commit hook, pre-push and CI         |

## Credits

Heavy inspiration from:

- [devaslife](https://github.com/craftzdog/dotfiles-public) — Takuya Matsuyama
- [mantran1611](https://github.com/manhtran1611/dotfiles) — Manh Tran
- [lazarus2019](https://github.com/lazarus2019) — Thai Son
- [nickjj](https://github.com/nickjj/dotfriedrice) — Nick Janetakis

Wallpaper sources and licences: [images/wallpaper/CREDITS.md](images/wallpaper/CREDITS.md).

Many thanks to my colleagues at **NDVN** for introducing me to Linux and guiding
me along the way. You're amazing and kind. 🙏

## License

[MIT](LICENSE) © ngockhoi96
