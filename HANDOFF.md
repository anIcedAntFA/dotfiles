# Handoff — terminal workflow (Ghostty + zellij + zoxide)

Branch: `feat/ghostty-zellij-zoxide-workflow`. Two `/grill-with-docs` sessions
overhauled the terminal setup. Everything below is **implemented, `just check`
green (44 files), and committed on this branch**. The design rationale lives in
**[ADR 0008](docs/adr/0008-terminal-workspace-model.md)** and the guides — read
those first; this file only captures state + what's left.

## What shipped (see the diff + guides, not duplicated here)

- **Ghostty** ([config](home/dot_config/ghostty/config), [docs/ghostty.md](docs/ghostty.md)):
  Alt-namespace keymap + `Ctrl+Space` leader; opaque window with depth from a
  `background-image` via optional `config-file = ?ghostty-local.conf`; added
  `mouse-hide-while-typing`, `notify-on-command-finish` (notify-only), `copy-on-select`,
  `clipboard-trim-trailing-spaces`. Every option/keybind was validated against the
  `ghostty` 1.3.1 binary via an isolated `XDG_CONFIG_HOME` + `+show-config`.
- **zellij** ([config.kdl](home/dot_config/zellij/config.kdl),
  [layouts/_template.kdl](home/dot_config/zellij/layouts/_template.kdl),
  [docs/zellij.md](docs/zellij.md)): optional session/layout layer; `zj` fish picker
  ([functions/zj.fish](home/dot_config/fish/functions/zj.fish)).
- **zoxide** replaced `jethrokuan/z` ([docs/zoxide.md](docs/zoxide.md)): removed
  `__z*.fish` + `conf.d/z.fish`, dropped from `fish_plugins`, added to `.chezmoiremove`,
  wired `zoxide init` into `config.fish`, added to `packages/pacman-explicit.txt`.
- Glossary: **[CONTEXT.md](CONTEXT.md)** "Terminal workspace layers" section.

## Key facts established (don't re-derive)

- **Transparency was never broken.** It works on niri. Noctalia runs with
  `disableWallpaper: true` (solid-colour desktop), so a see-through window has nothing
  to reveal — hence `background-image` instead. The earlier light-theme / niri-conflict
  theories were both disproven.
- **Keybind namespaces are disjoint**: niri=`Super`, Ghostty=`Alt`+`Ctrl+Space`,
  zellij=`Ctrl`-modal. This is load-bearing (ADR 0008).
- Installed context: Ghostty 1.3.1-arch2, niri 26.04, gtk4 4.22, zoxide 0.10.0.
  zoxide 0.10 imports via `import z` subcommand reading `~/.z` (not `--from`).

## Open items / user action items (NOT done in-repo)

These are on the user to run on their machine (documented in the guides):

1. `chezmoi apply ~/.config/ghostty/config` — **targeted** apply. A plain
   `chezmoi apply` would clobber the app-managed `themes/noctalia` (flipping Dracula→Latte).
2. Create machine-local `~/.config/ghostty/ghostty-local.conf` + `backgrounds/bg.jpg`
   (untracked) for the background-image — steps in docs/ghostty.md.
3. zoxide migration: `cp ~/.local/share/z/data ~/.z; zoxide import z --merge; rm ~/.z`
   then `set -eU Z_CMD ZO_CMD Z_DATA Z_DATA_DIR Z_EXCLUDE`.
4. Fully **quit + relaunch** Ghostty (not reload).

## Not yet verified / risks

- **zellij artifacts are unvalidated** — zellij was not installed when written, so
  `config.kdl` / `_template.kdl` / the `zj` picker were authored from docs only. Test
  after `pacman -S zellij`: layout `~` cwd expansion, `zj` picker flow, theme_dark/light.
- **`themes/noctalia` shows perpetually dirty** in `chezmoi status` (Noctalia rewrites
  it per mode). Left untouched deliberately. Pending decision: add it to `.chezmoiignore`
  (clean) vs leave as-is. User said "say the word" — not yet decided.
- Whether niri's global `window-rule { opacity 0.8 }` (inactive) interacts oddly with
  Ghostty was noted but not changed.

## Suggested skills for the next session

- **git-workflow** — for any further commits (gitmoji + Conventional Commits; this
  branch already follows it).
- **grill-with-docs** — the user's preferred mode for the next design branch (e.g. the
  `themes/noctalia` `.chezmoiignore` decision, or zellij post-install tuning).
- **verify** / **run** — once zellij is installed, to actually drive the `zj` picker and
  a project layout end-to-end.

## Housekeeping

Delete this `HANDOFF.md` once the next session has picked up — it's a transient
work note, not a permanent repo doc.
