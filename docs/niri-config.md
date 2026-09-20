# niri — configuration guide

A section-by-section tour of [`config.kdl.tmpl`](../home/dot_config/niri/config.kdl.tmpl),
plus how the one file serves three machines. Read
[niri-concepts.md](niri-concepts.md) first if the words _column_ / _workspace_ /
_output_ aren't yet second nature. Keybinds have their own page:
[niri-keybindings.md](niri-keybindings.md).

## The file is a chezmoi template

The source is `config.kdl.tmpl`, not `config.kdl`. chezmoi renders it to
`~/.config/niri/config.kdl` on `chezmoi apply`, and **niri hot-reloads the
rendered file**, not the template. So the edit loop is:

```sh
chezmoi edit ~/.config/niri/config.kdl   # opens the .tmpl source
just validate-niri                        # render it + `niri validate`
chezmoi apply                             # write the real config.kdl → niri reloads
```

`chezmoi edit --watch` applies on every save if you want the tight loop. Editing
`~/.config/niri/config.kdl` directly still hot-reloads instantly, but the change
is **outside chezmoi** and will be overwritten on the next `apply` — treat the
rendered file as disposable.

Why a template at all? Three machines (office desktop, personal laptop, home
desktop) with different monitors, DPI, and startup apps share one config, and the
differences are selected by a single variable. See
[ADR 0006](adr/0006-per-machine-niri-via-chezmoi-template.md) for the decision.

## KDL in 30 seconds

