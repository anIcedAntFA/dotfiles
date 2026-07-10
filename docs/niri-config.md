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
    "home"   (dict "cursor" 48 "gaps" 12 "ws" (dict)) -}}
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

On `work`, `terminal`/`coding` pin to the portrait monitor and
`browser`/`chatting`/`tools` to the landscape one. On single-monitor `laptop`,
`$p.ws` is empty so no pinning is emitted and the names still exist.

### startup

`spawn-at-startup` launches the shell (`qs -c noctalia-shell`), terminal, and
browser on every machine. Slack + Teams are wrapped in `{{ if eq $machine "work"
}}` so they only autostart on the office box. Use `spawn` for a plain exec
(quote each argument separately) and `spawn-sh` when you need a shell (pipes,
`~`, multiple commands).

### window rules

`window-rule { match ... ; <actions> }` adjusts individual windows. Find an app's
`app-id` with `niri msg windows` (focus the window first). This config:

- rounds every window's corners and dims inactive windows to `opacity 0.8`;
- routes ghostty → `terminal`, VS Code → `coding`, Zen → `browser`, Slack/Teams →
  `chatting`, each `open-maximized` as appropriate;
- floats the `tuxedo` todo TUI at a fixed size (launched with a custom app-id so
  this rule can catch it — see [tuxedo.md](tuxedo.md));
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

| Symptom                                | Check                                                        |
| -------------------------------------- | ------------------------------------------------------------ |
| Edit didn't take effect                | Did you `chezmoi apply`? niri reloads the rendered file.     |
| `niri validate` fails on `{{`          | You pointed it at the `.tmpl`; use `just validate-niri`.     |
| A monitor is misplaced / wrong mode    | `niri msg outputs`, then fix `mode`/`position`/`scale`.      |
| Render error "unknown machine profile" | `machine` in `chezmoi.toml` isn't `work`/`laptop`/`home`.    |
| Window opened on the wrong workspace   | `niri msg windows` → confirm the `app-id` your rule matches. |

## References

- [Configuration: Introduction](https://github.com/niri-wm/niri/wiki/Configuration:-Introduction)
- [Configuration: Outputs](https://github.com/niri-wm/niri/wiki/Configuration:-Outputs)
- [Configuration: Layout](https://github.com/niri-wm/niri/wiki/Configuration:-Layout)
- [Configuration: Window Rules](https://github.com/niri-wm/niri/wiki/Configuration:-Window-Rules)
- [chezmoi templating](https://www.chezmoi.io/user-guide/templating/)
