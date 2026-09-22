# fastfetch

A system-info banner you run by hand with **`ff`** (an alias for `fastfetch`).
Nothing starts it automatically — not `fish_greeting`, not Ghostty's `command`,
not a niri `spawn-at-startup`. This setup swaps the auto-detected EndeavourOS logo
for a **random pre-colored ASCII logo** picked per machine, and keeps every row
answerable.

## Files

| File                                                                            | What it holds                                                          |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [`config.jsonc.tmpl`](../home/dot_config/fastfetch/config.jsonc.tmpl)           | Main config (chezmoi template): logo + modules, branches on `machine`. |
| [`executable_random-logo`](../home/dot_config/fastfetch/executable_random-logo) | Picks a random logo from the machine's subset and prints it.           |
| [`logos/pc/*.txt`](../home/dot_config/fastfetch/logos/pc/)                      | Full-size ASCII logos (desktops) — Arch variants plus personal art.    |
| [`logos/laptop/*.txt`](../home/dot_config/fastfetch/logos/laptop/)              | Compact Arch ASCII logos (laptop) — 16 columns, too narrow for art.    |

## The logo system

fastfetch renders **once and exits** — it has no ASCII animation (the only motion
it supports is a GIF via the kitty/iTerm image protocol). So "variety" here means
**a different logo each launch**, not an animation.

How it fits together:

1. `config.jsonc` sets the logo to type **`command-raw`** — fastfetch runs a
   command and uses its stdout as the logo.
2. The command is `random-logo <subset>`, where `<subset>` is `pc` or `laptop`,
   chosen by the chezmoi template from the [`machine`](../CONTEXT.md) var.
3. `random-logo` `shuf`s one `*.txt` from `logos/<subset>/` and renders it —
   either by resolving a **mask** against the current light/dark palette, or by
   interpreting a legacy file's `\e[…m` escapes with `printf %b`.
4. It then **pads every line to a fixed width** — see below.

### The fixed canvas

fastfetch sizes the logo column from its widest line and starts the module block
after it. Logos of different widths therefore **shift the whole banner sideways**
between launches: `arch-classic` (38 cols) and `arch-neon` (20 cols) used to put
the modules 18 columns apart, so the banner visibly jumped run to run.

`random-logo` fixes this by padding each line out to one width per subset —
**40 columns for `pc`, 16 for `laptop`** — measured in _visible_ columns, with the
ANSI escapes stripped from a copy purely to count.

The padding lives in **the script, not in the `.txt` files**, and that is
deliberate: `.editorconfig` sets `trim_trailing_whitespace = true` under `[*]`, so
file-side padding would be silently eaten the first time anyone opened the art in
an editor — and the alignment would break again with no visible cause.

**Width is the binding constraint; height is only a ceiling.** Art shorter than
the module block just ends early and shifts nothing. Art _taller_ than it makes
the whole banner taller, so keep it at or under **31 lines** (the module block is
32). The mask logos are 36-38 mask rows = **18-19 terminal rows**, so there is
plenty of headroom; a mask could go to 62 rows before it pushed the banner taller.

**Two file formats.** `command-raw` skips fastfetch's own `$1`–`$9` color
substitution, so a logo carries its own colour. There are two ways to write one,
and `random-logo` detects which by looking for a `#light` header on line 1.

A **mask** (preferred — [ADR 0024](adr/0024-fastfetch-logos-as-masks-with-render-time-ring-palettes.md))
is two palette lines then a grid of **one character per pixel**, each letter naming
a colour _region_ rather than a colour:

```text
#light O=#4c4f69 B=#8d939f W=#f7f2e4
#dark  O=#f8f8f2 B=#8d939f W=#f7f2e4
....OOOO....
..OOBBBBOO..
.OBBWWWWBBO.
```

Two mask rows render into **one** terminal row as a half block (`▀`/`▄`), so
pixels come out square instead of 1×2 and the art gets twice the vertical
resolution. `.` is transparent and never paints a background — the theme's
`background-image` has to show through it.

