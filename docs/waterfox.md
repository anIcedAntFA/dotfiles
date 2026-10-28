# Waterfox

[Waterfox](https://www.waterfox.com/) is the daily browser (Gecko engine, 6.7.x on
Gecko ESR 153; maintained by BrowserWorks, MPL-2.0). It replaced Zen. Chrome stays
for testing and for the work VPN's SSO login ([vpn.md](vpn.md)). The raw research,
with sources and an `UNVERIFIED` list, is in
[research/waterfox.md](research/waterfox.md) — this page is the working summary.

## What's managed, and where

Two scopes, see **Policies layer** / **Profile layer** / **Pinned profile** in
[CONTEXT.md](../CONTEXT.md#browser):

| Piece          | Repo                                                                                                                              | Lands at                                       | Applied by              |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ----------------------- |
| Policies layer | [`etc/waterfox/policies/policies.json`](../etc/waterfox/policies/policies.json)                                                   | `/etc/waterfox/policies/policies.json`         | `sudo install` (manual) |
| Profile layer  | [`home/dot_waterfox/main/user.js`](../home/dot_waterfox/main/user.js)                                                             | `~/.waterfox/main/user.js`                     | `chezmoi apply`         |
| Pinned profile | [`dot-waterfox`](../home/dot_local/bin/executable_dot-waterfox)                                                                   | `~/.local/bin/dot-waterfox`                    | `chezmoi apply`         |
| Desktop entry  | [`waterfox.desktop`](../home/dot_local/share/applications/waterfox.desktop)                                                       | `~/.local/share/applications/waterfox.desktop` | `chezmoi apply`         |
| niri           | `spawn-at-startup`, `app-id="waterfox"` window-rule, `Mod+B` ([niri-keybindings.md](niri-keybindings.md)); `MOZ_ENABLE_WAYLAND=1` | `~/.config/niri/config.kdl`                    | `chezmoi apply`         |

Not managed on purpose: bookmarks, logins, history, session, Sync — they live in the
profile and stay out of a public repo.

`/etc/waterfox/policies/policies.json` **shadows** the file `waterfox-bin` ships in
`/opt/waterfox/distribution/` (the first file found wins; there is no merge). That is
why `AppAutoUpdate:false` / `ManualAppUpdateOnly:true` are repeated: updates come
from the AUR, not the app.

## Install & apply

```sh
yay -S waterfox-bin                       # official tarball repacked into /opt/waterfox
chezmoi apply                             # wrapper, .desktop override, user.js, niri
sudo install -Dm644 etc/waterfox/policies/policies.json /etc/waterfox/policies/policies.json
xdg-settings set default-web-browser waterfox.desktop
```

Use `waterfox-bin`, not the source-built `waterfox` (the official tarball is
Widevine-signed, a source build is not) and not the Flatpak (the sandbox breaks
native messaging). The AUR package's own `.desktop` is stale
(`StartupWMClass=waterfox-default`, `Exec=waterfox-g`), hence the override.

### Move over from Zen

Do **not** point Waterfox at the Zen profile: Zen 1.23 runs Firefox 158, Waterfox is
on Gecko 153, and Waterfox is built with downgrade protection **off**, so it won't
refuse the newer profile — it just can't protect it. Instead:

1. Launch `dot-waterfox` once (creates `~/.waterfox/main`).
2. Run the import wizard (**File ▸ Import data**) and pick the Zen profile:
   bookmarks, history, logins. If Zen isn't auto-detected, choose its profile folder
   (`about:support` in Zen ▸ _Profile Directory_) or export bookmarks as HTML and
   logins via `about:logins` ▸ _Export_.
3. Zen-only things (spaces, essentials, glance, split layouts) don't carry over.
4. Once happy, remove the old ones: `yay -Rns zen-browser-bin firefox`.

## First-run checklist

Everything below was written from upstream source and the official tarball; none of
it was run on the niri machine yet. Check once and fix the repo if reality differs:

- [ ] `niri msg windows` shows `app-id: waterfox` — the window-rule matches on it.
- [ ] `about:support` ▸ _Window Protocol_ = `wayland`.
- [ ] `about:policies` lists the policy keys as active; Vimium-C is installed.
- [ ] `about:config` shows the `user.js` prefs (vertical + tree tabs on).
- [ ] Dark/light follows the portal on `darkman` toggle
      (`widget.use-xdg-desktop-portal.settings` defaults to auto).
- [ ] Screen share works (needs `xdg-desktop-portal` + PipeWire, see
      [screen-recording.md](screen-recording.md)).

## Choices and how to change them

- **Vertical + tree tabs** are native (6.7.0+), so no Sidebery and no `userChrome.css`
  — the horizontal strip is already hidden. To tweak chrome, add
  `~/.waterfox/main/chrome/userChrome.css` (works out of the box, the pref is locked
  on); read Waterfox's own `tree-tabs.css` inside `browser/omni.ja` for selectors.
  `Ctrl+Alt+Z` toggles the sidebar; in the tab strip, ← collapses and → expands a
  tree parent.
- **Keyboard navigation:** Vimium-C (force-listed in policies as `normal_installed`,
  so removable). Waterfox has no native vim navigation. Tridactyl was skipped — it
  needs a native messenger and an rc file outside the browser.
- **Ads/trackers:** the built-in blocker only. Installing uBlock Origin triggers its
  extension-conflict warning unless `waterfox.blocker.coexist=true`; add both only
  if the built-in lists fall short.
- **Passwords:** Waterfox's own store (`logins.json` + NSS `key4.db` in the profile,
  strategy A in [secret-service.md](secret-service.md)). gopass-bridge is possible
  later but needs native messaging.
