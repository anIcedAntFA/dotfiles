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
[Noctalia](https://github.com/noctalia-dev/noctalia-shell) — the Wayland bar,
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
it _selects_ a theme per app but is not itself one.
_Avoid_: calling the mode a "theme"; "dark mode" when you mean the palette.

**Theme** (per app):
The concrete palette an app shows for a given color-scheme mode — e.g. VS Code's
Dracula ↔ Github Light, Zed's Dracula ↔ Catppuccin Latte, fish's Dracula Official
↔ Catppuccin Latte, niri's focus-ring colours. Each app maps the one color-scheme
mode to its own two themes.
_Avoid_: "color-scheme" for a single app's palette; assuming one global theme.

**Noctalia template** (theme-export):
Noctalia's own mechanism for pushing its generated colour palette into _other_
apps: an input template file is filled with the current palette and written to a
target app's config, optionally running a reload hook. Built-in ones ship in
`settings.json` under `templates.activeTemplates` (niri, yazi, zathura, btop, gtk,
qt); custom ones go in `home/dot_config/noctalia/user-templates.toml`. It is **not**
per-machine config and **not** a chezmoi template — a wholly separate meaning of
"template". So the word carries three senses here: chezmoi `.tmpl` (fills
`{{ .var }}` at apply), a Noctalia template (palette → another app's theme), and the
generic sense — always qualify which.
_Avoid_: reading `user-templates.toml` as a chezmoi/`.tmpl` thing or as machine
branching; conflating a Noctalia template with the per-app **Theme** it produces.

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
that dir but are cache, not config, and stay untracked.
_Avoid_: calling an override a "new app"; tracking the auto-generated neighbours.

**IM module** vs **Wayland text-input** (the two IME transports):
Two ways an app reaches fcitx. `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` route
input for **X11 / XWayland** apps; **native Wayland** apps use the compositor's
`text-input` protocol instead (and so don't need — and warn about — `GTK_IM_MODULE`).
Electron speaks `text-input` only on new-enough versions: current Electron (42, VS
Code 1.131) does it by default; older Electron needs the `--enable-wayland-ime` flag.
_Avoid_: assuming one transport covers every app; assuming every Electron app needs
`--enable-wayland-ime` (it's version-dependent — VS Code no longer does).

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
_Avoid_: treating a name's presence in both files as a bug.

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
