# Terminal workspace model: Ghostty-native base + optional zellij session layer

**Status:** accepted

The terminal needs two things that pull in different directions: a **self-sufficient**
Ghostty setup (tabs/splits that work with nothing else installed) and a **tmux-like
session model** (a project = many repos, each repo a tab, each tab several panes
running an editor, a script, and a log tail — restorable, declarative). Ghostty has
no native sessions and can't open a multi-split, multi-command layout at startup, so
the session model has to come from somewhere. We split the responsibility across two
layers with **non-overlapping keybind namespaces** so neither depends on the other:

- **Ghostty native** is the base. It owns `Alt+*` — both the direct binds and the
  `Alt+Space` leader (a key sequence). It must stay fully usable with no multiplexer —
  worst case, panes are opened by hand. `Super` is deliberately **not** used: niri
  (the compositor) grabs `Super` globally, so Ghostty would never receive
  `Super+hjkl`. `Alt` becomes "Ghostty's Super", reusing the `hjkl` muscle memory
  already built for niri.
- **zellij** is an **optional** layer for project work. When present it owns the whole
  session: project = one zellij session, repo = a zellij tab, panes = code/script/log.
  It drives everything through its default `Ctrl`-modal keys (`Ctrl+p/t/n/o/s…`), which
  Ghostty doesn't bind and therefore passes straight through. Persistence, the session
  picker, and declarative [layouts](../zellij.md) all live here. Ghostty's own tabs are
  then only for ad-hoc terminals.

The keybind partition is the load-bearing part: **niri = `Super`, Ghostty = `Alt`,
zellij = `Ctrl`-modal**. Three consumers, one modifier each, no interception fights.
`Ctrl+<letter>` is avoided for Ghostty binds because Ghostty consumes keys before the
terminal app sees them, and `Ctrl+A/E/W/L` etc. are shell line-editing.

The leader is `Alt+Space`, not the more traditional `Ctrl+Space`, so that `Alt`
stays the single rule for Ghostty. It is also the cheaper key to take: a leader is
swallowed whole — Ghostty waits **indefinitely** for the next key in the sequence and
never forwards the prefix on its own — and `Ctrl+Space` is a key programs want (it
sends `NUL`, and editors bind it for completion). Nothing wants `Alt+Space` here:
niri binds only `Alt+Print`, and `window-decoration = none` means there is no GTK
window menu to collide with.

`Ctrl+Tab` / `Ctrl+Shift+Tab` (cycle tabs) are the one deliberate carve-out from
zellij's `Ctrl` space. zellij's defaults are `Ctrl+g/p/t/n/h/o/s/q` — letters only —
so there is no actual contention.

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
  light-theme blend bug; that was a misdiagnosis.) `background-blur` is a no-op on
  niri regardless (it needs the KDE/KWin blur protocol).
- The background image is **tracked, and carried by the theme files**, which costs
  Noctalia's control of Ghostty's palette. `background-image` has no `light:/dark:`
  form — only `theme` does — but a theme file is an ordinary config file, so putting
  the image inside `themes/latte` and `themes/dracula` makes it swap with the mode
  for free. That requires two static theme files, so Noctalia's ghostty theming is
  switched off (`settings.json`, `id: ghostty` → `enabled: false`). Little is lost:
  Ghostty never watched the file Noctalia rewrote, so its colours only changed on a
  manual reload anyway; now both palette and image follow the desktop mode live. The
  cost is real but small — changing Noctalia's accent colour no longer reaches
  Ghostty. Two further knots come undone: `themes/noctalia` stops showing perpetually
  dirty in `chezmoi status`, and a plain `chezmoi apply` is safe again.
  An earlier draft kept the image in an untracked `config-file = ?ghostty-local.conf`
  "so the public repo carries no chosen wallpaper" — but the repo has always tracked
  `images/wallpaper/`, so that bought nothing and cost a manual setup step.
- Reversing is cheap for the tools (uninstall zellij/zoxide, delete `~/.config/zellij`)
  but the keybind muscle memory is the real switching cost — hence this record.
