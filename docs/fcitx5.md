# fcitx5 — Vietnamese input

## Why

[fcitx5](https://github.com/fcitx/fcitx5) is a cross-platform input-method
framework. With the **Bamboo** engine it provides Vietnamese typing (Telex/VNI)
system-wide, switchable with a hotkey.

## Install

```sh
yay -S --needed fcitx5 fcitx5-bamboo fcitx5-configtool
```

## Configure the environment

Wayland-native apps talk to fcitx5 over the `text-input` protocol automatically.
For **X11 / XWayland** apps you still need these env vars, set in
[`environment.d/fcitx5.conf`](../home/dot_config/environment.d/fcitx5.conf):

```ini
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
```

The daemon autostarts under niri via `spawn-at-startup "fcitx5"` in
[`config.kdl`](../home/dot_config/niri/config.kdl.tmpl) — machine-agnostic,
so it runs on every profile.

## What's configured

- [`profile`](../home/dot_config/fcitx5/profile) — default group uses the `us`
  keyboard layout with **bamboo** as the default input method.
- [`conf/`](../home/dot_config/fcitx5/conf/) — per-addon settings (`bamboo.conf`,
  `notifications.conf`, `unikey.conf`).

Switch input methods with `Ctrl+Space` (default). Fine-tune everything with the
GUI:

```sh
fcitx5-configtool
```

## References

- [fcitx5 on Arch Wiki](https://wiki.archlinux.org/title/Fcitx5)
- [fcitx5-bamboo](https://github.com/fcitx/fcitx5-bamboo)
