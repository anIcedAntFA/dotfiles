# niri + Noctalia

## Why

[niri](https://github.com/niri-wm/niri) is a **scrollable-tiling** Wayland
compositor: windows live on an infinite horizontal strip instead of being
crammed into a fixed grid. You scroll between them, and columns never overlap or
resize each other unexpectedly. [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
provides the bar, launcher, notifications, and widgets on top.

## In-depth guides

This page is the quick-reference hub. The deep dives:

| Guide                                      | Covers                                                      |
| ------------------------------------------ | ----------------------------------------------------------- |
| [niri-concepts.md](niri-concepts.md)       | The mental model — columns, workspaces, outputs, overview   |
| [niri-config.md](niri-config.md)           | Every config section + the one-file-three-machines template |
| [niri-keybindings.md](niri-keybindings.md) | Full Keybind ↔ Action tables                                |

## Install

```sh
yay -S --needed niri xwayland-satellite noctalia-shell noctalia-qs \
	xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
	swaybg swaylock wlsunset cliphist fuzzel
```

## Config layout

| File                                                                              | What it holds                                                                                                           |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| [`home/dot_config/niri/config.kdl.tmpl`](../home/dot_config/niri/config.kdl.tmpl) | Main config (chezmoi template): `input`, `output`, `layout`, `binds`, `window-rule`s, `animations`, `spawn-at-startup`. |
| [`home/dot_config/niri/noctalia.kdl`](../home/dot_config/niri/noctalia.kdl)       | Noctalia theme colors, `include`d last so they win.                                                                     |
| [`home/dot_config/environment.d/*.conf`](../home/dot_config/environment.d/)       | Session env vars (`XDG_CURRENT_DESKTOP=niri`, Wayland session type, `PATH`, XDG user dirs).                             |

The main config is a **chezmoi template** so one file serves three machines
(office desktop, laptop, home desktop) — outputs, DPI, and startup apps branch on
the `machine` var. See [niri-config.md](niri-config.md) and
[ADR 0006](adr/0006-per-machine-niri-via-chezmoi-template.md).

niri uses the [KDL](https://kdl.dev/) document language, so it isn't touched by
dprint — validate it instead (see below).

## Autostart

`spawn-at-startup` launches the shell and daily apps everywhere: Noctalia
(`qs -c noctalia-shell`), Ghostty, Zen browser. Slack and Teams autostart **only
on the `work` machine** (see [niri-config.md](niri-config.md#startup)).

## X11 apps

`xwayland-satellite` runs rootless Xwayland so legacy X11 apps work under niri
without a full rootful X server.

## Everyday commands

```sh
niri validate                 # check the config before reloading
niri msg action <action>      # trigger actions (e.g. screenshot-window)
niri msg --json focused-output # query state as JSON
```

niri hot-reloads the **applied** `~/.config/niri/config.kdl` on save. Since the
repo source is a template, edit it then `chezmoi apply`; `just validate-niri`
renders the template and runs `niri validate` on the result.

## Screenshots & recording

The [`dot-screenshot`](../home/dot_local/bin/executable_dot-screenshot) script
wires niri + `grim`/`slurp` into [satty](screenshot.md) for annotation, and
[`dot-screenrec`](../home/dot_local/bin/executable_dot-screenrec) drives
[wl-screenrec](screen-recording.md) for GPU video capture. Keybinds live in the
`binds` block of the config — full table in
[niri-keybindings.md](niri-keybindings.md#screenshots--capture).

## References

- [niri wiki](https://github.com/niri-wm/niri/wiki)
- [niri configuration reference](https://github.com/niri-wm/niri/wiki/Configuration:-Introduction)
- [awesome-niri](https://github.com/niri-wm/awesome-niri)
- [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell)
