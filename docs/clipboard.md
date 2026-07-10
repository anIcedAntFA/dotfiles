# Clipboard — wl-clipboard · cliphist · Noctalia

## Why this is three pieces

On Wayland the clipboard has no history and no persistence of its own: the copied
data lives **inside the app you copied from**, and the compositor just brokers it
to whoever pastes next. Close that app and the content can disappear; there's no
"last 20 things I copied". So a usable clipboard is a small stack:

- **`wl-clipboard`** — the CLI primitives `wl-copy` / `wl-paste`. This _is_ the
  Wayland clipboard interface; everything else builds on it.
- **[cliphist](https://github.com/sentriz/cliphist)** — the **history store**. A
  watcher (`wl-paste --watch cliphist store`) records every clipboard change into
  a small on-disk database you can later list, decode, and re-copy.
- **[Noctalia](https://github.com/noctalia-dev/noctalia)** — the **UI**. Its
  built-in launcher has a clipboard mode: a searchable panel over cliphist with
  Text / Images / Files tabs and a preview pane.

`wl-clipboard` + `cliphist` is the idiomatic niri/Wayland pairing; Noctalia is
just the frontend our shell already ships — no extra clipboard daemon or plugin.

## How it's wired here

Nothing to start by hand. **Noctalia launches the cliphist watchers itself** (one
for `text`, one for `image`) as children of `qs -c noctalia-shell`, so history
records for as long as the shell runs, on any machine, with no `spawn-at-startup`
entry needed.

Open the panel with the keybind (see
[niri-keybindings.md](niri-keybindings.md#applications--launchers)):

| Keybind       | Action                                               |
| ------------- | ---------------------------------------------------- |
| `Mod+Shift+C` | Open the Noctalia launcher in clipboard-history mode |

Under the hood the bind is a Noctalia IPC call:

```sh
qs -c noctalia-shell ipc call launcher clipboard
```

Pick an item to put it back on the clipboard, then paste it yourself with
`Ctrl+V` (`Ctrl+Shift+V` in a terminal). The delete (trash) icon drops a single
entry from history.

## Install

```sh
yay -S --needed wl-clipboard cliphist
```

Both are in [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt).
Noctalia itself is set up separately as part of the shell.

## CLI: dot-clip-copy / dot-clip-paste

Thin, memorable wrappers over `wl-copy` / `wl-paste`
([`dot-clip-copy`](../home/dot_local/bin/executable_dot-clip-copy),
[`dot-clip-paste`](../home/dot_local/bin/executable_dot-clip-paste)) — args pass
straight through:

```sh
echo "hello" | dot-clip-copy        # → clipboard (and into cliphist history)
dot-clip-paste | sort               # ← clipboard to stdout
```

Keep a secret **out** of history with `--sensitive` (cliphist honours the hint —
verified: content copied this way never lands in the panel):

```sh
gopass show wifi/home | dot-clip-copy --sensitive
```

Note the distinction Wayland makes between the **clipboard** (Ctrl+C / Ctrl+V) and
the **primary selection** (middle-click paste): these wrappers use the clipboard;
add `--primary` to reach the other one. cliphist watches the clipboard.

## Working with cliphist directly

The panel is optional — cliphist is scriptable on its own:

```sh
cliphist list                       # ids + previews of history
cliphist list | fuzzel --dmenu | cliphist decode | wl-copy   # pick with any menu
cliphist wipe                       # clear the whole history
```

## Optional: the Clipper / clipboard plugins

Noctalia's [v4 plugin repo](https://github.com/noctalia-dev/legacy-v4-plugins)
ships two clipboard frontends that add features on top of the same cliphist
backend — install them from Noctalia's **Settings → Plugins** UI if you want them:

- **`clipboard`** — the built-in panel's feature set as a dockable plugin
  (Text / Images / Files, pinning, search).
- **`clipper`** — a superset: **pinned items, NoteCards (sticky notes), ToDo
  integration, and auto-paste**. Auto-paste needs [`wtype`](https://github.com/atx/wtype)
  (not installed here); without it, selecting still copies and you paste yourself.

Neither is required — the core launcher clipboard mode above already covers
searchable text + image history. (Heads-up: `home/dot_config/noctalia/plugins.json`
may list `clipper` as enabled, but it won't load until it's actually installed
from a plugin source that carries it — the built-in mode doesn't depend on it.)

## Why not elephant / Walker?

[elephant](https://github.com/abenz1267/elephant) is a **data-provider daemon**
for the [Walker](https://github.com/abenz1267/walker) launcher — clipboard is one
of its many providers (apps, calc, emoji, files, package search…). It's a great
fit **if Walker is your launcher**. Here the launcher _is_ Noctalia, which already
provides the clipboard panel over the same `cliphist` backend — so pulling in
Walker + a second daemon would duplicate the launcher for zero clipboard gain.
elephant belongs to a Walker-centric rice (e.g. nickjj's `dotfriedrice`), not this
Noctalia one.

## References

- [wl-clipboard](https://github.com/bugaevc/wl-clipboard) — `wl-copy` / `wl-paste`
- [cliphist](https://github.com/sentriz/cliphist) — Wayland clipboard history
- [Noctalia v4 plugins](https://github.com/noctalia-dev/legacy-v4-plugins) — `clipboard`, `clipper`
- [niri wiki: important software](https://github.com/YaLTeR/niri/wiki/Important-Software)
