# Screenshots — grim · slurp · satty

## Why

Wayland has no built-in screenshot UI, so capture is a small pipeline: a
**grabber** pulls pixels, an **annotator** opens them for markup, then the
result is copied and saved. Here that's `grim` + `slurp` (grab) →
[satty](https://github.com/gabm/Satty) (annotate) — a fast, Flameshot-style
tool for arrows, boxes, blur, and text.

For _video_ capture, see [screen-recording.md](screen-recording.md); the two
guides are parallel.

## Install

```sh
yay -S --needed satty grim slurp wl-clipboard jq
```

> [!IMPORTANT]
> `grim`, `slurp`, and `wl-clipboard` are **required** by the script below
> (grab region, select area, clipboard). Install them alongside satty.

## The `dot-screenshot` script

[`home/dot_local/bin/executable_dot-screenshot`](../home/dot_local/bin/executable_dot-screenshot)
ties it together. It takes a mode and pipes the capture into satty:

```sh
dot-screenshot region          # select a region (default)
dot-screenshot window          # the focused niri window
dot-screenshot monitor-focused # the focused output
dot-screenshot monitor-all     # everything
```

Each capture is piped to `satty` and saved to `$XDG_PICTURES_DIR/screenshot-*.png`.
The binds live in niri's `binds` block — see
[niri-keybindings.md](niri-keybindings.md#screenshots--capture) (the `Mod+S`
family).

> [!NOTE]
> The source file carries chezmoi's `executable_` prefix so `chezmoi apply`
> writes it `0755`. Without it the file lands non-executable and niri's
> `spawn "dot-screenshot"` silently fails.

## satty config

From [`home/dot_config/satty/config.toml`](../home/dot_config/satty/config.toml):

- `early-exit = true` — close immediately after copy/save.
- `copy-command = "wl-copy"` — keep the result on the Wayland clipboard.
- `initial-tool = "brush"` — start ready to draw.

## References

- [satty README](https://github.com/gabm/Satty)
- [grim](https://sr.ht/~emersion/grim/) · [slurp](https://github.com/emersion/slurp)
