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
| `theme = light:latte,dark:dracula`          | Follows the desktop mode live — Latte (light) / Dracula (dark).              |
| `background-opacity = 1`                    | Opaque; depth comes from a `background-image`, not transparency (see below). |
| `mouse-hide-while-typing = true`            | Hides the pointer the moment you type.                                       |
| `focus-follows-mouse = true`                | Hover a pane to focus it — for when reaching for the keyboard isn't handy.   |
| `link-previews = osc8`                      | Preview only OSC 8 links, where the text can lie about the destination.      |
| `notify-on-command-finish = unfocused`      | Desktop notification when a long command finishes off-focus.                 |
| `copy-on-select = clipboard`                | Auto-copy the selection; rich (html) copy is automatic since 1.3.0.          |
| `shell-integration = fish`                  | Enables prompt marks, cwd tracking, etc. for [fish](fish.md).                |
| `window-decoration = none`                  | No CSD — niri manages window framing.                                        |
| `window-save-state = always`                | Reopens last tabs/splits/cwd (not running programs).                         |
| `custom-shader = shaders/cursor_sweep.glsl` | Animated cursor (vendored `shaders/` — see below).                           |

## Keybinds

The keybind model gives each of three consumers **its own modifier** so nothing
intercepts anything else — see [ADR 0008](adr/0008-terminal-workspace-model.md):

- **niri** owns `Super+*` (the compositor grabs these first).
- **Ghostty** owns `Alt+*`, leader included.
- **[zellij](zellij.md)** owns its `Ctrl`-modal keys, passed straight through.

`Alt` is "Ghostty's Super": it reuses the `hjkl` muscle memory built for niri.
`Super` is unusable for Ghostty — niri would eat `Super+hjkl` before Ghostty saw
it. `Ctrl+<letter>` is avoided because Ghostty consumes keys before the shell,
and `Ctrl+A/E/W/L` are fish line-editing. The one exception to the rule is
`Ctrl+Tab` (cycle tabs) — zellij's defaults are `Ctrl`+letter, so nothing clashes.

Two bits of `keybind` syntax are easy to mix up:

- `+` joins keys pressed **together**: `alt+shift+h` is one chord.
- `>` makes a **sequence**: `alt+space>e` means press `Alt+Space`, let go, then
  press `e`. Ghostty waits **indefinitely** for that second key — there is no
  timeout — so the leader never reaches the program underneath. That's why the
  leader is `Alt+Space` and not `Ctrl+Space`, which editors bind for completion.
  Press an unbound key mid-sequence and the whole sequence is forwarded to the
  program as if no keybind existed.

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
| `Alt+r`                       | Rename the tab.                                            |
| `Alt+Space > r`               | Enter the resize key table (below).                        |
| `Alt+Shift+F`                 | Search the scrollback (`Ctrl+Shift+F` also works).         |
| `Alt+Space > e`               | Equalize splits.                                           |
| `Alt+Space > n`               | New window.                                                |
| `Alt+Space > , / .`           | Move the tab left / right.                                 |
| `Alt+Space > b`               | Scroll to bottom.                                          |
| `Alt+Space > x`               | Reload the config.                                         |

> **Shadowing note:** Ghostty consumes these before the terminal app, so `Alt+h`
> and `Alt+l` shadow fish's man-page / list-dir bindings. Everything else avoids
> fish's defaults.

### The resize key table

`Alt+Shift+h/j/k/l` moves a pane edge by 60px. That's ~2.3% of a 2560px monitor —
right for a nudge, tedious for a real drag (nine presses to shift 20%). So the
same four moves also live in a **key table**, where the modifier is dropped and
you can just hammer `hjkl`:

```ini
keybind = alt+space>r=activate_key_table:resize
keybind = resize/h=resize_split:left,60
keybind = resize/escape=deactivate_key_table
keybind = resize/catch_all=deactivate_key_table
```

A key table is a **third** kind of "mode" in this window, and [CONTEXT.md](../CONTEXT.md)
keeps the three apart. The distinction that matters: the leader (`Alt+Space > e`)
takes one key and ends itself, whereas a key table **stays active** until you
dismiss it — and **Ghostty draws no indicator for it**. There is no status bar, no
cursor change, nothing; the only cue is what your keys do. That's the whole risk.

`resize/catch_all` is what makes it safe. Any key that isn't `hjkl` or `Escape`
drops the table, so you can't get stranded in an invisible mode. Type `ls` having
forgotten you're still in it and the worst case is one stray 2.3% nudge —
`Alt+Space > e` puts it back. Lookup also proceeds from the innermost table
outward, so the normal `Alt+*` binds keep working inside it.

