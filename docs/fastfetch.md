# fastfetch

A system-info banner shown on shell start (aliased to `ff`). This setup swaps the
auto-detected EndeavourOS logo for a **random pre-colored Arch ASCII logo** picked
per machine, and keeps the module list lean.

## Files

| File                                                                            | What it holds                                                          |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [`config.jsonc.tmpl`](../home/dot_config/fastfetch/config.jsonc.tmpl)           | Main config (chezmoi template): logo + modules, branches on `machine`. |
| [`executable_random-logo`](../home/dot_config/fastfetch/executable_random-logo) | Picks a random logo from the machine's subset and prints it.           |
| [`logos/pc/*.txt`](../home/dot_config/fastfetch/logos/pc/)                      | Full-size Arch ASCII logos (desktops).                                 |
| [`logos/laptop/*.txt`](../home/dot_config/fastfetch/logos/laptop/)              | Compact Arch ASCII logos (laptop).                                     |

## The logo system

fastfetch renders **once and exits** — it has no ASCII animation (the only motion
it supports is a GIF via the kitty/iTerm image protocol). So "variety" here means
**a different logo each launch**, not an animation.

How it fits together:

1. `config.jsonc` sets the logo to type **`command-raw`** — fastfetch runs a
   command and uses its stdout as the logo.
2. The command is `random-logo <subset>`, where `<subset>` is `pc` or `laptop`,
   chosen by the chezmoi template from the [`machine`](../CONTEXT.md) var.
3. `random-logo` `shuf`s one `*.txt` from `logos/<subset>/` and prints it,
   interpreting the `\e[…m` escapes with `printf %b`.

**Why the escapes live in the files.** `command-raw` skips fastfetch's own
`$1`–`$9` color substitution, so the logos carry their own ANSI color codes as
plain text (`\e[1;34m`, `\e[38;5;51m`, …). They stay human-readable in git and get
interpreted at runtime. Trade-off: colors are baked per file, so they don't track
Catppuccin theme switches — see [ADR 0006](adr/0006-per-machine-niri-via-chezmoi-template.md)
for why this (and not fish-side logic) was chosen.

### Adding or editing a logo

Drop a `*.txt` into `logos/pc/` or `logos/laptop/`. Prefix lines with an ANSI
color escape and it joins the random rotation on the next `chezmoi apply`:

```text
\e[1;36m      /\
\e[1;36m     /  \
\e[1;34m  / /____\ \
\e[0m
```

Preview one without fastfetch:

```sh
printf '%b' "$(cat ~/.config/fastfetch/logos/pc/arch-gradient.txt)"
```

Common escapes: `\e[1;34m` bold blue, `\e[1;36m` bold cyan, `\e[38;5;Nm` 256-color
(N = 51 cyan, 75 blue, 111 light-blue, 201 magenta), `\e[0m` reset (end every
file with it).

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

| Group        | Rows                                                       |
| ------------ | ---------------------------------------------------------- |
| **System**   | OS · Kernel · Packages · Uptime                            |
| **Desktop**  | WM (niri) · Shell (Noctalia) · Login · Theme · Display     |
| **Hardware** | CPU · GPU · Memory · Swap · Disk · Battery _(laptop only)_ |
| **Dev**      | Terminal stack · Font · Editor · Runtime                   |

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

`ff` runs on every shell start, so each row is checked for cost. Total ≈ **25 ms**.
Cheaper substitutes were chosen deliberately:

| Wanted            | Obvious way          | Cost   | Used instead                                 |
| ----------------- | -------------------- | ------ | -------------------------------------------- |
| wrangler version  | `wrangler --version` | 477 ms | `sed` on mise's `wrangler/package.json`      |
| mise version      | `mise --version`     | 208 ms | dropped — the runtimes it manages are shown  |
| repo vs AUR count | `pacman -Qm`         | 134 ms | static `(pacman · yay)` label                |
| ghostty version   | `ghostty --version`  | 30 ms  | `$TERM_PROGRAM_VERSION` (ghostty exports it) |

Anything added here should be measured the same way before it goes in.

## References

- [fastfetch wiki](https://github.com/fastfetch-cli/fastfetch/wiki)
- [Logo options](https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options)
- [JSON schema / config](https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema)
- Logo inspiration: [LierB/fastfetch](https://github.com/LierB/fastfetch),
  [sofijacom/dotfiles-fastfetch](https://github.com/sofijacom/dotfiles-fastfetch),
  [ad1822/hyprdots](https://github.com/ad1822/hyprdots)
