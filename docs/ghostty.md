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

| Setting                                     | Why                                                           |
| ------------------------------------------- | ------------------------------------------------------------- |
| `theme = noctalia`                          | Matches the desktop's Noctalia color scheme.                  |
| `font-family = JetBrainsMono Nerd Font`     | Nerd Font for icons/glyphs in prompts and TUIs.               |
| `shell-integration = fish`                  | Enables prompt marks, cwd tracking, etc. for [fish](fish.md). |
| `window-decoration = none`                  | No CSD — niri manages window framing.                         |
| `custom-shader = shaders/cursor_sweep.glsl` | Animated cursor (vendored `shaders/` — see below).            |
| `window-padding-x/y = 8`                    | Breathing room around the grid.                               |

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

Custom themes live in [`themes/`](../home/dot_config/ghostty/themes/) (e.g.
`noctalia`, `catppuccin-latte`). Set `theme = <name>` to switch.

## References

- [Ghostty documentation](https://ghostty.org/docs)
- [Config reference](https://ghostty.org/docs/config/reference)
