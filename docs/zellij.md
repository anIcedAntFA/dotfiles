# zellij — terminal multiplexer

## Why

[Ghostty](ghostty.md) has fast native tabs and splits but **no sessions**: it
can't declare "open these repos, each with an editor, a `btop`, and a log tail"
and restore that later. [zellij](https://zellij.dev/) supplies exactly that — and
it's **optional**: Ghostty stays fully usable without it.

The division of labour ([ADR 0008](adr/0008-terminal-workspace-model.md)):

```text
Ghostty window
└─ zellij session "project-x"      ← one session per PROJECT
   ├─ tab: app    │ editor │ btop / logs
   ├─ tab: api    │ editor │ dev server
   └─ tab: infra  │ k9s    │ logs
```

Project = session, repo = tab, panes = editor / script / log. Ghostty's own tabs
are then just for ad-hoc terminals.

## Install

```sh
yay -S --needed zellij
```

Config: [`home/dot_config/zellij/config.kdl`](../home/dot_config/zellij/config.kdl).
Layouts: [`home/dot_config/zellij/layouts/`](../home/dot_config/zellij/layouts/).

## Keybinds — and why they don't fight Ghostty

zellij keeps its **default `Ctrl`-modal keys**. Ghostty binds only `Alt+*` and
`Ctrl+Space`, and passes the `Ctrl`-modal keys straight through — so the two never
collide. The status bar at the bottom always shows the current mode's keys.

| Enter mode | Then                                                                                 |
| ---------- | ------------------------------------------------------------------------------------ |
| `Ctrl+p`   | Pane: `n` new, `h/j/k/l` focus, `x` close, `f` fullscreen, `z` frames, `w` floating. |
| `Ctrl+t`   | Tab: `n` new, `h/l` or `1…9` switch, `x` close, `r` rename.                          |
| `Ctrl+n`   | Resize: `h/j/k/l` or `+`/`-`.                                                        |
| `Ctrl+s`   | Scroll / search the scrollback.                                                      |
| `Ctrl+o`   | Session: `d` detach, `w` the session manager.                                        |
| `Ctrl+g`   | Lock (ignore all zellij keys — pass to the app).                                     |

> **Inside zellij, drive panes with `Ctrl`-modal, not `Alt`.** Ghostty intercepts
> `Alt+hjkl` before zellij ever sees it, so `Alt` is inert here by design.

## Project layouts

A [layout](https://zellij.dev/documentation/creating-a-layout) is a KDL file (same
language as the niri config) declaring a session's tabs, panes, cwds, and the
commands to run. Start from the template:

```sh
cd ~/.config/zellij/layouts
cp _template.kdl myproject.kdl   # then edit repo paths + commands
```

`_`-prefixed layouts are hidden from the `zj` picker, so `_template.kdl` won't
show up there. A pane runs a command with `pane command="btop"`; a plain `pane`
is just a shell.

## The `zj` picker

[`functions/zj.fish`](../home/dot_config/fish/functions/zj.fish) is an `fzf` menu
over **running sessions** (resume) and **available layouts** (fresh start). It fits
the "many projects" case — you pick one when you need it rather than hardcoding a
default at startup.

```text
zj
  resume  project-x        ← attach to a running session
  open    myproject        ← start a new session from a layout
```

An "open" pick names the session after the layout and resumes it if it's already
running, so re-running `zj` on the same project reattaches instead of duplicating.

## Persistence

`session_serialization` is on, so a project **survives closing the terminal**.
Detach with `Ctrl+o d` (or just close Ghostty) and later `zj → resume`, or
`zellij attach <name>`. List sessions with `zellij list-sessions`.

## Theme

`config.kdl` sets `theme_dark "dracula"` / `theme_light "catppuccin-latte"` to
track the desktop mode like Ghostty does, falling back to `theme "dracula"` if the
terminal doesn't report its color scheme.

## References

- [zellij documentation](https://zellij.dev/documentation/)
- [Creating a layout](https://zellij.dev/documentation/creating-a-layout)
- [Configuration options](https://zellij.dev/documentation/options)
