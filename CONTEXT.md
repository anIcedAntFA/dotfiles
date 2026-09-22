# linux-setup — Context

Glossary for this dotfiles repo. Definitions only — the _how_ lives in `docs/`.
Terms here are the ones that are easy to conflate; pick the listed word, avoid the
rest.

## Secrets & access

**Store**:
The gopass password store — a GPG-encrypted, git-versioned repo of secrets that
lives **outside** this public repo. The one place private bytes (passwords, certs)
are kept.
_Avoid_: vault, password DB, keychain.

**Secret Service**:
The freedesktop D-Bus API `org.freedesktop.secrets` that desktop apps (Zed, Chrome
via libsecret) call to save and fetch credentials — an _interface_, not a program.
Whichever provider is running answers it: gnome-keyring here, KWallet or
`pass-secret-service` elsewhere. Distinct from the **Store**: the Secret Service is
the machine-local desktop keychain apps reach _automatically_; the Store is the
CLI/git-synced gopass repo you drive _by hand_. A niri session started by greetd
ships **no** provider by default — that gap is what makes apps re-login every launch.
_Avoid_: calling gnome-keyring "the Secret Service" (it's one implementation of it);
using "keychain" for the Store.

**Keyring** (`login` vs others):
gnome-keyring's own encrypted file(s) under `~/.local/share/keyrings/` (e.g.
`login.keyring`, a legacy `Default.keyring`) that back the Secret Service — the
concrete store behind the API. Each keyring carries its **own** password. The one
named **`login`** is the one PAM unlocks with your login password at session start
(seamless, no prompt); any other keyring keeps its own password and stays locked
until something unlocks it. A keyring's _name_ does not by itself cause a prompt —
whether you see one is decided by the **Default alias**, not the name.
_Avoid_: conflating a keyring (gnome-keyring's store) with the Secret Service (the API
in front of it), or with the gopass Store (a third, separate thing); treating "Default"
as a magic fallback name (it's just a keyring that isn't `login`).

**Default alias**:
The `~/.local/share/keyrings/default` pointer — exposed on D-Bus as the Secret
Service's `default` collection — naming **which keyring** apps get when they don't ask
for one by name. This is where the prompt-or-not outcome is actually decided: if the
alias resolves to a keyring PAM didn't unlock (e.g. a leftover `Default`), the first
app to use it fires the "unlock keyring" dialog — even while `login` sits unlocked and
empty. Point the alias at `login` and the prompt is gone.
_Avoid_: "default collection" / "default keyring" for the pointer (say _default
alias_); assuming a keyring's _name_, rather than the alias, picks the default.

**Trust anchor** (or _anchor_):
A CA certificate file under `/etc/ca-certificates/trust-source/anchors/`. It is the
**source of truth**; the matching files in `/etc/ssl/certs/` are generated from it
by `update-ca-trust`. When we say "restore a cert", we mean the anchor.
_Avoid_: calling the generated `/etc/ssl/certs/*.pem` the cert.

**Auth key** vs **Signing key**:
The same per-host SSH key registered on GitHub/GitLab **twice**, under two separate
roles — one to authenticate (push/pull), one to verify commit/tag signatures. Not
two different keys, and unrelated to the GPG key.
_Avoid_: treating "signing key" as GPG (signing is SSH here; GPG is only for the Store).

**Portal**:
The GlobalProtect VPN gateway host. Stored as the chezmoi var `workVpnPortal`, never
hard-coded in the repo.
_Avoid_: server, endpoint, gateway (in config we say portal).

## Machines

**Machine profile** (or _profile_):
One of the three boxes this config targets — `work`, `laptop`, or `home` — selected
by the chezmoi var `machine` (prompted on init, stored in the gitignored
`chezmoi.toml`). Templated configs branch on it to pick outputs, DPI cosmetics,
startup apps, and input. The value is a generic form-factor label, never a hostname
or company name (the real hostname may carry a company tag, so it stays out of the repo).
_Avoid_: host, box, device (in config we say profile / the `machine` var).

## Desktop