A **raw** file has no header and carries literal `\e[…m` escapes, passed through
untouched. `arch-*.txt` and `wordmark-k96.txt` are still this; they are **broken in
one mode** (`arch-gradient` runs 1.11–1.64:1 against Latte) and converting them is
open work.

### Adding or editing a logo

Drop a `*.txt` into `logos/pc/` or `logos/laptop/` and it joins the random rotation
on the next `chezmoi apply`. You do **not** need to pad it — `random-logo` handles
the canvas — but keep it within 40×31 (`pc`) or 16×31 (`laptop`) **terminal rows**;
a mask may therefore be up to 62 rows tall. Anything wider than the canvas is left
alone and will push the modules out.

Preview one, in both modes, without waiting for the rotation to pick it:

```sh
just preview-logo nuxcut
```

`random-logo` takes an optional second argument that **pins** one logo instead of
shuffling, which is what `preview-logo` uses and what you want for a screenshot:

```sh
random-logo pc yay          # or set it as logo.source in config.jsonc
```

Note it still goes through the script. `"type": "file-raw"` with a path does
**not** work for a mask — a mask is a grid of colour-region letters, so fastfetch
would print the letters.

`just validate-fastfetch` checks every mask: both palettes must exist, agree on
their key set, and match the grid. A key used in the grid but missing from the
palette renders as an **empty escape** — the region silently loses its colour while
the art still lines up, which is the same failure shape as the PUA trap above.

**Colour rules.** A **subject colour** (a penguin's black, a grizzly's brown) is
identical in both palettes — it is part of the thing depicted. A **ring colour**
exists to separate figure from ground, so it is drawn from MineScheme per mode.
Rings come in two roles because one colour cannot do both jobs: `O` separates the
figure from the **background** (and goes light in dark mode), `o` separates the
figure from its own **pale interior** (and goes dark in dark mode). Aim for ≥2.5:1
between any two regions that must be told apart — but not for deliberate shading,
which is supposed to sit below that.

### What the art should be

The logo does not have to be an Arch logo. The `OS` row already prints
`EndeavourOS x86_64`, so a distro logo on the left is repeating a fact the banner
has already stated — which is exactly what makes the stock one feel generic. The
rotation is the place for art that is actually yours.

The same reasoning rules out taglines _inside_ the art: a wordmark that also spells
out `EndeavourOS · niri · Noctalia` is repeating the `OS`, `WM` and `Desktop shell`
rows sitting right beside it.

Art is **hand-drawn**, not converted from an image. `chafa` and friends would add a
package to [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt) for a
tool used once, and dithered output on a flat-colour cartoon looks worse at 40
columns than a hand mask. The reference images under
[`images/thumbnail/`](../images/thumbnail/) are bold, flat cartoons, which is
exactly the shape that survives being redrawn by hand at this size.

`logos/laptop/` stays Arch-only: at **16 columns** an animal is no longer
recognisable, and widening that canvas would push the banner 12 columns right on
the narrowest screen in the fleet.

The `pc` rotation today — mask sizes are in **pixels**, and two mask rows render
into one terminal row, so 40 × 36 occupies 18 of them:

| File                | Subject                       | Format | Size    |
| ------------------- | ----------------------------- | ------ | ------- |
| `arch-classic.txt`  | Stock Arch logo               | raw    | 38 × 20 |
| `arch-gradient.txt` | Arch, gradient fill           | raw    | 38 × 20 |
| `arch-neon.txt`     | Arch, small neon outline      | raw    | 19 × 11 |
| `nuxcut.txt`        | Penguin face                  | mask   | 40 × 36 |
| `hungry-grizz.txt`  | Bear eating a sandwich        | mask   | 40 × 36 |
| `yay.txt`           | Three penguins under "YAY!"   | mask   | 40 × 38 |
| `wordmark-k96.txt`  | `ngockhoi96` in block letters | raw    | 39 × 8  |

**How the animals were drawn.** Freehand block art came out lopsided and ragged at
this size, so each figure is composed from geometric primitives — ellipses for a
head, a muzzle, an eye — and the result is committed **as the mask**. That is the
point of the format: the mask is what you read in a diff and what you edit to
redraw, so there is no generator to lose between sessions.

