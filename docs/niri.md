# niri + Noctalia

## Why

[niri](https://github.com/YaLTeR/niri) is a **scrollable-tiling** Wayland
compositor: windows live on an infinite horizontal strip instead of being
crammed into a fixed grid. You scroll between them, and columns never overlap or
resize each other unexpectedly. [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
provides the bar, launcher, notifications, and widgets on top.

## Install

```sh
yay -S --needed niri xwayland-satellite noctalia-shell noctalia-qs \
	xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
	swaybg swaylock wlsunset cliphist fuzzel
```

## Config layout

| File                                                                        | What it holds                                                                                        |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`home/dot_config/niri/config.kdl`](../home/dot_config/niri/config.kdl)     | Main config: `input`, `output`, `layout`, `binds`, `window-rule`s, `animations`, `spawn-at-startup`. |
| [`home/dot_config/niri/noctalia.kdl`](../home/dot_config/niri/noctalia.kdl) | Noctalia-specific niri bits (kept separate for clarity).                                             |
| [`home/dot_config/environment.d/*.conf`](../home/dot_config/environment.d/) | Session env vars (`XDG_CURRENT_DESKTOP=niri`, Wayland session type, `PATH`, XDG user dirs).          |

niri uses the [KDL](https://kdl.dev/) document language, so it isn't touched by
oxfmt — validate it instead (see below).

## Autostart

`spawn-at-startup` in `config.kdl` launches the shell and your daily apps:
Noctalia (`qs -c noctalia-shell`), Ghostty, Zen browser, Slack, Teams.

## X11 apps

`xwayland-satellite` runs rootless Xwayland so legacy X11 apps work under niri
without a full rootful X server.

## Everyday commands

```sh
niri validate                 # check the config before reloading
niri msg action <action>      # trigger actions (e.g. screenshot-window)
niri msg --json focused-output # query state as JSON
```

niri hot-reloads `config.kdl` on save. Run `just validate-niri` to check this
repo's config file explicitly.

## Screenshots

The [`dot-screenshot`](../home/dot_local/bin/dot-screenshot) script wires niri +
`grim`/`slurp` into [satty](satty.md) for annotation. Keybinds live in the
`binds` block of `config.kdl`.

## References

- [niri wiki](https://github.com/YaLTeR/niri/wiki)
- [niri configuration reference](https://github.com/YaLTeR/niri/wiki/Configuration:-Overview)
- [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell)
