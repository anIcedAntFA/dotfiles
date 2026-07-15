# Terminal workspace model: Ghostty-native base + optional zellij session layer

**Status:** accepted

The terminal needs two things that pull in different directions: a **self-sufficient**
Ghostty setup (tabs/splits that work with nothing else installed) and a **tmux-like
session model** (a project = many repos, each repo a tab, each tab several panes
running an editor, a script, and a log tail — restorable, declarative). Ghostty has
no native sessions and can't open a multi-split, multi-command layout at startup, so
the session model has to come from somewhere. We split the responsibility across two
layers with **non-overlapping keybind namespaces** so neither depends on the other:

- **Ghostty native** is the base. It owns `Alt+*` (direct) and `Ctrl+Space` (leader,
  a key-table). It must stay fully usable with no multiplexer — worst case, panes are
  opened by hand. `Super` is deliberately **not** used: niri (the compositor) grabs
  `Super` globally, so Ghostty would never receive `Super+hjkl`. `Alt` becomes
  "Ghostty's Super", reusing the `hjkl` muscle memory already built for niri.
- **zellij** is an **optional** layer for project work. When present it owns the whole
  session: project = one zellij session, repo = a zellij tab, panes = code/script/log.
  It drives everything through its default `Ctrl`-modal keys (`Ctrl+p/t/n/o/s…`), which
  Ghostty doesn't bind and therefore passes straight through. Persistence, the session
  picker, and declarative [layouts](../zellij.md) all live here. Ghostty's own tabs are
  then only for ad-hoc terminals.

The keybind partition is the load-bearing part: **niri = `Super`, Ghostty = `Alt` +
`Ctrl+Space`, zellij = `Ctrl`-modal**. Three consumers, three disjoint modifier spaces,
no interception fights. `Ctrl+<letter>` is avoided for Ghostty binds because Ghostty
consumes keys before the terminal app sees them, and `Ctrl+A/E/W/L` etc. are shell
line-editing.

## Considered options

- **Ghostty base + optional zellij (chosen).** Ghostty stands alone; zellij is additive.
  Costs: two key systems to learn (`Alt` for Ghostty, `Ctrl`-modal for zellij), and the
  discipline of not nesting Ghostty splits inside a zellij session.
- **zellij over tmux** for the session layer. zellij's layouts are **KDL** — the same
  language as the niri config — its status bar advertises keybinds (discoverable), and
  it ships a session manager. tmux would need `tmuxinator`/`sesh` for the same
  declarative layouts and is far less discoverable. tmux's edge (detach survives a
  terminal crash, mature ecosystem) didn't outweigh the KDL/discoverability fit.
- **Pure Ghostty-native, no multiplexer** — rejected. `window-save-state = always`
  resumes tabs/splits/cwd but **not** running programs, and there is no way to declare
  "open these repos with these panes running `btop`/logs" at startup. Fails the headline
  requirement.
- **`Super` for Ghostty** — impossible, not merely rejected: niri intercepts `Super`
  before Ghostty exists in the input path.

## Consequences

- Ghostty's dead binds are removed: `super+b>N` never fired (niri owns `Super+B` =
  browser), and the old `ctrl+alt+arrow` splits are replaced by the `Alt+Enter` scheme.
- Window **transparency is not used**; the terminal stays opaque and depth comes from
  a `background-image`. `background-opacity` does work on niri, but Noctalia runs with
  the wallpaper disabled (a solid-colour desktop), so a see-through window would only
  pick up that flat colour — nothing to reveal. (An earlier draft wrongly blamed a
  light-theme blend bug; that was a misdiagnosis.) The image is wired through an
  optional untracked `config-file = ?ghostty-local.conf`, mirroring the `local.fish`
  pattern, so the public repo carries no chosen wallpaper. `background-blur` is a
  no-op on niri regardless (it needs the KDE/KWin blur protocol).
- Reversing is cheap for the tools (uninstall zellij/zoxide, delete `~/.config/zellij`)
  but the keybind muscle memory is the real switching cost — hence this record.