> zellij has its own resize mode (`Ctrl+n`) **with** a status bar indicator. When
> zellij is running, prefer it. This table exists because Ghostty must stand on its
> own without a multiplexer (ADR 0008), and that case still needs a way to resize.

### Considered and skipped

Recorded so they don't get re-litigated:

- **`working-directory`** — leave it at the default (`inherit`). `Alt+T` goes
  through niri, which spawns into the already-running Ghostty process, so
  `window-inherit-working-directory` wins and this setting is never consulted.
  It only applies to a fresh process — i.e. `ghostty` typed at a shell, where
  `inherit` opening in that shell's cwd is exactly what you want. Pinning it to a
  path would sacrifice that to change nothing else. Jumping to a project is
  [zoxide](fish.md)'s job.
- **`link`** — would let us match our own regexes (issue IDs, stack-trace paths)
  and act on them. The man page ends its entry with "TODO: This can't currently be
  set!" as of 1.3.1. Recheck on a future release.
- **Chained actions** (`chain=`) — no use for them here. The one candidate was a
  sized split (`new_split` is always 50/50, so `new_split:down` + `chain=resize_split`
  fakes a log drawer), but `resize_split` counts **pixels**, and one of the two
  2560×1440 monitors is rotated — any constant is wrong on one of them. Sized,
  declarative layouts belong to zellij anyway.

## Background & transparency

`background-opacity` **works fine on niri** — the earlier guesses (a niri conflict,
or a light-theme blend bug) were both wrong. The real reason a see-through window
seems to do nothing here: Noctalia runs with the **wallpaper disabled**, so the
desktop is a solid colour. Under tiling, only that flat colour sits behind a
terminal, so transparency merely tints the window — there's nothing with depth to
reveal. (`background-blur` is also a no-op on niri; it needs the KDE/KWin blur
protocol.)

So depth comes from a **`background-image`** instead — an image drawn behind the
text, independent of the desktop. The images are tracked
([`backgrounds/`](../home/dot_config/ghostty/backgrounds/)) and land with everything
else on `chezmoi apply`; there's no hand-setup step.

**The image follows light/dark mode via the theme files.** `background-image` has no
`light:/dark:` syntax of its own — only `theme` does. But a theme file is just an
ordinary config file (it may set anything except `theme` and `config-file`), so each
of `themes/latte` and `themes/dracula` carries its own image alongside its palette:

```ini
# themes/dracula (tail) — themes/latte is the same with light.jpg
background-image = ~/.config/ghostty/backgrounds/dark.jpg
background-image-fit = cover           # contain | cover | stretch | none
background-image-position = center
background-image-opacity = 0.1         # keep low so text stays legible
```

`theme = light:latte,dark:dracula` then swaps palette **and** image together when
the desktop mode changes.

Two limitations worth knowing, both from Ghostty's own docs:

- **The image is per-terminal, not per-window** — with splits, each pane draws its
  own copy of the whole image rather than showing its slice of one shared image.
  There's no config for this; upstream says a future release will fix it.
- **Each terminal duplicates the image in VRAM.** Hence the tracked copies are
  downscaled to 2560×1440 (the monitor size — a pane is never larger) instead of the
  5120×2880 originals in `images/wallpaper/`.

After changing any of this, **fully restart** Ghostty (`Alt+Space > x` reloads most
things, but background/opacity changes are surest after a real restart).

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

Two tracked themes live in [`themes/`](../home/dot_config/ghostty/themes/):
`latte` (light) and `dracula` (dark). `theme = light:latte,dark:dracula` makes
Ghostty watch the desktop light/dark setting and switch between them at runtime.
Set `theme = latte` to pin one instead. Each file holds a palette plus its
background image (see above).

**Noctalia's ghostty theming is deliberately off** — `settings.json` has
`id: ghostty` → `enabled: false`. It used to rewrite a single `themes/noctalia`
file per mode, which had two problems: Ghostty doesn't watch config files, so the
colours only changed on a manual reload; and the file showed perpetually dirty in
`chezmoi status`. Two static files driven by `light:/dark:` fix both, and are what
lets the background image follow the mode at all. The trade-off: changing Noctalia's
accent colour no longer reaches Ghostty — edit these files by hand instead. (fish
has its own `auto-sync-theme`; that is unrelated and still live.)

## References

- [Ghostty documentation](https://ghostty.org/docs)
- [Config reference](https://ghostty.org/docs/config/reference)
- [Release notes](https://ghostty.org/docs/install/release-notes)