niri configs are [KDL](https://kdl.dev/). You'll only ever touch a few shapes:

```kdl
node "argument" property=value {   // a node with an arg, a property, children
    child-node 42                  // arguments can be numbers/strings/bools
    flag                           // a bare node = a boolean turned ON
}
// line comment
/-node { ... }                     // "/-" comments out an ENTIRE node + children
```

Key gotcha: a **flag** (like `numlock`, `prefer-no-csd`, `off`) is enabled just
by being present. To disable it you delete or `//` it — there is no `= false`.

Validate any time with `niri validate`; this repo wraps that as `just
validate-niri` (it renders the template first, since raw `{{ }}` isn't valid KDL).

## The per-machine profile table

At the very top the template picks a **profile** from the `machine` chezmoi var
and pulls per-machine scalars from one dictionary:

```kdl
{{- $machine := dig "machine" "work" . -}}
{{- $profiles := dict
    "work"   (dict "cursor" 64 "gaps" 12 "ws" (dict "terminal" "HDMI-A-2" ...))
    "laptop" (dict "cursor" 32 "gaps" 8  "ws" (dict))
    "home"   (dict "cursor" 64 "gaps" 12 "ws" (dict "terminal" "HDMI-A-1" ...)) -}}
{{- $p := index $profiles $machine -}}
```

- `machine` is prompted once at `chezmoi init` (stored in the **gitignored**
  `~/.config/chezmoi/chezmoi.toml`, so the public repo never sees your hostname).
  Valid values: `work`, `laptop`, `home`.
- `$p.cursor`, `$p.gaps` are read inline where those settings live, so the whole
  file has **one** place that answers "what's different about the laptop?".
- `$p.ws` maps each named workspace to the monitor it should open on (empty for
  single-monitor boxes).
- `dig` (not a bare `.machine`) is used so ad-hoc renders don't error before the
  var exists; it falls back to `work`.

Whole multi-line blocks that can't collapse to a scalar (output definitions,
the touchpad block, the work-only startup apps) branch inline with
`{{ if eq $machine "..." }}` where they naturally sit.

### Adding a machine or changing a value

- Tune an existing box: edit its row in `$profiles` (e.g. bump `laptop`'s cursor).
- Add a fourth machine: add a `"name" (dict ...)` row, add its `output` block in
  the OUTPUTS section, and update the prompt hint in
  [`.chezmoi.toml.tmpl`](../home/.chezmoi.toml.tmpl). An unknown `machine` value
  fails the render loudly (by design), so typos surface immediately.

## Section by section

### Global

`prefer-no-csd` asks apps to drop their own title bars (niri draws the
focus-ring instead). `screenshot-path` sets where `Print`-key screenshots land
(`null` keeps them in memory only). `hotkey-overlay` controls the startup "important
hotkeys" popup. `environment` exports session vars to spawned processes.

### input

- **keyboard** — `repeat-delay`/`repeat-rate` (how fast held keys repeat),
  `numlock` on at login, and an `xkb {}` block for layout/options (e.g.
  `options "ctrl:nocaps"` to make Caps Lock a Ctrl).
- **touchpad / trackpoint** — rendered **only on the `laptop` profile** (desktops
  have neither). `tap` = tap-to-click, `natural-scroll`, `accel-speed`.
- **focus-follows-mouse** with `max-scroll-amount="20%"` — focus tracks the
  pointer, but only once it's moved enough to be intentional.

### cursor

`xcursor-theme` + `xcursor-size` (from `$p.cursor`, so it shrinks on the laptop),
plus `hide-when-typing` and `hide-after-inactive-ms`.

### outputs (per machine)

Each monitor is an `output "<connector>" { ... }` block. Find the connector name
and available modes with `niri msg outputs`.

| Setting     | Meaning                                                                    |
| ----------- | -------------------------------------------------------------------------- |
| `mode`      | `"WxH@rate"`. Omit to let niri pick the highest refresh rate.              |
| `scale`     | HiDPI factor. Integer (`2`) or fractional (`1.5`). Unset = auto-estimated. |
| `transform` | Rotation: `"normal"`, `"90"`, `"180"`, `"270"`, and `flipped-*` mirrors.   |
| `position`  | `x=… y=…` in **logical** (scaled) px — defines monitor adjacency.          |
| `off`       | Disable the output entirely.                                               |

**Positioning math**: positions are in logical pixels, so a 3840×2160 output at
`scale 2` is 1920×1080 logically; the next monitor to its right starts at
`x=1920`. Overlaps get auto-repositioned. Outputs you don't configure are placed
automatically (sorted by name, so it's deterministic), and outputs that aren't
connected are simply ignored — which is why all three machines can coexist in one
file.

The `work` profile here is two ASUS PA278CV panels: `HDMI-A-2` rotated to
**portrait** on the left (`transform "90"`, `position x=1280`), and `DP-1` in
landscape to its right (auto-placed; shown as a commented block you can enable to
pin its refresh rate). `laptop` and `home` are commented `# TODO` scaffolds — run
`niri msg outputs` on each box and fill them in.

### layout

The visual + tiling behaviour. `gaps` comes from `$p.gaps`. `preset-column-widths`
are the widths `Mod+R` cycles (1/3, 1/2, 2/3); `default-column-width` is what new
columns open at. `center-focused-column` decides whether the focused column
recentres.

**Colors live elsewhere.** `focus-ring`, `border`, and `shadow` here set only
_structure_ (width, softness, offset). Their colours are themed by
[`noctalia.kdl`](../home/dot_config/niri/noctalia.kdl), which is `include`d last
and wins. `border` is `off` because the `focus-ring` is used instead — remove
`off` to get per-window borders.

### named workspaces

Five persistent workspaces are defined so window rules can target them by name.
Monitor pinning is data-driven from `$p.ws`:

```kdl
workspace "terminal" {
    {{- with (index $p.ws "terminal") }}
    open-on-output {{ . | quote }}   // only emitted when the table has a value
    {{- end }}
}
```

`work` and `home` share the same shape: `terminal`/`coding` pin to the portrait
monitor (work `HDMI-A-2`, home `HDMI-A-1`) and `browser`/`chatting`/`tools` to the
landscape one (work `DP-1`, home `DP-3`). On single-monitor `laptop`, `$p.ws` is
empty so no pinning is emitted and the names still exist.

**Pin every workspace on a multi-monitor profile.** A declared workspace with no
`open-on-output` isn't skipped — it floats onto the first output and, because niri
orders workspaces by creation, grabs **slot 1** there, pushing the intended
occupant down. So each of the five names must appear in the `work` and `home`
tables (even if two share an output). Single-monitor `laptop` is exempt: with one
output the unpinned names just stack in declaration order.

### startup

`spawn-at-startup` launches the shell (`qs -c noctalia-shell`) and terminal on
every machine, plus `fcitx5` + `xsettingsd`. Machine blocks add the rest: `work`
gets VS Code, `home` gets Discord — and `zen` plain-spawns only on single-monitor
`laptop` (on `work`/`home` it's gated, see below). Use `spawn` for a plain exec
(quote each argument separately) and `spawn-sh` when you need a shell (pipes, `~`,
multiple commands).

**The output startup race.** A window-rule's `open-on-workspace` can only route an
app once its target `open-on-output`-pinned workspace can resolve — which needs
that monitor **enumerated with a logical position**. Apps launched before then
have no positioned output to resolve against and collapse onto whatever's active.
The fix therefore keys on **which output an app's workspace is pinned to** — a
**login-ready** one (the primary, positioned the instant niri comes up) vs a
**late-enumerating** one (a secondary monitor, positioned _after_ login). See
[ADR 0022](adr/0022-login-ready-vs-late-enumerating-output-startup.md) and the
CONTEXT.md glossary.

- **Login-ready output → plain spawn.** The primary (`work`'s `HDMI-A-2`, `home`'s
  `HDMI-A-1`, `laptop`'s lone panel) is up at login, so the window-rule routes the
  window with no help. `zeditor` (`→ coding`) just `spawn-at-startup`s. **ghostty is
  the exception**: the output is ready, but a plain spawn silently exits 0 at boot with
  no window (a _session_-readiness race — portal/dbus still settling — not the output
  race), so it's wrapped in `dot-spawn-ghostty` (short settle delay + boot stderr/exit
  log; see below). A plain spawn also runs under niri's own `app-niri-<app>.scope`, so
  the app's stderr reaches the journal — worth having when an app fails to appear.
- **Late-enumerating output → `dot-niri-startup`.** A secondary monitor (`work`'s
  `DP-1`, `home`'s `DP-3`) enumerates after login, so launching its apps now races
  and they collapse onto its first slot. Route them through **`dot-niri-startup`**
  (`home/dot_local/bin/`, on `PATH`):

```kdl
spawn-at-startup "dot-spawn-ghostty"  // -> terminal on the login-ready primary (delay + log)
spawn-at-startup "dot-niri-startup" "DP-3" "zen-browser" "google-chrome-stable" "discord"
```

`dot-niri-startup` polls `niri msg -j outputs` until `<output>` reports a non-null
logical position, then launches each command in order with a small gap — so list
order becomes left-to-right column order (zen takes the browser's left column,
chrome the next). The poll is bounded (~30 s) so an unplugged monitor degrades to
launching anyway instead of hanging the session. A fixed `sleep` only gambles
against the display's init time on a given boot (a `sleep 3` on Teams still lost the
race after a cold boot). `work` batches its `DP-1` apps; `home` batches its `DP-3`
apps — the two boxes are structurally identical.

**Why ghostty is _not_ gated on the output** (it was, twice — see ADR 0022). The gate
keys on the output, not on "a named workspace reports that output" — an earlier version
polled for the latter, but niri doesn't surface an empty persistent workspace until a
window occupies it (chicken-and-egg), so that poll stalled. Re-basing it on output
enumeration fixed the stall but exposed the deeper error: on a **login-ready** output
the poll is a **no-op** (`gate=ready after 0 polls`, always), so gating ghostty there
guarded nothing.

**Why ghostty _is_ wrapped in `dot-spawn-ghostty`.** Dropping the gate for a plain
`spawn-at-startup "ghostty"` was tried next — and a real light→dark reboot proved it
_also_ fails: the boot ghostty exits 0 with **no window, no stderr, no coredump** ~0.5 s
in. Ruled out — output timing (both outputs were already positioned before it spawned),
single-instance (`gtk-single-instance=false`), a self-exiting shell (`command=/bin/bash`),
and a crash. What's left is a silent early exit against a session that isn't fully ready
(portal/dbus/`graphical-session.target` still settling); a hand-opened ghostty seconds
later always works, and `zeditor` survives only because its slow cold start misses the
window. So ghostty goes through
[`dot-spawn-ghostty`](../home/dot_local/bin/executable_dot-spawn-ghostty): a short
settle **delay** (a fixed nudge — we don't yet know _which_ readiness signal is missing,
and gating on the wrong one is the trap that made three earlier fixes wrong) plus a
capture of ghostty's stderr + exit code to `~/.local/state/ghostty-boot.log` so the next
boot fixes-or-explains (an early `exit rc=0` line = still reproduced). Temporary — revert
to a plain `spawn-at-startup "ghostty"` once a few boots confirm the delay holds.

`dot-niri-startup` appends a compact per-boot trace to
`~/.local/state/niri-startup.log` (a temporary diagnostic — safe to delete) so a
recurrence in the secondary batch is self-documenting instead of needing another
reboot to guess; `dot-theme-reconcile` traces the theme handoff to
`~/.local/state/theme-reconcile.log` the same way.

### window rules

`window-rule { match ... ; <actions> }` adjusts individual windows. Find an app's
`app-id` with `niri msg windows` (focus the window first). This config:

- rounds every window's corners and dims inactive windows to `opacity 0.8`;
- routes ghostty → `terminal`, VS Code → `coding`, Zen **and** Chrome → `browser`
  (zen spawns first, so it takes the first column), Slack/Teams/Discord →
  `chatting`, each `open-maximized` as appropriate;
- keeps two disabled (`/-`) examples: float Firefox PiP, and block password
  managers out of screen capture.

### binds

The full table is in [niri-keybindings.md](niri-keybindings.md). Structurally
it's grouped by intent (lifecycle, apps, capture, media, focus, move, monitors,
workspaces, layout, wheel, system) and follows the concepts rule: _focus key +
`Ctrl` = move_. Bind properties you'll see: `repeat=false` (no key-repeat),
`cooldown-ms` (rate-limit, used on the wheel), `allow-when-locked` (works on the
lock screen), `allow-inhibiting=false` (survives shortcut inhibitors),
`hotkey-overlay-title` (label in the `Mod+Shift+/` overlay).

### animations & theme include

`animations {}` is left at defaults (comments show how to slow down or disable).
The final `include "./noctalia.kdl"` pulls in the shell's theme colours and must
stay **last** so those colours win.

## Troubleshooting

| Symptom                                              | Check                                                                                                                     |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Edit didn't take effect                              | Did you `chezmoi apply`? niri reloads the rendered file.                                                                  |
| `niri validate` fails on `{{`                        | You pointed it at the `.tmpl`; use `just validate-niri`.                                                                  |
| A monitor is misplaced / wrong mode                  | `niri msg outputs`, then fix `mode`/`position`/`scale`.                                                                   |
| Render error "unknown machine profile"               | `machine` in `chezmoi.toml` isn't `work`/`laptop`/`home`.                                                                 |
| Window opened on the wrong workspace                 | `niri msg windows` → confirm the `app-id` your rule matches.                                                              |
| Empty workspace grabbed slot 1 on a monitor          | A declared workspace has no `open-on-output` on this profile — add it to `$p.ws`.                                         |
| Startup apps piled onto a secondary monitor's slot 1 | That output enumerates after login — route the apps through `dot-niri-startup <output> …`, not a bare `spawn-at-startup`. |

## References

- [Configuration: Introduction](https://github.com/niri-wm/niri/wiki/Configuration:-Introduction)
- [Configuration: Outputs](https://github.com/niri-wm/niri/wiki/Configuration:-Outputs)
- [Configuration: Layout](https://github.com/niri-wm/niri/wiki/Configuration:-Layout)
- [Configuration: Window Rules](https://github.com/niri-wm/niri/wiki/Configuration:-Window-Rules)
- [chezmoi templating](https://www.chezmoi.io/user-guide/templating/)
