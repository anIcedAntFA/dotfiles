# Starship styles use ANSI colour names, not a hex palette

**Status:** accepted

Ghostty is configured `theme = light:latte,dark:dracula` and swaps its palette the
moment the desktop light/dark preference changes; zellij mirrors it with
`theme_dark`/`theme_light`. Starship has no equivalent — it exposes a single
static `palette` key and no hook for the desktop mode. Whatever it renders has to
be correct in **both** themes at once, because it will never be told which one is
active.

So every `style` in [`starship.toml.tmpl`](../../home/dot_config/starship/starship.toml.tmpl)
names an ANSI colour (`red`, `cyan`, `purple`, `bright-black`, …) instead of a hex
value. ANSI names are resolved by the terminal against palette slots 0–15, which
Ghostty already defines for both themes. The prompt therefore tracks the desktop
mode for free, with no `[palettes]` block and no template.

Two brand marks are deliberate exceptions and carry hex: the bun symbol
(`#f9f1e1`) and the Cloudflare badge (`#f6821f`). A logo colour is an identity, not
a theme colour — it _should_ look the same in Latte and Dracula, the way the actual
logos do. Both are commented in place so the inconsistency reads as a decision
rather than an oversight.

## Considered options

- **ANSI colour names** — chosen. Follows the light/dark swap automatically, keeps
  the file free of a palette block, and stays readable to anyone who has seen a
  terminal colour before. Cost: the exact shade is out of our hands — it is
  whatever Dracula and Latte assign to that slot — so fine-grained contrast tuning
  (e.g. two adjacent shades of blue) is not possible.
- **`[palettes.dracula]` with exact hex** — rejected. Gives precise control and
  matches how the Ghostty theme files are written, but pins the prompt to one mode.
  In Latte, Dracula's `#8be9fd` cyan on a `#eff1f5` background is close to
  unreadable. Starship cannot re-read the palette on a mode change, so there is no
  version of this that degrades gracefully.
- **Two palettes plus a chezmoi template** — rejected. `chezmoi apply` renders at
  _apply_ time; the desktop mode changes at _runtime_. The template would freeze
  whichever mode happened to be active during the last apply, which is strictly
  worse than the status quo because it looks deliberate.
- **A wrapper that rewrites `starship.toml` on mode change** — rejected as
  disproportionate. It means a daemon watching the desktop preference and
  rewriting a config file to change the colour of a prompt, plus a new failure mode
  when the two drift out of sync.

## Consequences

- No `[palettes]` table and no `palette` key in `starship.toml`; a reader expecting
  one should find this ADR through the comment block at the top of that file.
- Prompt colours change meaning slightly between themes — `yellow` is Dracula's
  `#f1fa8c` and Latte's `#df8e1d`. Both read as "yellow"; neither was chosen here.
- Any future module must be styled with an ANSI name. Reaching for hex is the
  signal to either pick an ANSI name or document a brand-mark exception.
- Emoji are avoided in styled positions for the same reason: they carry their own
  fixed colours and ignore the palette entirely. This is why `status.map_symbol`
  has all of its emoji defaults overridden with glyphs.
- 256-colour indices fall under the same rule as hex: index 16–255 is a fixed RGB
  value, not a palette slot, so it does not follow the theme either. starship's
  own defaults are ANSI names nearly everywhere, but `c`, `cpp`, `php`, `package`
  and `terraform` ship with indices (`149`, `147`, `208`, `105`); each is remapped
  to the nearest ANSI name and marked `# was NNN` so the diff against the upstream
  preset stays legible.
- Reversing is mechanical but touches every module: define a palette, then rewrite
  each `style` line.