- **DNS:** `network.trr.mode=5` (off). Waterfox defaults to DoH over an OHTTP relay
  for new profiles, which can bypass the work VPN's split-horizon DNS. Delete the line
  if you don't use the VPN.
- **Left unset until measured:** VA-API (`media.hardware-video-decoding.force-enabled`,
  needs `libva-nvidia-driver` on the NVIDIA box), `dom.ipc.processCount`, and
  `widget.wayland.opaque-region.enabled` (only if fullscreen video flickers). Turn on
  only when `about:support` says so.
- **Not copied from Betterfox/arkenfox:** Waterfox already ships telemetry, studies,
  Safe Browsing, sponsored content and AI off; the lists add breakage-prone prefs
  (HTTPS-only, RAM-only cache, strict ETP) with little proven benefit.

## What's good, what's not

| Aspect              | Waterfox 6.7                                                | Zen 1.23                                  |
| ------------------- | ----------------------------------------------------------- | ----------------------------------------- |
| Gecko base          | 153 (ESR)                                                   | 158 (rapid)                               |
| Tabs                | Native vertical + tree tabs, tab groups, split view         | Vertical tabs, spaces, essentials, glance |
| Privacy defaults    | Telemetry, Normandy, Safe Browsing, sponsored, AI off       | not checked                               |
| Built-in blocker    | Yes (adblock-rust)                                          | not checked                               |
| Extensions          | Firefox add-ons, legacy XUL; Chrome Web Store removed       | Firefox add-ons                           |
| Weight              | ~490 MB unpacked (128.8 MiB download)                       | not measured                              |
| Security patch pace | Follows Mozilla ESR advisories; smaller team (single owner) | Rapid-release cadence                     |

Cons worth knowing: no spaces/workspaces; no Linux PWA support found; smaller
maintainer base than Mozilla; AUR repack lags the tarball by hours; DRM and DoH
behave differently from stock Firefox and need a deliberate choice.

## Performance

No trustworthy RAM/CPU benchmark of Waterfox 6.7 against Zen, Firefox or Chrome was
found, so this repo claims none. Process model is stock Firefox: e10s + Fission,
`dom.ipc.processCount=8` (web-isolated 4). Tab unloading is **off** on Linux by
default; `user.js` turns it on for tabs idle an hour. Measure on your own tabs:

```sh
# RSS summed over every Waterfox process (double-counts shared pages)
ps -eo rss,args | rg '/opt/waterfox/' | awk '{s+=$1} END {printf "%.0f MiB\n", s/1024}'
# time to a first headless window
hyperfine --warmup 1 'waterfox --new-instance --profile /tmp/wf-bench --headless about:blank'
```

Run the same 10–20 tabs and extensions in each browser, two minutes after load.
