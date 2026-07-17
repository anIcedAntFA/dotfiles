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

## Terminal workspace layers

Three layers all get loosely called "workspace/tab/window"; keep them distinct.

**niri workspace**:
Compositor-level named workspace (`terminal`, `coding`, `browser`…), pinned to a
monitor. Owns `Super`-prefixed keys. This is where a Ghostty _window_ lives.
_Avoid_: calling a Ghostty tab a "workspace".

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

## Identity

**Identity** (personal / work):
A git author+signing pair selected by directory via `includeIf`. "Personal" is the
default; "work" applies under the company ghq root.
_Avoid_: account, profile, user.
