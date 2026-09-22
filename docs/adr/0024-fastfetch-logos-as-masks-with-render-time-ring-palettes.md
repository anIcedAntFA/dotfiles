# fastfetch logos are masks with render-time ring palettes

**Status:** accepted (2026-09-21) · narrows [ADR 0023](./0023-starship-ansi-colours-over-hex-palette.md) · complements [ADR 0021](./0021-tiered-app-theming-minescheme-identity.md)

A banner logo is committed as a **mask** — one character per pixel, each letter
naming a colour region — plus a two-line palette header. `random-logo` reads the
current mode, resolves the mask against the matching palette, and emits half-block
(`▀`/`▄`) truecolor escapes at render time. **Subject colours** (a penguin's black,
a grizzly's brown) are identical in both modes; only the **ring colour** — the
outline that separates figure from ground — comes from MineScheme per mode.

## Why this is not a violation of ADR 0023

0023 says every starship style must name an ANSI colour, and its consequences
extend that: _"256-colour indices fall under the same rule as hex… Any future
module must be styled with an ANSI name."_ Taken literally that forbids this
design, so the distinction has to be written down.

**0023 governs output whose producer cannot detect the mode.** Starship "exposes a
single static `palette` key and no hook for the desktop mode… Whatever it renders
has to be correct in **both** themes at once, because it will never be told which
one is active." Delegating to palette slots 0–15 is the only escape from that box.
`random-logo` is not in the box: it is a script we own that already runs on every
`ff` and already transforms the art (it pads the canvas). It can simply ask.

**And ANSI names do not work here anyway** — evidence 0023 did not have. Slots
0–15 give theme-_consistent_ hues, not luminance _inversion_:

| slot             | Latte     | Dracula   |
| ---------------- | --------- | --------- |
| `color0` (black) | `#5c5f77` | `#21222c` |
| `color7` (white) | `#acb0be` | `#f8f8f2` |

`color0` is dark in **both** themes, so an ANSI-named outline still vanishes on
Dracula's `#282a36`. The mechanism works for starship because it colours **thin
glyphs in mid-tone hues**; a filled 40-column figure needs real contrast against
the ground. 0023's rule is sound in its own domain and simply does not reach this
one.

The measured damage from ignoring the problem, on the art as it stood:

```text
yay.txt   236 #303030  latte 11.67 ok    dracula  1.08 FAIL  ← letters + bodies
          238 #444444  latte  8.61 ok    dracula  1.46 FAIL  ← outlines
          255 #eeeeee  latte  1.03 FAIL  dracula 12.27 ok    ← bellies
```

In Dracula `yay` was a black-on-black void; only the bellies and beaks survived,
floating with no penguin around them. Five of the seven logos failed in one mode
or the other.

## Where this sits in the tier model

ADR 0021's taxonomy puts this in **Tier A — own config**, beside `auto-sync-theme`
and starship: the config follows the mode itself, and nothing external drives it.
It is explicitly **not Tier C** (a darkman hook), which matters because 0019
records that darkman "runs every executable in `~/.local/share/darkman/`, so adding
a hook needs a `darkman` restart before it is picked up" — a banner should not
require that.

Reading `org.gnome.desktop.interface color-scheme` respects ADR 0019: darkman is
the single **writer** and scheduler of that key; this is a read, at 4.4 ms.

## Considered options

- **Mask + render-time ring palette** — chosen. One art source serves both modes,
  the committed file is legible in a diff, and the half-block fg/bg pairing is
  computed once in the renderer instead of hand-authored ~2,500 times per logo.
  Cost: `random-logo` grows a renderer, and a `.txt` is no longer directly
  `printf %b`-able. Measured over 100 renders the logo step goes **9.6 ms → 23.0
  ms**, taking the banner from ~34 ms to **~47 ms** against a ~150 ms budget. Most
  of the delta is the `dconf` read plus its subshell, not the rendering.
- **ANSI colour names, per 0023's letter** — rejected on the evidence above: slots
  0–15 do not invert, so the figure still disappears in one mode.
- **One baked palette with a contrast floor ≥2.5:1 against both grounds** —
  rejected. It works, needs no machinery at all, and was the close runner-up. But
  clearing the floor on `#eff1f5` _and_ `#282a36` simultaneously forces every value
  to a mid-tone: no true black, no true white. The art would be washed out in both
  modes and correct in neither, and subject colours would stop being subject
  colours.
- **Two masks, `logos/pc/light/` and `logos/pc/dark/`** — rejected: doubles the art
  to maintain and guarantees the two drift.
- **Keep escapes, add a mode swap by `sed`** — rejected. It preserves the property
  that caused this rework: the committed file is unreadable, so the real source is
  a throwaway generator that gets lost between sessions. It already happened once.
- **`chafa` / image conversion** — rejected, as in `docs/fastfetch.md`: a pacman
  dependency for a one-shot tool, and dithered output on flat-colour cartoons looks
  worse at 40 columns than a hand mask.

## Consequences

- **`docs/fastfetch.md`'s "human-readable in git" claim becomes true.** It argued
  against `chafa` on that ground while the committed files were walls of `█` and
  `\e[38;5;137m`. The mask is what that sentence was always describing.
- **The mirror-symmetry guard on `hungry-grizz` is gone.** It asserted
  `row == row[::-1]`, which no 3/4-view subject holding a sandwich can satisfy. A
  mask is reviewable by eye, which is what the guard was substituting for.
- **New art needs a palette header**, so "drop a `.txt` in and it joins the
  rotation" now carries a requirement. The renderer is **dual-format** — a file
  with no `#light` header is passed through as raw escapes — so `arch-*` and
  `wordmark-k96` keep working untouched. They are still broken in one mode
  (`arch-gradient` runs 1.11–1.64:1 in Latte); converting them is follow-up work
  this ADR licenses but does not do.
- **Truecolor, not 256-index.** `38;5;N` cannot express `#6272a4`; the renderer
  emits `38;2;R;G;B`.
- **Ring luminance is tuned per logo against two grounds**, not set globally —
  per-logo work whenever art is added.
- Reversing is mechanical but touches every logo file plus the renderer.
