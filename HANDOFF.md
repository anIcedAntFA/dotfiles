# HANDOFF — screen recording + bundled niri/fastfetch WIP

> Transient continuation note (public-safe: no secrets/company data). Delete once
> the work below is picked up.

## Where things stand

- **Branch:** `feat/screen-recording-wl-screenrec` (committed, **not pushed / no PR
  yet** — push it to continue on the other machine).
- **Verification:** `just check` green (oxfmt, markdownlint, shellcheck, shfmt,
  fish, gitleaks — no leaks); `just validate-niri` valid.
- **Heads-up:** this branch bundles **two concerns** because they're entangled in
  shared files (`config.kdl.tmpl`, `niri.md`, `README.md`, `niri-keybindings.md`
  each carry both). Clean per-concern splitting wasn't possible without fragile
  hunk-surgery. The two are described separately below.

## What shipped — 1. Screen recording (this session's work)

Wraps `wl-screenrec` (GPU h264) as a start/stop capture tool, mirroring
`dot-screenshot`.

- **`home/dot_local/bin/executable_dot-screenrec`** — `region` (slurp `-g`),
  `screen` (focused output `-o`), `stop` (SIGINT the tracked PID). Single instance
  via `$XDG_RUNTIME_DIR/dot-screenrec.state`; start-while-recording refuses +
  notifies. Silent by default, trailing `audio` arg → `--audio`. Output:
  `.mp4`/`--codec avc` → `$XDG_VIDEOS_DIR/Screencast from <ts>.mp4`. `notify-send`
  on start/stop.
- **niri binds** (`config.kdl.tmpl`): `Mod+Print` region · `Mod+Shift+Print`
  screen · `Mod+Ctrl+Print` stop. No collisions.
- **Docs:** `docs/satty.md` → `docs/screenshot.md` (reframed around the task, satty
  as annotator); new `docs/screen-recording.md`. Fixed all 3 stale `satty.md`
  links (README, niri.md, niri-keybindings.md); added record rows to the keybind
  table. `packages/aur.txt` gets `wl-screenrec-git`.
- **Bug fix:** renamed `dot-screenshot` → `executable_dot-screenshot`. It had **no
  `executable_` prefix**, so a fresh `chezmoi apply` wrote it non-executable and
  `spawn "dot-screenshot"` would silently fail.

## What shipped — 2. Prior niri/fastfetch WIP (predates this session)

Was already uncommitted in the tree; carried along, not authored this session — **eyeball before you trust it**:

- **niri per-machine templating:** `config.kdl` → `config.kdl.tmpl` +
  `docs/adr/0006-per-machine-niri-via-chezmoi-template.md`; `home/.chezmoi.toml.tmpl`
  gained the machine prompt(s).
- **niri docs split:** new `docs/niri-concepts.md`, `docs/niri-config.md`,
  `docs/niri-keybindings.md`; `docs/niri.md` + `README.md` updated to link them.
- **fastfetch:** `config.jsonc` → `config.jsonc.tmpl`,
  `executable_random-logo` script, `logos/` (`laptop`, `pc`), `docs/fastfetch.md`.
- `CONTEXT.md`, `justfile` touched by the above.

## Pending — pick up here

1. **`git push -u origin feat/screen-recording-wl-screenrec`** then open the PR
   (not done this session — user asked for commit only).
2. **Live-test the recorder** (couldn't in-session — needs a display + interactive
   slurp): `chezmoi apply` (deploys both scripts), then `Mod+Shift+Print` to start,
   `Mod+Ctrl+Print` to stop, confirm a playable file lands in `~/Videos`. Also try
   `dot-screenrec region audio`. Verify VA-API works or `--no-hw` is needed.
3. **Review the bundled prior WIP** (§2) — decide if it's ready to ship on this PR
   or should be split back out.

## Known issues (persistent, out of scope)

- **Package snapshot drift** — `packages/pacman-explicit.txt` out of sync with live
  `pacman -Qqe`. **Do NOT blindly regenerate** (drops wanted pkgs). (In agent memory.)
- **noctalia `settings.json`** hardcodes absolute repo paths — not portable to a
  fresh machine/user.

## Suggested skills next session

- **git-workflow** — push + open the PR.
- **verify** — after `chezmoi apply`, drive a real recording start→stop.
- **grill-with-docs** — if tackling the bundled niri/fastfetch WIP or the drift.