**Desktop shell** vs **Login shell**:
Two unrelated things that both get called "shell". The **desktop shell** is
[Noctalia](https://github.com/noctalia-dev/noctalia) — the Wayland bar,
widgets, and launcher layer that sits on top of the niri compositor. The **login
shell** is [fish](https://fishshell.com/) — the interactive command shell in the
terminal. When a doc or the README says "shell" unqualified, prefer one of these
two labels.
_Avoid_: bare "shell" (ambiguous); "bar"/"panel" for Noctalia (it's the whole shell).

**Login session** vs **systemd user session** vs **Wayland session**:
Three "sessions" in the boot chain, easy to smear together. The **login session** is
what [greetd](docs/greetd.md) + PAM open when you authenticate — tracked by
systemd-logind, owning `seat0`. The **Wayland session** is the entry the greeter
offers: a `.desktop` in `/usr/share/wayland-sessions/` whose `Exec` (here
`niri-session`) starts the compositor. The **systemd user session** is the
`systemctl --user` instance `niri-session` sets up (imports the env, brings up
`graphical-session.target`). One login → one Wayland session → one systemd user
session.
_Avoid_: bare "session" (say which); conflating any of these with a **niri
workspace**, a **Multiplexer session** (zellij), or the Secret Service's own notion
of a keyring "session".

**Login-ready output** vs **Late-enumerating output**:
The two kinds of monitor from the point of view of **startup** (`spawn-at-startup`).
A **login-ready output** has a logical position the instant niri comes up — the
**primary** on each box (`work`/`home`: `HDMI-A-2`/`HDMI-A-1`; `laptop`: its lone
panel). A **late-enumerating output** gets its logical position only _after_ login —
the **secondary** monitor (`work`: `DP-1`, `home`: `DP-3`). The distinction decides
_how_ an auto-started app is launched, and it's the app's **pinned output** that
classifies it, not the app: an app whose workspace lives on a login-ready output
**plain-spawns** (`spawn-at-startup "app"`; the window-rule's `open-on-workspace`
routes it), while one pinned to a late-enumerating output goes through
**`dot-niri-startup`**, which waits for that output to be positioned before
launching. See [ADR 0022](docs/adr/0022-login-ready-vs-late-enumerating-output-startup.md).
_Avoid_: "primary/secondary" as if it were about monitor _importance_ (here it's
purely login-time readiness); gating an app on a login-ready output (the poll is a
no-op there — a plain spawn is correct and keeps stderr on the journal).

## Terminal workspace layers

Three layers all get loosely called "workspace/tab/window"; keep them distinct.

**niri workspace**:
Compositor-level named workspace (`terminal`, `coding`, `browser`…), pinned to a
monitor via `open-on-output`. Owns `Super`-prefixed keys. This is where a
Ghostty _window_ lives.
A workspace _name_ pins to at most one output, and can host more than one app —
e.g. `browser` holds both zen and chrome (see
[ADR 0009](docs/adr/0009-zen-browser-not-forced-across-outputs.md), superseded).
Separately, whether an app actually _lands_ on its pinned workspace depends on
a window-rule's `open-on-workspace` — pinning the workspace to an output and
forcing a window onto it are two independent mechanisms; not every app uses
the second one.
_Avoid_: calling a Ghostty tab a "workspace"; conflating the output pin with the
window-rule that routes an app onto it.

**Ghostty tab** / **Ghostty split** (a split is a **pane**):
Inside a single Ghostty window. Tabs are switched along the bottom bar; a split
divides one tab into panes. This is the self-sufficient layer — it must work with
no multiplexer. Owns `Alt` keys, leader included (never `Super` — niri eats those).
_Avoid_: "pane" for a tab; "window" for a split.

**Multiplexer session** / **layout** (zellij, optional):
An _optional_ layer run inside one Ghostty surface for declarative project layouts
(repo→tab, code/log/btop→panes) and session persistence — the tmux-like capability
Ghostty lacks natively. Never required; Ghostty stands alone without it.
_Avoid_: conflating a zellij session with a niri workspace or a Ghostty tab.

## Terminal modal input

Three mechanisms in the same terminal window all get called "a mode". They differ
in how long they last and whether you can see them.

**Leader**:
A Ghostty _key sequence_ — `alt+space>r`. Consumes exactly **one** key, then ends
on its own. Nothing to exit; nothing to see. Not modal in the sticky sense.
_Avoid_: calling it a mode, or a prefix key.

**Key table**:
A Ghostty _named_ set of bindings (`resize/h=…`) that stays active until
`deactivate_key_table`. Sticky, and Ghostty renders **no indicator** for it — the
only cue is what the keys do. Owned by the Ghostty layer.
_Avoid_: conflating with a leader (that one is one-shot) or a zellij mode.

**zellij mode**:
The multiplexer's own modal layer (`Ctrl+n` for resize…), shown in its status bar.
Only exists when the optional zellij layer is running.
_Avoid_: saying "resize mode" unqualified — both Ghostty and zellij have one.

## Appearance

**Color-scheme** (the _mode_):
The system-wide dark/light preference — the `org.gnome.desktop.interface color-scheme`
gsetting (`prefer-dark` / `prefer-light`), served to apps by the gtk XDG portal.
[darkman](https://darkman.whynothugo.nl/) is its single writer, driven by both a
sunrise/sunset schedule and a manual keybind. It is a _mode_, not a colour palette;
it _selects_ a theme per app but is not itself one. The Noctalia **desktop shell**
can also write this gsetting, but it is deliberately kept a _follower_
(`colorSchemes.syncGsettings:false` + darkman's hook drives it) so darkman stays
the sole writer — see [ADR 0019](docs/adr/0019-darkman-owns-mode-noctalia-follows.md).
_Avoid_: calling the mode a "theme"; "dark mode" when you mean the palette; assuming
the desktop shell owns the mode (darkman does).

**Wallpaper** (the other mode channel):
The per-monitor background image, one per mode — also darkman-driven (its
`set-wallpaper` hook maps each connector to a dark/light image on every transition).
Critically, unlike the **Color-scheme**, it has **no compositor-independent
fallback**: darkman writes the color-scheme gsetting directly (the gtk portal
broadcasts it) even with the desktop shell down, but the wallpaper is set **only**
through Noctalia IPC (`noctalia msg wallpaper-set`). So a boot where darkman's hooks
fire before Noctalia's IPC is up breaks the wallpaper _unconditionally_ (the IPC call
fails silently, Noctalia asserts its stale persisted image) while the mode self-heals
— the classic symptom is **dark mode under a light wallpaper**. Because it can't
self-heal, the wallpaper is re-driven by the same login **reconcile**
([`dot-theme-reconcile`](home/dot_local/bin/executable_dot-theme-reconcile)) that
fixes the mode, once Noctalia can receive it. See
[ADR 0019](docs/adr/0019-darkman-owns-mode-noctalia-follows.md), docs/theme-sync.md.
_Avoid_: assuming the wallpaper follows the mode "for free" (it has no gsetting
fallback); treating a stale boot wallpaper as a Noctalia bug (it's the IPC-only
boot race).

**Theme** (per app):
The concrete palette an app shows for a given color-scheme mode — e.g. VS Code's
Dracula ↔ Github Light, Zed's Dracula ↔ Catppuccin Latte, fish's Dracula Official
↔ Catppuccin Latte, niri's focus-ring colours. Each app maps the one color-scheme
mode to its own two themes.
_Avoid_: "color-scheme" for a single app's palette; assuming one global theme.

**Noctalia palette** vs **MineScheme** (the identity):
A **Noctalia palette** is the set of Material-3 role colours (`mPrimary`,
`mSurface`, … + a `terminal` block) Noctalia resolves for the current mode and
feeds into every **Noctalia template**. The active palette comes from one of four
_sources_ (`[theme].source` in Noctalia's config: `builtin` / `wallpaper` /
`community` / `custom`). **MineScheme** is _our_ **custom** palette — the single
file that encodes this setup's whole identity: **`light` = Catppuccin Latte,
`dark` = Dracula**. One file carries both variants; in v5 it lives at
`~/.config/noctalia/palettes/MineScheme.json` (the v4 `colorschemes/<name>/…`
path is dead). Because Noctalia's own palette _is_ MineScheme, every Noctalia
template (btop, qt, niri…) renders that identity automatically. (GTK is **not**
templated — libadwaita + adw-gtk3 self-follow the mode live; see
[ADR 0021](docs/adr/0021-tiered-app-theming-minescheme-identity.md).)
_Avoid_: calling the Noctalia palette a **Theme** (a palette is Noctalia's
source colours; a Theme is one app's rendered result); assuming the built-in
Catppuccin palette is active (source is `custom`→MineScheme).

**Noctalia template** (theme-export):
Noctalia's own mechanism for pushing its generated colour palette into _other_
apps: an input template file is filled with the current palette and written to a
target app's config, optionally running a reload hook. In **v5** the built-in
catalog ships on disk (`/usr/share/noctalia/assets/templates/builtin.toml`) and is
enabled per-id via `[theme.templates].builtin_ids` / `community_ids` in Noctalia's
app-owned config (`~/.local/state/noctalia/settings.toml`) — **not** the dead v4
`settings.json → templates.activeTemplates`; custom ones go in a hand-written
`~/.config/noctalia/*.toml`. It is **not**
per-machine config and **not** a chezmoi template — a wholly separate meaning of
"template". So the word carries three senses here: chezmoi `.tmpl` (fills
`{{ .var }}` at apply), a Noctalia template (palette → another app's theme), and the
generic sense — always qualify which.
_Avoid_: reading `user-templates.toml` as a chezmoi/`.tmpl` thing or as machine
branching; conflating a Noctalia template with the per-app **Theme** it produces.

**Canvas** vs **art** (the banner logo):
The **canvas** is the fixed rectangle every fastfetch logo is padded out to — one
size per machine subset — so the module block starts at the same column no matter
which logo was drawn. The **art** is the figure itself, which may be smaller; it
never sets the layout. Width is the binding constraint, height only a ceiling.
_Avoid_: calling a logo's own extent "the canvas"; assuming a wider logo is
allowed to push the modules right.

**Mask** (a logo's authored form):
The committed artefact for a hand-drawn logo: a grid of one character per pixel,
each letter naming a **colour region** (outline, fur, belly, beak…) rather than a
colour. The mask is the thing a human edits and reviews in a diff — the coloured
escape sequences are generated from it at render time and are never authored
directly. Redrawing means editing the mask.
_Avoid_: treating the rendered escape output as the source; "ASCII art" for the
mask (it is a colour-region map, not the picture).

**Subject colour** vs **ring colour**:
A **subject colour** belongs to the thing depicted — a penguin's black, a
grizzly's brown, a beak's orange — and is therefore **the same in both modes**. A
**ring colour** is the outline separating a figure from the ground; its job is
contrast, not likeness, so it is **drawn from MineScheme per mode** (Latte in
light, Dracula in dark). This is the seam between
[ADR 0023](docs/adr/0023-starship-ansi-colours-over-hex-palette.md) (a logo colour
is fixed) and [ADR 0021](docs/adr/0021-tiered-app-theming-minescheme-identity.md)
(MineScheme is the identity) — they apply to different parts of the same drawing.
_Avoid_: the bare word **identity** for a subject colour — `CONTEXT.md` already
uses it for MineScheme (above) and for personal/work git config (below); inverting
a subject colour to gain contrast (that is the ring's job).

## Wayland rendering & input

**Native Wayland** vs **XWayland** (the _rendering path_):
Whether an app draws directly on the Wayland compositor (**native**) or through the
X11 compatibility layer (**XWayland**). Setting `XDG_SESSION_TYPE=wayland` does **not**
by itself make an app native — Chromium/Electron apps fall back to XWayland unless
given an Ozone hint. XWayland means software scaling: blur and caret/scroll jank on
fractionally-scaled or rotated outputs. The usual root cause of "VS Code feels laggy".
_Avoid_: assuming a Wayland session implies every app renders natively.

**Ozone** (the Chromium/Electron platform selector):
Chromium's backend-abstraction layer that picks X11 vs Wayland. Selected with
`--ozone-platform-hint=auto` (per-app flag) or `ELECTRON_OZONE_PLATFORM_HINT=auto`
(env). Only **Electron** reads the env var; plain Chromium and **Google Chrome do
not** — Chrome must be steered via its `.desktop` override.
_Avoid_: expecting the Electron env var to affect Chrome, or a flags file to affect
`google-chrome`.

**Desktop entry override**:
A copy of a system `/usr/share/applications/<name>.desktop` placed under
`~/.local/share/applications/` with the **same basename**, which shadows the system
one. Its only job here is to rewrite `Exec=` (force Ozone/Wayland, add IME). Distinct
from the auto-generated `mimeinfo.cache` / `userapp-*.desktop` files that also land in
that dir but are cache, not config, and stay untracked (gitignored).
_Avoid_: calling an override a "new app"; tracking the auto-generated neighbours.

**IM module** vs **Wayland text-input** (the two IME transports):
Two ways an app reaches fcitx. `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` route
input for **X11 / XWayland** apps; **native Wayland** apps use the compositor's
`text-input` protocol instead (and so don't need — and warn about — `GTK_IM_MODULE`).
Electron speaks `text-input` only on new-enough versions: current Electron (42, VS
Code 1.131) does it by default; older Electron (Slack/Teams/Discord) needs the
`--enable-wayland-ime` flag.
_Avoid_: assuming one transport covers every app; assuming every Electron app needs
`--enable-wayland-ime` (it's version-dependent — VS Code no longer does).

**Theme-follow (portal appearance)** vs **Ozone/IME**:
Three _independent_ properties of a Chromium/Electron app on Wayland, easy to
conflate. **Ozone** decides native-Wayland vs XWayland (rendering). **`--enable-wayland-ime`**
decides whether fcitx reaches it. **Theme-follow** is whether it repaints on the
`org.freedesktop.appearance color-scheme` portal broadcast — a native-Wayland app
gets the broadcast, but whether it _acts_ on a **live** change is app/version
dependent (Chrome/Zen do; Discord's stock Electron does so reliably only at launch —
see [docs/research/discord-wayland-theme-follow.md](docs/research/discord-wayland-theme-follow.md)).
_Avoid_: assuming Ozone alone makes an app follow the theme; assuming portal
broadcast reaching an app means it repaints live.

## Packages

Two orthogonal axes describe an installed package; the snapshot files in
`packages/` each cut along one of them, so an app can sit in both.

**Explicit** vs **Dependency**:
Whether _you_ asked for a package by name (**explicit**, `pacman -Qqe`) or it was
pulled in only to satisfy another package (**dependency**). Orthogonal to where it
came from.
_Avoid_: equating "explicit" with "official-repo" — an AUR app you installed by
name is explicit too.

**Native** vs **Foreign**:
Whether a package comes from a sync database — an **official repo** (native) — or
from outside one (**foreign**, `pacman -Qqm`): the AUR or a manual build.
Orthogonal to explicit/dependency.
_Avoid_: "foreign" as a synonym for AUR — a hand-built local package is foreign too
(the AUR is just the usual source).

**`pacman-explicit.txt`** vs **`aur.txt`** (the snapshots):
`pacman-explicit.txt` = `pacman -Qqe` (everything explicit, native **and** foreign).
`aur.txt` = `pacman -Qqm` (everything foreign). They overlap on every explicit
foreign app — that's why e.g. `zen-browser-bin` appears in both; it is by design,
not drift. Reference records only: nothing in the repo replays them.
A snapshot is a **record of intent, not a reproducible query**: the explicit flag is
mutable, so a reinstall or a meta-package can demote a tool you chose by name to a
mere dependency, after which `-Qqe` stops listing it. A listed name missing from
`-Qqe` is therefore as likely to be a demoted flag as a stale entry.
_Avoid_: treating a name's presence in both files as a bug.
_Avoid_: regenerating a snapshot from `-Qqe`/`-Qqm` wholesale — it silently drops
every demoted-but-still-wanted tool.

**Official repo** vs **AUR**:
`core`/`extra`/`multilib` are **official repos** — binary, signed, maintained by
Arch Package Maintainers (`community` was merged into `extra` in 2023);
`endeavouros` is EOS's small distro repo. The **AUR** is not a binary repo at all —
it's user-submitted `PKGBUILD` _recipes_, unvetted and unsigned, built locally by a
helper (paru/yay). So it's a trust gradient: organisation-vetted (official) →
individual/community, at-your-own-risk (AUR). A `-bin` suffix = an AUR recipe that
ships a prebuilt binary instead of compiling from source (often the only path for
proprietary apps kept out of the official repos for licensing).
_Avoid_: calling the AUR a "repo" in the binary sense; assuming an AUR package is
vetted the way an official one is.

## VS Code extensions

**Always-on extension** vs **On-demand extension**:
The two curation groups in `packages/vscode-extensions.txt`. **Always-on** =
editor-wide, language-agnostic tools kept globally enabled (themes, GitLens,
formatters, spell check…). **On-demand** = language/framework/tool-specific ones
kept globally _disabled_ and turned on per project via VS Code's _Enable
(Workspace)_. The split is documentation — the installer installs both groups; VS
Code can't install an extension pre-disabled.
_Avoid_: "default" / "project" extension (ambiguous); implying the grouping
auto-enables/disables anything.

## Identity

**Identity** (personal / work):
A git author+signing pair selected by directory via `includeIf`. "Personal" is the
default; "work" applies under the company ghq root.
_Avoid_: account, profile, user.
