# Theme sync — darkman · gtk portal · per-app themes

Make every app follow one system **light/dark color-scheme** — switched both
**automatically** at sunrise/sunset and **manually** by a keybind — without each
app growing its own theme-switcher.

## The one idea

There is a single source of truth: the `org.gnome.desktop.interface color-scheme`
gsetting (`prefer-dark` / `prefer-light`). Everything else either **writes** it or
**reads** it.

```text
sunrise/sunset schedule ─┐
                         ├─► darkman ──► ~/.local/share/darkman/*   (hooks, $1 = dark|light)
Mod+Shift+D (toggle) ────┘   (writer/      │
                             scheduler)    ├─ set-color-scheme
                                           │     ├─ gsettings color-scheme  (the source of truth) ─┐
                                           │     ├─ noctalia msg theme-mode-set   (Noctalia + its   │
                                           │     │        templates: btop/qt/niri re-render)        │
                                           │     ├─ fish auto-sync-theme  (live, running shells)    │
                                           │     ├─ gsettings icon-theme  (Papirus-Dracula/-Latte)  │
                                           │     ├─ gsettings gtk-theme + accent-color (GTK live)   │
                                           │     └─ Zed buffer_font_weight        (200 / 400)       │
                                           └─ set-wallpaper (per machine) ─► per-output, per-mode   │
                                                                                                   ▼
                                                                             gtk XDG portal (Settings=gtk)
                                                                                                   │ broadcasts
                            ┌──────────────────┬─────────────────┬────────────────────────────────┴──┐
                            ▼                  ▼                 ▼                                     ▼
                      VS Code (autoDetect)  Ghostty / Zed   Chrome · Waterfox  Discord·Slack·Teams  fish auto-sync-theme
                      Dracula ↔ Github Lt.  (portal-aware)  (portal, 0 cfg)    (Electron: needs     Dracula ↔ Catppuccin Latte
                                                                                Wayland+Ozone)

     Noctalia's bar, Zed's font weight, and btop's theme are hook-driven, not portal-driven; everything
     to the right of the portal just reads the one gsetting. Noctalia *follows* here (it does not own the
     mode) — see docs/adr/0019.
```

