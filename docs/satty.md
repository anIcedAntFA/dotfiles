# Satty — screenshot annotation

## Why

[Satty](https://github.com/gabm/Satty) is a fast screenshot **annotation** tool
(arrows, boxes, blur, text) inspired by Swappy/Flameshot. Here it's the final
step of a Wayland screenshot pipeline: a grabber captures pixels, Satty opens
them for markup, then copies/saves the result.

## Install

```sh
yay -S --needed satty grim slurp wl-clipboard jq
```

> [!IMPORTANT]
> `grim`, `slurp`, and `wl-clipboard` are **required** by the screenshot script
> below (grab region, select area, clipboard). Install them alongside Satty.

## The `dot-screenshot` script

[`home/dot_local/bin/dot-screenshot`](../home/dot_local/bin/dot-screenshot) ties
it together. It takes a mode and pipes the capture into Satty:

```sh
dot-screenshot region          # select a region (default)
dot-screenshot window          # the focused niri window
dot-screenshot monitor-focused # the focused output
dot-screenshot monitor-all     # everything
```

Each capture is piped to `satty` and saved to `$XDG_PICTURES_DIR/screenshot-*.png`.
Bind these in niri's `binds` block (see [niri.md](niri.md)).

## Config

From [`home/dot_config/satty/config.toml`](../home/dot_config/satty/config.toml):

- `early-exit = true` — close immediately after copy/save.
- `copy-command = "wl-copy"` — keep the result on the Wayland clipboard.
- `initial-tool = "brush"` — start ready to draw.

## References

- [Satty README](https://github.com/gabm/Satty)
- [grim](https://sr.ht/~emersion/grim/) · [slurp](https://github.com/emersion/slurp)
