# Ghostty terminal

## Why

[Ghostty](https://ghostty.org/) is a fast, GPU-accelerated terminal with native
platform integration and modern features (ligatures, shaders, good Wayland
support). It's the primary terminal here; [Alacritty](https://github.com/alacritty/alacritty)
is kept as a fallback.

## Install

```sh
yay -S --needed ghostty ghostty-cursor-shaders
```

## Config highlights

From [`home/dot_config/ghostty/config`](../home/dot_config/ghostty/config):

| Setting                                     | Why                                                           |
| ------------------------------------------- | ------------------------------------------------------------- |
| `theme = noctalia`                          | Matches the desktop's Noctalia color scheme.                  |
| `font-family = JetBrainsMono Nerd Font`     | Nerd Font for icons/glyphs in prompts and TUIs.               |
| `shell-integration = fish`                  | Enables prompt marks, cwd tracking, etc. for [fish](fish.md). |
| `window-decoration = none`                  | No CSD — niri manages window framing.                         |
| `custom-shader = shaders/cursor_sweep.glsl` | Animated cursor (from `ghostty-cursor-shaders`).              |
| `window-padding-x/y = 8`                    | Breathing room around the grid.                               |

## Cursor shaders

The [`shaders/`](../home/dot_config/ghostty/shaders/) folder holds several cursor
effects (`cursor_sweep`, `cursor_tail`, `ripple_cursor`, `sonic_boom_cursor`…).
Swap the effect by pointing `custom-shader` at a different `.glsl` file. These
are GLSL, so they're excluded from formatting/linting.

## Themes

Custom themes live in [`themes/`](../home/dot_config/ghostty/themes/) (e.g.
`noctalia`, `catppuccin-latte`). Set `theme = <name>` to switch.

## References

- [Ghostty documentation](https://ghostty.org/docs)
- [Config reference](https://ghostty.org/docs/config/reference)