[darkman](https://darkman.whynothugo.nl/) is the **writer and scheduler**; the gtk
portal is the **broadcaster**. See
[ADR 0010](adr/0010-darkman-behind-gtk-portal.md) for why darkman writes the
gsetting instead of being the Settings portal itself (short version: it keeps the
`Settings=gtk` routing and lets `fish`, which reads the dconf key directly, work
unchanged).

The **color-scheme** (the dark/light _mode_) and a **theme** (an app's actual
palette for that mode) are different things — see
[CONTEXT.md](../CONTEXT.md#appearance).

## The two triggers

| Trigger        | What runs                                                                                  | Notifies?   |
| -------------- | ------------------------------------------------------------------------------------------ | ----------- |
| Sunrise/sunset | `darkman` service, from `lat`/`lng` in the config                                          | no          |
| `Mod+Shift+D`  | [`dot-theme-toggle`](../home/dot_local/bin/executable_dot-theme-toggle) → `darkman toggle` | yes (toast) |

A manual toggle is an **override, not a lock**: it flips the mode now, and the
schedule reclaims control at the next sunrise/sunset. darkman has no "pause auto"
mode, and we deliberately didn't build one.

## Pieces in this repo

- [`home/dot_config/darkman/config.yaml.tmpl`](../home/dot_config/darkman/config.yaml.tmpl)
  — `lat`/`lng` (from the gitignored `chezmoi.toml`, a home location is private),
  `usegeoclue: false`, `portal: false`.
- [`home/dot_local/share/darkman/executable_set-color-scheme`](../home/dot_local/share/darkman/executable_set-color-scheme)
  — darkman's transition hook; `$1` is `dark`/`light`, it runs `gsettings set …
  color-scheme prefer-*`. Runs on **both** the schedule and manual toggles. It also:
  drives Noctalia with `noctalia msg theme-mode-set "$1"` (Noctalia _follows_
  darkman — [ADR 0019](adr/0019-darkman-owns-mode-noctalia-follows.md) — and its
  templates re-render btop/qt/niri from the MineScheme palette per mode);
  re-runs fish's `auto-sync-theme` so **running** shells re-theme live via universal
  vars; flips the Papirus icon variant (`icon-theme` → `Papirus-Dracula`/`Papirus-Latte`);
  flips `gtk-theme` (`adw-gtk3`/`adw-gtk3-dark`) + a named `accent-color`
  (`purple`/`teal`) so GTK/libadwaita apps self-follow live (no gtk template —
  see above and [ADR 0021](adr/0021-tiered-app-theming-minescheme-identity.md));
  swaps superfile's `theme` (`dracula`/`catppuccin-latte`); and `sed`-swaps Zed's
  `buffer_font_weight` (200 dark / 400 light —
  [ADR 0013](adr/0013-zed-per-theme-font-weight-via-darkman-hook.md)). btop is **no
  longer** swapped here — it's a Noctalia template again ([ADR 0021](adr/0021-tiered-app-theming-minescheme-identity.md)).
  **`WAYLAND_DISPLAY` guard:** darkman's service can start before niri exports
  `WAYLAND_DISPLAY`, and `noctalia msg` needs it to find its socket — so the hook
  pulls it from `systemctl --user show-environment` when its own env lacks it.
  Without this, scheduled toggles silently fail to move Noctalia while a hand-run
  one works ([ADR 0019](adr/0019-darkman-owns-mode-noctalia-follows.md)).
- [`home/dot_local/share/darkman/executable_set-wallpaper.tmpl`](../home/dot_local/share/darkman/executable_set-wallpaper.tmpl)
  — per-machine (`.tmpl`, branches on `.machine`). darkman runs _every_ executable
  in its hook dir, so this second hook sets a per-output, per-mode wallpaper via
  `noctalia msg wallpaper-set <connector> <path>` (home/work: DP-3 landscape +
  HDMI-A-1 portrait; laptop: eDP-1). The image dir is baked in by chezmoi (no more
  `jq`-ing the dead v4 `settings.json`). Adding a hook needs a `darkman` restart.
- [`home/dot_local/bin/executable_dot-theme-toggle`](../home/dot_local/bin/executable_dot-theme-toggle)
  — the `Mod+Shift+D` target: `darkman toggle` + a one-shot `notify-send`.
- [`home/dot_local/bin/executable_dot-theme-reconcile`](../home/dot_local/bin/executable_dot-theme-reconcile)
  — a niri `spawn-at-startup` that fixes the **boot** ordering race. `darkman.service`
  starts before Noctalia's IPC, so darkman's hook can't reach Noctalia at boot;
  Noctalia then asserts its persisted `[theme] mode` **once at startup** and writes
  the color-scheme gsetting to that (stale) value — the desktop boots in the wrong
  mode, and since darkman's _internal_ mode is already right, the first `Mod+Shift+D`
  is a no-op (two presses to flip). This waits for Noctalia's socket, then pushes
  `noctalia msg theme-mode-set "$(darkman get)"` until the gsetting agrees. Fixed-mode
  Noctalia doesn't re-assert, so the correction holds. **It then re-drives the
  wallpaper too**: the wallpaper is set _only_ via Noctalia IPC (no gsetting fallback
  like the mode has), so the same boot race leaves it on Noctalia's stale image —
  **dark mode under a light wallpaper**. After the mode loop converges (proof
  Noctalia's startup assertion is done) the reconcile re-runs `set-wallpaper
  "$(darkman get)"` once; a single post-startup `wallpaper-set` sticks. See
  [ADR 0019](adr/0019-darkman-owns-mode-noctalia-follows.md) and the **Wallpaper** term
  in [CONTEXT.md](../CONTEXT.md).
- `window.autoDetectColorScheme` + `workbench.preferred{Light,Dark}ColorTheme` in
  [VS Code settings](../home/dot_config/Code/User/settings.json) — native follow,
  no script.
- [`fish/functions/auto-sync-theme.fish`](../home/dot_config/fish/functions/auto-sync-theme.fish)
  — reads the same color-scheme key on shell start and picks the fish theme.
- `theme.mode: "system"` in [Zed settings](../home/dot_config/zed/settings.json)
  — native portal follow (Dracula ↔ Catppuccin Latte); its per-mode font weight
  rides the `set-color-scheme` hook above. See [zed.md](zed.md).
- **Portal-aware apps.** Modern Chromium/Electron/Firefox read
  `org.freedesktop.appearance` from the `Settings=gtk` portal, so Chrome and Waterfox
  follow the toggle with **no per-app setting** — the same mechanism as Ghostty;
  they just read the one gsetting the portal broadcasts. (This is why it feels
  "like gtk" — it is the gtk portal.)
  - **Electron caveat 1 — must run on Wayland/Ozone.** An Electron app only reads
    the appearance portal when it runs as a native Wayland client. On **XWayland**
    (the Electron default) it never sees the portal and its "sync with system"
    theme stays stuck. Ozone/Wayland is selected by
    `ELECTRON_OZONE_PLATFORM_HINT=auto` in
    [`environment.d/electron.conf`](../home/dot_config/environment.d/electron.conf)
    (session-wide, all Electron apps); the per-app
    `~/.local/share/applications/*.desktop` overrides only add
    `XDG_CURRENT_DESKTOP=GNOME` + `--enable-wayland-ime` (fcitx5 text-input). Verify
    with `pgrep -af slack` / `teams-for-linux` — you should see `--ozone-platform=wayland`.
  - **Electron caveat 2 — Slack & Teams also need an app-level opt-in.** Running on
    Wayland/Ozone is necessary but **not sufficient** for these two: unlike Discord
    (which follows the portal once on Ozone), Slack and Teams default to a fixed
    theme and must be told to follow the OS:
    - **Teams** (teams-for-linux): set `"followSystemTheme": true` in
      `~/.config/teams-for-linux/config.json` (the file/key doesn't exist by
      default — create it), then restart Teams.
    - **Slack**: in-app **Preferences → Themes → Sync with OS setting** (Slack has
      no config-file knob for this; it's a per-user in-app toggle).
    - Without these, the `.desktop` override alone leaves them stuck light even
      though the portal is broadcasting correctly.
- **GTK/libadwaita apps self-follow live — no Noctalia gtk template.** GTK4/
  libadwaita apps (Nautilus, ghostty's tab-bar) read `org.freedesktop.appearance
  color-scheme` from the portal and repaint light↔dark **live**; GTK3 apps follow
  the `gtk-theme` NAME. So the darkman hook just flips two interface gsettings —
  `gtk-theme` (`adw-gtk3`/`adw-gtk3-dark`) and a named `accent-color` (`purple`
  dark / `teal` light, the nearest names to the MineScheme identity) — and every
  open GTK app repaints with **no relaunch**.
  - **Why not a Noctalia gtk template?** It used to render `gtk-4.0/noctalia.css`
    (+ `gtk-3.0`) with `@define-color` overrides read **only at app launch**. On a
    live toggle libadwaita flipped its base but the stale override rode on top, so
    already-open Nautilus/ghostty **inverted** until relaunched. Dropping gtk3/gtk4
    from `[theme.templates]` (ADR 0021) traded the exact Dracula/Latte chrome
    colours for correct **live** switching via adw-gtk3 + libadwaita. The identity
    survives as the named accent (purple/teal) + Noctalia's own bar/niri/qt.

## Tiers: who themes what (ADR 0021)

Each app gets its theme by capability, not by one universal mechanism:

- **Own config** (self-follows the color-scheme; Noctalia template off): Ghostty,
  Zed, VS Code, fish; **GTK3/GTK4/libadwaita** apps (adw-gtk3 + the appearance
  portal — see above); and — via the **terminal's ANSI palette** (Dracula/Latte
  from Ghostty) — **bat** (`--theme=base16`) and **starship** (named ANSI colours,
  no palette in `starship.toml`). bat/starship follow the terminal, **not** fish.
- **Noctalia template** (can't self-switch → renders the MineScheme palette per
  mode): **btop**, qt, niri, zathura. Enabled via
  `[theme.templates].builtin_ids`/`community_ids` in `00-base.toml`. (gtk3/gtk4
  were **removed** — libadwaita self-follows live; see above and ADR 0021.)
- **darkman hook** (Tier C, only when a template can't): fish live-sync, Zed font
  weight, Papirus icon variant, superfile theme, and the GTK `gtk-theme` +
  `accent-color` gsettings.

### Icons — Papirus (Catppuccin Latte / Dracula folders)

Noctalia's `papirus-icons` template can't do a per-mode Catppuccin/Dracula split
(no `--theme`, stock colours only), so Papirus is driven from the darkman hook:

- One-time per machine (**no sudo**): [`dot-setup-papirus`](../home/dot_local/bin/executable_dot-setup-papirus)
  builds two **user-local thin icon themes** under `~/.local/share/icons`:
  - `Papirus-Latte` — `Inherits=Papirus-Light` + Catppuccin Latte **sapphire**
    folders (matching MineScheme light accent `#209fb5`), from
    [`catppuccin/papirus-folders`](https://github.com/catppuccin/papirus-folders).
  - `Papirus-Dracula` — `Inherits=Papirus-Dark` + Dracula **purple** folders
    (matching the dark accent `#bd93f9`), from
    [`dracula/papirus-folders`](https://github.com/dracula/papirus-folders).

  Each theme overrides only the Places folder icons and inherits everything else
  (light/dark panel + symbolic icons) from its stock parent. Copying colours into
  the stock `Papirus-Light`/`-Dark` fails — they **symlink** size dirs to base
  `Papirus`, so `cp -r` hits "cannot overwrite non-directory". Run it as your user,
  **not** with `sudo` (sudo would build the themes under `/root`).
- Per toggle: `set-color-scheme` flips `gsettings icon-theme` between
  `Papirus-Latte` and `Papirus-Dracula` — no `papirus-folders`, no sudo.

### File manager — superfile (Tier C)

superfile has no dark/light auto (one `theme =` in `config.toml`), so the hook
rewrites that line in place per mode: `catppuccin-latte` (light) / `dracula`
(dark). A running superfile reads its config only at launch, so the new theme
lands on the next launch. The tracked `config.toml` carries the light baseline.
(superfile replaced yazi, which is gone from the repo.)

### Night light (Noctalia, independent of mode)

Noctalia's night-light (blue-light / colour-temperature filter) is **separate**
from the dark/light mode darkman owns. It schedules off `[location]` in
`00-base.toml`: `auto_locate = false` with manual `sunrise = "06:00"` /
`sunset = "18:00"`. `auto_locate = true` previously geolocated and wrote an
**inverted** schedule (sunrise 18:00 / sunset 06:00), so night-light never fired.
Manual times keep any private lat/long out of this public repo.

### Qt (fcitx5-configtool etc.)

The Noctalia `qt` template writes `~/.config/qt{5,6}ct/colors/noctalia.conf`. Qt
only reads those if routed through the qtct platform theme, so the repo ships
`environment.d/qt.conf` (`QT_QPA_PLATFORMTHEME=qt6ct`) and `qt6ct.conf`/`qt5ct.conf`
that point `color_scheme_path` at `noctalia.conf` with `custom_palette=true`.

## Install

darkman is in [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt):

```sh
yay -S --needed darkman
```

The user service is enabled automatically on `chezmoi apply` by
[`run_onchange_after_enable-darkman-service.sh.tmpl`](../home/.chezmoiscripts/run_onchange_after_enable-darkman-service.sh.tmpl).
To do it by hand:

```sh
systemctl --user enable --now darkman.service
```

Set this machine's coordinates when prompted at `chezmoi init` (`lat`/`lng`); one
or two decimals is plenty ([relevant xkcd](https://xkcd.com/2170/)).

Don't know them off-hand? Ask your IP — city-level precision is all darkman needs:

```sh
curl -s ipinfo.io   # read the "loc" field: "10.82,106.63" = lat,lng
```

Run it **off the work VPN**. Over GlobalProtect (or any VPN) `ipinfo.io` returns
the exit datacenter's location, not yours — darkman would then flip light/dark on
the wrong schedule. See [vpn.md](vpn.md).

## Verify

```sh
darkman get                                                   # current mode
gsettings get org.gnome.desktop.interface color-scheme        # what apps read
darkman toggle                                                # flip and watch apps follow
systemctl --user status darkman.service                       # scheduler alive?
```

VS Code, Ghostty, Chrome, Waterfox, Discord, and Teams should re-theme live on a
toggle; the Noctalia bar, btop's next launch, and the per-monitor wallpaper follow
via darkman's hooks; a fish shell picks up the new theme on its next launch.

**After a reboot** (the real test of the `WAYLAND_DISPLAY` guard — darkman.service
starts before niri at boot), confirm the whole pipeline agrees with the current
mode. `theme-mode-get` is the value that used to lag:

```sh
gsettings get org.gnome.desktop.interface color-scheme        # prefer-dark | prefer-light
noctalia msg theme-mode-get                                   # dark | light  (MUST agree ↑)
noctalia msg wallpaper-get HDMI-A-1                           # F42-01-night | F42-01-day (MUST match mode)
gsettings get org.gnome.desktop.interface icon-theme          # Papirus-Dracula | Papirus-Latte
rg -oP '(?<=@define-color accent_bg_color )\S+' ~/.config/gtk-4.0/noctalia.css  # #bd93f9 | #209fb5
cat ~/.local/state/theme-reconcile.log                        # per-boot trace: mode + wallpaper re-drive
```

If `theme-mode-get` disagrees with the gsetting after boot, the guard didn't fire —
compare `set-color-scheme` against `systemctl --user show-environment`. Note the
boot case (shut down in one mode, boot into the other) is handled by
`dot-theme-reconcile`, not the guard; if it's still wrong at login, check that niri
spawns it after Noctalia and that Noctalia's socket appeared within its ~30 s wait.
The **wallpaper** is the more fragile channel — it has no gsetting fallback, so a
stale boot wallpaper (dark mode, light image) means the reconcile's wallpaper re-drive
didn't land; check the `wallpaper:` line in `theme-reconcile.log`.

```sh
noctalia msg color-scheme-get                                 # Noctalia's palette source
noctalia msg wallpaper-get DP-3                               # effective wallpaper per output
```

## References

- [darkman](https://darkman.whynothugo.nl/) · `man darkman`, `man darkman.conf`
- [Portal configuration for darkman](https://whynothugo.nl/journal/2024/04/09/darkman-portal-configuration/)
- [xdg-environment.md](xdg-environment.md) — how `Settings` is routed to the gtk portal
