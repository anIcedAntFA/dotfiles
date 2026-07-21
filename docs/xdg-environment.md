# Environment variables & desktop portals

## Why

Three different mechanisms in this repo all shape "what an app sees when it
asks about the environment or the desktop" — a login-time env var file, a
systemd env var directory, and a D-Bus request broker. They look similar and
overlap in purpose, but apply at different moments to different sets of
processes. Mixing them up leads to "I set the var but the app doesn't see it"
confusion, so this doc keeps them straight.

| Layer                                       | Read by                              | When                                                | Scope                                                                                                                                |
| ------------------------------------------- | ------------------------------------ | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [`/etc/environment`](#etcenvironment)       | PAM (`pam_env`)                      | At login, before your session's process tree starts | Every login on the box — TTY, greetd/tuigreet, SSH — any PAM-based auth path                                                         |
| [`environment.d/*.conf`](#environmentd)     | `systemd --user` (via `pam_systemd`) | At systemd user-session startup                     | Anything spawned _through_ systemd-user or D-Bus — launchers, `.desktop` `Exec=`, dbus-activated services                            |
| [`xdg-desktop-portal`](#xdg-desktop-portal) | The portal daemon (D-Bus service)    | On-demand, per portal call                          | Not env vars — a broker for things Wayland apps can't do directly (screenshot, screen share, reading the system theme, file pickers) |

## `/etc/environment`

**Not chezmoi-managed** — this is a system file (see [`etc/environment`](../etc/environment)),
applied by hand (`sudo cp etc/environment /etc/environment`), same as
[greetd's config](greetd.md). Plain `KEY=VAL` lines, parsed once by PAM at
login and inherited the traditional Unix way by every child of your login
session. It's the only layer of the three that also covers plain TTY logins
and SSH — no desktop or systemd session required.

```sh
#QT_QPA_PLATFORMTHEME=qt5ct     # commented out — Qt apps would theme via qt5ct
#QT_STYLE_OVERRIDE=kvantum      # commented out — force Qt apps onto the Kvantum theme engine
BROWSER=firefox                 # generic fallback some CLI tools/scripts use to open a URL
EDITOR=nano                     # default $EDITOR for git commit -e, crontab -e, etc.
```

The `QT_*` lines are commented out on purpose — uncomment them if a Qt app
(e.g. JetBrains Toolbox) ever needs explicit theming. `EDITOR`/`BROWSER` are
not overridden anywhere in the fish config, so `nano`/`firefox` are what
actually fires when a CLI tool asks for your editor or browser.

## `environment.d`

[systemd's environment mechanism](https://www.freedesktop.org/software/systemd/man/latest/environment.d.html)
(`man environment.d`) — every `*.conf` under
[`home/dot_config/environment.d/`](../home/dot_config/environment.d/) is read
by `systemd --user` at session start and held as the user manager's merged
environment. This matters separately from `/etc/environment` because a lot of
desktop-launched apps (via `.desktop` files, portal-spawned helpers,
dbus-activated services) never go through fish — they'd never see a var only
set in `config.fish`, but they do see anything here.

| File                                                            | Sets                                                   | Why                                                                                                                                                                                                |
| --------------------------------------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`path.conf`](../home/dot_config/environment.d/path.conf)       | `PATH=%h/.local/bin:...`                               | `%h` is a systemd specifier for `$HOME`. Without this, anything launched outside your interactive shell (e.g. a `.desktop` entry) wouldn't see `~/.local/bin` (where `claude` lives).              |
| [`xdg.conf`](../home/dot_config/environment.d/xdg.conf)         | `XDG_DESKTOP_DIR`, `XDG_DOWNLOAD_DIR`, etc.            | The env-var form of the same info in [`user-dirs.dirs`](../home/dot_config/user-dirs.dirs) — some apps read the env var directly instead of parsing that file, so this keeps both answers in sync. |
| [`wayland.conf`](../home/dot_config/environment.d/wayland.conf) | `XDG_CURRENT_DESKTOP=niri`, `XDG_SESSION_TYPE=wayland` | Tells apps/portals this is a niri session running on Wayland — affects GTK's `GDK_BACKEND` auto-detection and Electron apps' rendering path.                                                       |
| [`fcitx5.conf`](../home/dot_config/environment.d/fcitx5.conf)   | `GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS`          | Routes text input through fcitx for X11/XWayland apps. Native Wayland apps don't need this — they use the `text-input` protocol directly. See [fcitx5.md](fcitx5.md).                              |

`XDG_CURRENT_DESKTOP`/`XDG_SESSION_TYPE` are set **again**, redundantly, in
niri's own `environment { }` block in
[`config.kdl.tmpl`](../home/dot_config/niri/config.kdl.tmpl) — that one only
scopes to processes niri itself spawns via `spawn-at-startup`, while
`wayland.conf` here covers the broader systemd-user/D-Bus-activated set. Both
agree, so the overlap is harmless; a `niri.conf` file that duplicated just
`XDG_CURRENT_DESKTOP` a _third_ time was removed as pure redundancy.

## `xdg-desktop-portal`

Not an env var file — [`xdg-desktop-portal`](https://github.com/flatpak/xdg-desktop-portal)
is a D-Bus service that brokers requests apps can't fulfill themselves under
Wayland's security model (no app can screenshot another app's window
directly). Screenshots, screen recording, file pickers, and **reading system
appearance settings** (dark/light mode, accent color) all go through it.

The daemon itself only routes — the actual work is done by **backend**
implementations (`xdg-desktop-portal-wlr`, `-gtk`, `-gnome`, `-kde`, all
installed per [packages.md](packages.md)), and
[`portals.conf`](../home/dot_config/xdg-desktop-portal/portals.conf)'s
`[preferred]` block says which backend handles which interface:

```ini
[preferred]
default=wlr                                      # fallback for any interface not listed below
org.freedesktop.impl.portal.Screenshot=wlr        # screenshots -> wlr backend
org.freedesktop.impl.portal.ScreenCast=wlr        # screen recording/sharing -> wlr backend
org.freedesktop.impl.portal.Settings=gtk          # dark/light mode, accent color, etc. -> gtk backend
```

- **`default=wlr`** — `xdg-desktop-portal-wlr` is purpose-built for
  wlroots-family compositors (niri included) and correctly implements
  Screenshot/ScreenCast via the wlr-screencopy protocol. It implements almost
  nothing else — notably no Settings, and likely no FileChooser either (that's
  traditionally missing from the wlr backend too, though untested here — if
  "Open file" dialogs ever look wrong in some app, this is the same root
  cause as the theme bug, just a different unassigned interface).
- **`Settings=gtk`** — `xdg-desktop-portal-gtk` implements the Settings
  interface by reading `gsettings` (`org.gnome.desktop.interface
  color-scheme`). This is the mechanism that lets portal-aware apps (Ghostty,
  Chrome) ask "am I in dark mode" without a GNOME session running. Before this
  line existed, `default=wlr` silently starved that query — confirmed with:

  ```sh
  busctl --user call org.freedesktop.portal.Desktop \
    /org/freedesktop/portal/desktop org.freedesktop.portal.Settings Read ss \
    "org.freedesktop.appearance" "color-scheme"
  # -> Call failed: Requested setting not found   (before the fix)
  ```

## Troubleshooting

```sh
# What systemd-user actually exported for this session:
systemctl --user show-environment

# What a specific portal interface resolves to right now:
busctl --user call org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop org.freedesktop.portal.Settings Read ss \
  "org.freedesktop.appearance" "color-scheme"

# Which portal backend processes are actually running:
pgrep -fa xdg-desktop-portal
```

## References

- [environment.d(5)](https://www.freedesktop.org/software/systemd/man/latest/environment.d.html)
- [pam_env(8)](https://man.archlinux.org/man/pam_env.8)
- [xdg-desktop-portal](https://github.com/flatpak/xdg-desktop-portal)
- [XDG Desktop Portal docs](https://flatpak.github.io/xdg-desktop-portal/docs/)
