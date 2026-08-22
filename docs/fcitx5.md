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

fcitx5 is reachable two ways, and the trick is to not let them overlap. Native
**Wayland** apps talk to fcitx5 over the compositor's `text-input` protocol (niri
speaks text-input-v3); **X11 / XWayland** apps use the legacy IM-module env vars.
[`environment.d/fcitx5.conf`](../home/dot_config/environment.d/fcitx5.conf) sets
only the two that native Wayland can't cover:

```ini
QT_IM_MODULE=fcitx      # Qt5 still defaults to XWayland
XMODIFIERS=@im=fcitx    # the XIM path for all X11 / XWayland apps
```

> [!IMPORTANT]
> `GTK_IM_MODULE` is deliberately **unset**. With niri's text-input frontend
> running, GTK3/GTK4 Wayland apps use their built-in `wayland` im module on their
> own; also setting `GTK_IM_MODULE=fcitx` routes GTK input through _both_ paths,
> which fcitx surfaces as its **"Wayland Diagnose"** pop-up
> (_"unset GTK_IM_MODULE and use the Wayland input method frontend instead"_).
> Leaving it unset silences that warning and is fcitx's recommended Wayland setup.

**Electron / Chromium apps are a third case, and it's Electron-version-dependent.**
Older Electron didn't use `text-input` even on Wayland — it needed
`--enable-wayland-ime`, or it got no input method at all (there's no XIM fallback
once off X11). Newer Electron enables Wayland IME by default: VS Code 1.131 /
Electron 42 reaches fcitx5 over `text-input` with no flag (`fcitx5-diagnose` shows a
`program:code frontend:wayland_v2` context without it), so its
[`code-flags.conf`](../home/dot_config/code-flags.conf) leaves the flag commented.
Apps bundling older Electron — Slack, Teams, Discord — keep `--enable-wayland-ime`
in their `.desktop` overrides in
[`dot_local/share/applications/`](../home/dot_local/share/applications/); Chrome
carries it there too. See [vscode.md](vscode.md) and
[xdg-environment.md](xdg-environment.md).

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
