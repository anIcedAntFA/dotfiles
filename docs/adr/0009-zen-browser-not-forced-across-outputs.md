# zen-browser is not forced onto a workspace on multi-monitor machines

**Status:** accepted

The `home` machine has two outputs that each want a browser: HDMI-A-1 hosts
zen (the `browser` workspace) and DP-3 hosts chrome (a new `web` workspace).
Every other autostarted app (ghostty, code, slack, teams-for-linux, discord)
is forced onto its workspace with a `window-rule { match app-id=...
open-on-workspace "..."; }`, matching [ADR 0006](./0006-per-machine-niri-via-chezmoi-template.md)'s
model of one named, monitor-pinned workspace per role. Doing the same for zen
does not work: it's a single-instance browser, and empirically (`--class`
tested against a running instance, confirmed via `niri msg windows`) a second
zen process still reports the Wayland `app-id` as plain `"zen"` — niri's
window-rules match on `app-id`, so one rule can only ever route _all_ zen
windows to the same place, on every machine, for every window (including ones
opened later, not just at startup).

## Considered options

- **No window-rule for zen on `home`; keep it on work/laptop** — chosen. The
  `zen` window-rule's `open-on-workspace "browser"` is wrapped in
  `{{ if ne $machine "home" }}` so work/laptop keep their proven forced
  placement, while on `home` zen windows land wherever focus is (typically
  HDMI-A-1 at startup) and can be dragged to DP-3's `web` workspace
  (`Mod+Shift+Ctrl+Right`) without a rule fighting the move back.
- **Two zen instances with distinct `--class` values, routed by separate
  window-rules** — rejected. Tested and disproven: zen ignores `--class` on
  Wayland (both instances report `app-id="zen"`), so this can't work without
  patching zen or wrapping it in a launcher that spoofs a different binary
  identity — not worth the fragility for a cosmetic autostart placement.
- **Force zen to one output only, chrome covers the other** — rejected as the
  sole answer, though it's the practical fallback: it would satisfy "a browser
  on each screen" but not "zen specifically on both", which was the actual ask.

## Consequences

- The `browser` (HDMI-A-1) and `web` (DP-3) workspaces are two distinct
  named workspaces serving the same _role_ ("a browser lives here"), pinned to
  different outputs — see the updated `niri workspace` entry in
  [CONTEXT.md](../../CONTEXT.md). A role is not guaranteed to map to exactly
  one workspace name per machine.
- On `home`, a manually opened zen window is not guaranteed to land on
  HDMI-A-1 — it follows focus like any unmatched window. This is a deliberate
  trade-off: predictable-but-wrong (always snapping to one output) was judged
  worse than unforced-but-flexible.