Three things that only became visible once the art was drawn at full resolution:

- **A single ring colour cannot work in dark mode.** It has to separate from the
  ground, the mid-tone body _and_ the pale face at once, which needs a luminance
  both ≤0.09 and ≥0.135. Hence the `O`/`o` split described above.
- **`hungry-grizz` is no longer mirrored.** It used to be written as a left half
  and reflected, with the generator asserting `row == row[::-1]`. No 3/4-view bear
  holding a sandwich off-centre can satisfy that, and the mask is reviewable by eye
  anyway — which is what the assertion was substituting for.
- **`yay`'s penguins are still stamped, then mirrored** — the left and centre birds
  are drawn and the right half is reflected from the left, so they cannot drift.
  The letters are excluded, since "YAY!" is not symmetric. Beware that Python's
  banker's rounding makes `round(6.5)` and `round(33.5)` land asymmetrically; the
  mirror pass is what actually guarantees it.

The generators are throwaway — the committed `.txt` is the artefact. Redrawing
means editing the mask, not the escapes.

## Per-machine differences

The config is a chezmoi template (same pattern as
[niri](niri-config.md#the-file-is-a-chezmoi-template)), so one file serves all
machines and your hostname never enters this public repo:

| `machine` | Logo subset     | Extra module |
| --------- | --------------- | ------------ |
| `work`    | `logos/pc/`     | —            |
| `home`    | `logos/pc/`     | —            |
| `laptop`  | `logos/laptop/` | `battery`    |

Everything else (CPU, GPU, disk, display…) is auto-detected, and fastfetch
silently omits hardware a machine doesn't have.

## Editing & applying

```sh
chezmoi edit ~/.config/fastfetch/config.jsonc   # opens the .tmpl
chezmoi apply                                    # renders config + logos + script
ff                                               # (alias for fastfetch)
```

Unlike niri, fastfetch has no hot-reload — just re-run `ff`. To sanity-check a
rendered config: `chezmoi execute-template < …/config.jsonc.tmpl | fastfetch -c /dev/stdin`.

## Modules

Four groups, each drawn with a colored header, a left rail and a `╰─` foot:

| Group        | Rows                                                                     |
| ------------ | ------------------------------------------------------------------------ |
| **System**   | OS · Kernel _(+ reboot flag)_ · Packages                                 |
| **Desktop**  | WM · Desktop shell · Login · Theme · Display                             |
| **Hardware** | CPU · GPU · Memory · Swap · Disk · Battery _(laptop only)_               |
| **Dev**      | Terminal · Login shell · Prompt · Font · Editor · VCS · Runtime · Deploy |

### No `Uptime` row — the Kernel row answers the real question

`Uptime` only ever _implied_ something useful ("how long since I rebooted?"), and
the question behind that is **"do I need to reboot?"** — which it never answered.
The `Kernel` row now does, for ~1 ms:

```text
7.2.6-arch2-1                                  # current — silent
7.2.4-arch1-2  󰑙 reboot → 7.2.6-arch2-1        # running kernel is stale
```

pacman **deletes** `/usr/lib/modules/<release>` when it upgrades a kernel — that
missing directory is precisely why a running-but-upgraded kernel can no longer
load modules. So the entire check is `[ -d /usr/lib/modules/$(uname -r) ]`. No
`pacman -Q` (8 ms, and it would have to guess whether you run `linux`, `-lts` or
`-zen`); the `pkgbase` file beside the modules names the flavour for free.

The flag is **silent when there is nothing to do**, so when it does appear it
means something.

### One row, one category, one icon

Every row carries **exactly one icon, in the key**, and a label that is the thing's
**actual category**. Where fastfetch's generic `{icon}` was vague, `keyIcon`
overrides it.

Getting the Dev group here took two wrong turns worth recording, because both are
tempting:

1. **Packing rows to save space.** Four rows held the whole toolchain, which meant
   filing `git` under **Editor** and `wrangler` under **Runtime**. Compact, and
   simply false.
2. **Dropping the labels and showing bare icons.** This fixed the lying labels by
   deleting them, and produced a column of glyphs and version numbers that nobody
   could read — least of all a stranger hitting a screenshot from a public repo.

Both failures have the same root: the row label was being asked to do something
other than name the thing. So now `git` is **VCS**, `wrangler` is **Deploy**, and
`starship` is **Prompt**.

`Runtime` is the one row holding several tools — and that is not packing, because
node, go and bun genuinely _are_ all language runtimes. Group only where the
category is truly shared.

The single exception to "one icon per row" is **Theme**, which carries an icon in
its value as well (`󰖙` / `󰖔`). That icon is **state** — it flips with `darkman` —
not identity, and a static `keyIcon` cannot express it. Every other icon here is
fixed at config time. (Nerd Fonts has no real Catppuccin or Dracula glyph anyway,
so a brand icon there would have been an invented metaphor carrying no
information.)

### `Desktop shell` and `Login shell`, both spelled out

[`CONTEXT.md`](../CONTEXT.md) defines these as two unrelated things that both get
called "shell": the **desktop shell** is Noctalia, the **login shell** is fish.
Both are now on screen — Noctalia in `Desktop`, fish in `Dev` — so neither can
lean on its group header to disambiguate, and both use the full glossary term.

An earlier version labelled the Noctalia row just `Shell`, which worked only while
fish had no row of its own. Renaming the group to `Session` was also considered
and rejected: `CONTEXT.md` reserves "session" for the login/Wayland/systemd trio
and zellij's **Multiplexer session**, so it would trade one banned bare term for
another.

`Desktop shell` is 13 characters, which is what sets the key width below.

### Icons are written as `\uXXXX`, never typed

Every `keyIcon` in the config is an escape with a `// U+XXXX` comment beside it,
because this config has already been broken once by the Private Use Area trap
that [starship](starship.md#the-private-use-area-trap) documents.

A PUA glyph **inside the BMP** (`U+E000`–`U+F8FF`) is silently eaten by anything
that re-encodes the file. The result is not an error — it is an empty string that
parses fine, lints clean, and renders nothing:

```jsonc
"keyIcon": "",  // U+E795  Terminal   ← survives anything
"keyIcon": "",        // what a typed  became
```

It cost five rows here — `Kernel`, `Theme`, `Terminal`, `VCS`, `Deploy` — and the
symptom looked like two unrelated bugs: missing icons _and_ misaligned columns.
They were one bug. A missing icon shortens the key, so those five values sat a
column to the left of every other row.

Note which icons survived: only the ones above `U+F0000` (`󰗟`, `󰌈`, `󱖮`…), which
sit outside the BMP and are written as surrogate pairs. That uneven survival is
what makes the failure so easy to miss — most of the banner still looks right.

`just validate-fastfetch` now fails on either shape: an empty `keyIcon`, or a
literal BMP PUA character anywhere in a string value.

### The 13-column key

Every label in **all four groups** is padded to exactly 13 columns, so the values
line up in one straight column down the entire banner. That single column is most
of why the banner reads as one object rather than four stacked tables.

Adding a label longer than 13 means **repadding every key in the file**, not just
that group's — per-group widths would break the value column into visible steps.
This is also why `Prompt` is not `Cross-shell prompt` (18) and `Font` is not
`Terminal font`: sitting directly under `Login shell`, the short forms are already
unambiguous, and the longer ones would cost five columns of whitespace on every
row of the other three groups.

### One GPU row

Hybrid graphics emit one row **per adapter**, so this desktop listed both the
RTX 2060 and the i7's UHD 770 — a second row that never changes and never matters.
`"hideType": "integrated"` drops it, but only on `pc` profiles: on a laptop with
integrated graphics only, hiding it would silently delete the GPU row entirely.
Hence the same `$isLaptop` branch the `battery` row already uses.

Group colors are **ANSI names** (`{#blue}`, `{#bold_green}`…), not hex, so they
follow Ghostty's `theme = light:latte,dark:dracula` switch for free — the same
reasoning as [starship](starship.md). Valid codes are `{#<name>}`, `{#bold_<name>}`
and `{#}` for reset; there is **no `{#reset}`** (fastfetch errors out on it).

Browse more modules with `fastfetch --list-modules`.

### The layout rule: no absolute cursor escapes

The right-hand side of every group is **deliberately open** — no right border, no
closed box. That is not a style choice, it is what keeps the layout from breaking.

Aligning a right border requires knowing where the value ends, and the only way to
express that in fastfetch is an **absolute cursor move** — `\u001b[46C` (right N
columns) or `\u001b[46G` (go to column N). The moment a value outgrows the column
those assume, the cursor is already past it and the escape pushes the border
outside the box, or drags it backwards over text. A 56-character CPU name is
enough to do it.

The same trap hides in **`display.key.width`**: it is implemented as `\u001b[NG`,
so a key longer than the width makes the value overwrite the key —
`Packages` renders as `Packag1026 (pacman · yay)`. It is not used here.

So: key columns are aligned by **padding the key strings with plain spaces**, and
nothing else positions anything. To check a change kept this property:

```sh
fastfetch --logo none | cat -v | rg '\^\[\[[0-9]*[GCD]'   # must print nothing
```

(The logo files themselves are exempt — their escapes are colors, not motion.)

### Cost

`ff` is a command you **type**, not a shell-start banner — so the budget is "feels
instant" (~150 ms), not the ~25 ms an on-every-prompt banner would need. Measured
total is ≈ **38 ms** — the kernel check is free, and splitting Dev from four rows
into eight cost about 5 ms in extra `command` module shells.

Cheap is still preferred wherever it costs nothing in usefulness:

| Wanted            | Obvious way          | Cost   | Used instead                                 |
| ----------------- | -------------------- | ------ | -------------------------------------------- |
| wrangler version  | `wrangler --version` | 477 ms | `sed` on mise's `wrangler/package.json`      |
| mise version      | `mise --version`     | 208 ms | dropped — the runtimes it manages are shown  |
| repo vs AUR count | `pacman -Qm`         | 134 ms | static `(pacman · yay)` label                |
| ghostty version   | `ghostty --version`  | 30 ms  | `$TERM_PROGRAM_VERSION` (ghostty exports it) |
| reboot needed?    | `pacman -Q linux`    | 8 ms   | `[ -d /usr/lib/modules/$(uname -r) ]` (1 ms) |

Anything added here should be measured the same way before it goes in:

```sh
s=$(date +%s%N); fastfetch --logo none >/dev/null; e=$(date +%s%N); echo $(( (e-s)/1000000 ))ms
```

## Gotchas

**Screenshots must come from a real Ghostty window.** fastfetch identifies the
terminal by walking the **parent process tree**, so running `ff` from inside
another program reports `Unknown terminal: <that program>` and the `Font` row
vanishes without an error:

```sh
$ fastfetch -s terminalfont --logo none --format json
[ { "type": "TerminalFont", "error": "Unknown terminal: claude" } ]
```

The row is fine; the _wrapper_ is what it cannot see through.

**There is no ASCII animation, and there is no way to add one.** Two independent
blockers:

1. Ghostty does not implement the Kitty graphics protocol's **animation frames**
   (`a=f` / `a=a`) — [ghostty#5218](https://github.com/ghostty-org/ghostty/discussions/5218),
   [#5350](https://github.com/ghostty-org/ghostty/discussions/5350). Static images
   have worked since 1.0; animated ones have not.
2. More fundamentally, `fastfetch` **renders once and exits**. Animating ASCII
   needs a process that stays alive redrawing frames, which would mean `ff` hangs
   the terminal it just decorated until you hit Ctrl-C.

What this setup has instead is one frame per invocation: `random-logo` deals a
different card each run. If you ever want real motion, it belongs in a _separate_
command, not in `ff`.

## References

- [fastfetch wiki](https://github.com/fastfetch-cli/fastfetch/wiki)
- [Logo options](https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options)
- [JSON schema / config](https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema)
- Logo inspiration: [LierB/fastfetch](https://github.com/LierB/fastfetch),
  [sofijacom/dotfiles-fastfetch](https://github.com/sofijacom/dotfiles-fastfetch),
  [ad1822/hyprdots](https://github.com/ad1822/hyprdots)
