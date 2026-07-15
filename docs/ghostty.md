# Ghostty terminal

## Why

[Ghostty](https://ghostty.org/) is a fast, GPU-accelerated terminal with native
platform integration and modern features (ligatures, shaders, good Wayland
support). It's the primary terminal here; [Alacritty](https://github.com/alacritty/alacritty)
is kept as a fallback.

## Install

```sh
yay -S --needed ghostty
```

The cursor shaders are **vendored** in this repo (see below), so there's no separate
shader package to install — chezmoi lays them down with the rest of the config.

## Config highlights

From [`home/dot_config/ghostty/config`](../home/dot_config/ghostty/config):

| Setting                                     | Why                                                                          |
| ------------------------------------------- | ---------------------------------------------------------------------------- |
| `theme = noctalia`                          | Tracks the desktop mode — Latte (light) / Dracula (dark).                    |
| `background-opacity = 1`                    | Opaque; depth comes from a `background-image`, not transparency (see below). |
| `mouse-hide-while-typing = true`            | Hides the pointer the moment you type.                                       |
| `notify-on-command-finish = unfocused`      | Desktop notification when a long command finishes off-focus.                 |
| `copy-on-select = clipboard`                | Auto-copy the selection; rich (html) copy is automatic since 1.3.0.          |
| `shell-integration = fish`                  | Enables prompt marks, cwd tracking, etc. for [fish](fish.md).                |
| `window-decoration = none`                  | No CSD — niri manages window framing.                                        |
| `window-save-state = always`                | Reopens last tabs/splits/cwd (not running programs).                         |
| `custom-shader = shaders/cursor_sweep.glsl` | Animated cursor (vendored `shaders/` — see below).                           |

## Keybinds

The keybind model is split across three consumers with **disjoint modifier
spaces** so nothing intercepts anything else — see
[ADR 0008](adr/0008-terminal-workspace-model.md):

- **niri** owns `Super+*` (the compositor grabs these first).
- **Ghostty** owns `Alt+*` (direct) and `Ctrl+Space` (leader).
- **[zellij](zellij.md)** owns its `Ctrl`-modal keys, passed straight through.

`Alt` is "Ghostty's Super": it reuses the `hjkl` muscle memory built for niri.
`Super` is unusable for Ghostty — niri would eat `Super+hjkl` before Ghostty saw
it. `Ctrl+<letter>` is avoided because Ghostty consumes keys before the shell,
and `Ctrl+A/E/W/L` are fish line-editing.

| Key                           | Action                                                     |
| ----------------------------- | ---------------------------------------------------------- |
| `Alt+h/j/k/l`                 | Focus the pane left/down/up/right.                         |
| `Alt+Shift+h/j/k/l`           | Resize the focused pane.                                   |
| `Alt+Enter`                   | Split right (pane beside) — `Alt+Shift+Enter` splits down. |
| `Alt+z`                       | Zoom the focused pane (toggle).                            |
| `Alt+t`                       | New tab.                                                   |
| `Alt+w`                       | Close pane (last pane closes the tab).                     |
| `Alt+Shift+w`                 | Close the whole tab.                                       |
| `Alt+1…9`                     | Jump to tab N.                                             |
| `Alt+o`                       | Tab overview (zoomed-out grid of all tabs).                |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Cycle to next / previous tab.                              |
| `Alt+r`                       | Rename the tab (also `Ctrl+Space > r`).                    |
| `Alt+Shift+F`                 | Search the scrollback (`Ctrl+Shift+F` also works).         |
| `Ctrl+Space > e`              | Equalize splits.                                           |
| `Ctrl+Space > n`              | New window.                                                |
| `Ctrl+Space > , / .`          | Move the tab left / right.                                 |
| `Ctrl+Space > b`              | Scroll to bottom.                                          |
| `Ctrl+Space > x`              | Reload the config.                                         |

> **Shadowing note:** Ghostty consumes these before the terminal app, so `Alt+h`
> and `Alt+l` shadow fish's man-page / list-dir bindings. Everything else avoids
> fish's defaults.

## Background & transparency

`background-opacity` **works fine on niri** — the earlier guesses (a niri conflict,
or a light-theme blend bug) were both wrong. The real reason a see-through window
seems to do nothing here: Noctalia runs with the **wallpaper disabled**, so the
desktop is a solid colour. Under tiling, only that flat colour sits behind a
terminal, so transparency merely tints the window — there's nothing with depth to
reveal. (`background-blur` is also a no-op on niri; it needs the KDE/KWin blur
protocol.)

So depth comes from a **`background-image`** instead — an image drawn behind the
text, independent of the desktop. To keep this public repo free of a chosen
wallpaper, it's wired through an **optional, untracked local file** (the same idea
as `local.fish`). The committed config ends with:

```ini
config-file = ?ghostty-local.conf
```

The `?` makes it optional — no error if the file is absent. To use it, create the
machine-local file and drop an image next to it:

```ini
# ~/.config/ghostty/ghostty-local.conf   (untracked, per machine)
background-image = ~/.config/ghostty/backgrounds/bg.jpg
background-image-fit = cover           # contain | cover | stretch | none
background-image-position = center
background-image-opacity = 0.12        # keep low so text stays legible
```

After editing, **fully restart** Ghostty (`Ctrl+Space > x` reloads most things, but
background/opacity changes are surest after a real restart).

## Sessions & project layouts

Ghostty has no native sessions and can't open a multi-pane, multi-command layout
at startup. That job is delegated to **[zellij](zellij.md)** (optional): project =
session, repo = tab, panes = editor / script / logs. Ghostty's own tabs and splits
stay fully usable on their own for ad-hoc terminals.

## Cursor shader

[`shaders/cursor_sweep.glsl`](../home/dot_config/ghostty/shaders/cursor_sweep.glsl)
is the single vendored cursor effect, loaded via `custom-shader`. It's GLSL, so
it's excluded from formatting/linting.

**Vendored, not cloned — and deliberately not a git submodule or `.chezmoiexternal`.**
The one shader in use is committed here rather than pulled at install time. For a
single settled effect that keeps the setup self-contained and offline, with no
upstream coupling or network dependency on `chezmoi apply`; a submodule would also
fight chezmoi's source model (nested `.git`, naming attributes). It's **MIT**, from
[`sahaj-b/ghostty-cursor-shaders`](https://github.com/sahaj-b/ghostty-cursor-shaders);
[`NOTICE`](../home/dot_config/ghostty/shaders/NOTICE) carries the attribution — keep
it. To update, copy the upstream `cursor_sweep.glsl` over this one and re-check the
license.

## Themes

Custom themes live in [`themes/`](../home/dot_config/ghostty/themes/). `theme =
noctalia` points at the `noctalia` file, which Noctalia rewrites to match the
active desktop mode (Latte in light, Dracula in dark); fish's `auto-sync-theme`
keeps it live. Set `theme = <name>` to pin one instead.

## References

- [Ghostty documentation](https://ghostty.org/docs)
- [Config reference](https://ghostty.org/docs/config/reference)
- [Release notes](https://ghostty.org/docs/install/release-notes)
