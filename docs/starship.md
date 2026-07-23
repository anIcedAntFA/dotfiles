# starship — the shell prompt

## Why

[starship](https://starship.rs/) is a cross-shell prompt written in Rust. It
renders modules in parallel and only shows a module when the current directory
actually calls for it, so the prompt stays quiet in a plain folder and fills in
detail inside a project.

`config.fish` sets `STARSHIP_CONFIG` to `~/.config/starship/starship.toml` (the
non-default path) and runs `starship init fish | source`. Source file:
[`home/dot_config/starship/starship.toml.tmpl`](../home/dot_config/starship/starship.toml.tmpl).

## The prompt is a sentence

The left side reads as prose, using starship's own connectors:

```text
alice at box …/webapp on  hotfix/revert-svg via  v22.19.0 via ❄ impure (nix-shell-env) on  ap-northeast-1
➜ git push
```

Those connectors are not decoration — each module ships with one, and they differ
by kind:

| Kind                                                | Connector | Reads as         |
| --------------------------------------------------- | --------- | ---------------- |
| `hostname`                                          | `at`      | `at box`         |
| `git_branch`, `aws`, `gcloud`                       | `on`      | `on  main`      |
| runtimes (node, bun, go, python, rust, nix, docker) | `via`     | `via  v22.19.0` |
| `package`                                           | `is`      | `is 󰏗 v1.2.8`    |

**This is why the config sets almost no `format` keys.** Leave `format` alone and
every module — all 50-odd of them — phrases itself consistently. Override it on
some modules but not others and the sentence breaks in half. An earlier version of
this config did exactly that:

```text
[ v22.19.0]via ❄ impure (nix-shell-env) [☁  (ap-northeast-1)]
└─ overridden ┘└──── default ─────────┘└──── overridden ────┘
```

Three modules, two styles, jammed together with no space at `]via`. The prose
"via" that looked deliberate was simply the modules nobody had got around to
overriding yet.

### Shortening the hostname

A hostname shaped like `<user>-<org>` makes the opening of every prompt repeat
itself — `alice at alice-acme` — and drags an organisation tag along. The
`[hostname.aliases]` table maps the real hostname to a short label:

<!-- dprint-ignore -->

```toml
[hostname.aliases]
"alice-acme" = "box"     # → "alice at box"
```

`trim_at` cannot do this. It keeps the text _before_ the separator, so
`trim_at = '-'` on `alice-acme` yields `alice` — the half you already have.

This is the one templated part of the config, which is why the source file is
`starship.toml.tmpl`. The real hostname must not enter a public repo, so the
label is prompted by [`.chezmoi.toml.tmpl`](../home/.chezmoi.toml.tmpl) as
`hostAlias` and stored only in the untracked `~/.config/chezmoi/chezmoi.toml`
(see [chezmoi.md](chezmoi.md) and [ADR 0002](adr/0002-private-data-via-templates.md)).

The key is `{{ output "hostname" | trim }}`, **not** `{{ .chezmoi.hostname }}`.
chezmoi derives its own `hostname` from a reverse-DNS lookup, which on a VPN
answers with the network's name for the machine — here `local`, with FQDN
`local.<corp domain>` — rather than the kernel hostname starship reads. The
alias key must match `gethostname()` exactly or it silently does nothing, and
the DNS form would also drag a corporate domain into the rendered file.

### The right side is not part of the sentence

`right_format` carries `status`, `cmd_duration`, `battery` and `time` — things
that report on the command that just finished, not on where you are. These are the
only modules whose `format` **is** overridden, swapping the prose connector for a
glyph, because `took 11s` and `at 17:24` floating alone at the right margin are
connectors with nothing to connect to.

`format = '$all'` handles the left side. `$all` renders every module in starship's
canonical order **and excludes anything named in `right_format`**, so nothing
appears twice and any module starship adds in future joins the sentence
automatically.

## Symbols

The symbol block at the bottom of the config is generated, never hand-typed —
`starship preset nerd-font-symbols` piped straight into the file. Symbol only,
no `format`, no `style`. Regenerate it with:

```fish
starship preset nerd-font-symbols
```

Keeping the full preset (rather than only the languages in use) means an
unfamiliar project still gets a proper glyph instead of starship's plain-text
fallback, at zero runtime cost — a module that does not match the directory never
runs. Piping rather than retyping is not fussiness; see the Private Use Area
trap below for what happens otherwise.

The only edits to that block are five `style` lines, each marked `# was NNN`.
starship's default styles are ANSI colour names nearly everywhere, but `c`, `cpp`,
`php`, `package` and `terraform` ship with 256-colour indices, which are fixed RGB
and ignore the theme. See
[ADR 0009](adr/0009-starship-ansi-colours-over-hex-palette.md).

## Git

Four modules cover the repository, and between them every state git can report
has a symbol.

### `git_status` — all twelve states

| Codepoint | Glyph         | Meaning                            |
| --------- | ------------- | ---------------------------------- |
| `U+F071`  |  warning     | conflicted — unresolved merge      |
| `U+F067`  |  plus        | staged                             |
| `U+F044`  |  edit        | modified, not staged               |
| `U+F128`  |  question    | untracked                          |
| `U+F1F8`  |  trash       | deleted                            |
| `U+F061`  |  arrow-right | renamed or moved                   |
| `U+F0EC`  |  exchange    | type changed, e.g. file → symlink  |
| `U+F187`  |  archive     | stash entries                      |
| `U+21E1`  | ⇡             | ahead — local commits not pushed   |
| `U+21E3`  | ⇣             | behind — remote commits not pulled |
| `U+21D5`  | ⇕             | diverged — history has forked      |
| —         | (nothing)     | up to date; the branch shows alone |

`typechanged` is easy to miss: its starship default is an empty string, so
without an explicit value that state is permanently invisible.

Emoji were considered and rejected. Measured, they occupy twice the width (12
terminal columns for six symbols against six) and they ignore `style` entirely —
they carry their own fixed colours, so the "this repo is dirty" red never
reaches them, and they clash with the monochrome glyphs on either side. See
[ADR 0009](adr/0009-starship-ansi-colours-over-hex-palette.md).

### `git_state` — the half-finished, dangerous states

Icon _and_ word, because nobody memorises seven rare glyphs and the moment this
matters is the moment you are lost mid-rebase:

```text
( REBASING 3/7)   ( MERGING)   ( REVERTING)   ( CHERRY-PICKING)
( BISECTING)      ( AM)        ( AM/REBASE)
```

### `git_commit` — detached HEAD

Only speaks up when `git_branch` has no branch to show, which is exactly when
you most need to know where you are. Tags are enabled so the answer is a name
when one exists:

```text
…/repo on  HEAD ( 6694932  v1.0.0)
```

### `git_metrics` — lines changed

Off in starship by default, enabled here. Measured at 8-10ms, the most expensive
module in this prompt though still inside the ~20ms budget; note it pays that
cost even on a clean tree, where it prints nothing.

## Exit status

The prompt character turns red on failure (colour says _something_ failed) while
the `status` module on the right names it (text says _what_ failed):

```text
✘ ERROR      exit 1
✘ USAGE      exit 2
 NOPERM     exit 126
 NOTFOUND   exit 127
✋ INT        SIGINT (Ctrl-C)
⚡ KILL       SIGKILL
⚡ SEGV       SIGSEGV
```

`map_symbol = true` is what turns 130 into `SIGINT`. It also pulls in starship's
per-case default symbols, several of which are emoji — sigint is 🧱 out of the box.
Emoji carry their own fixed colours and ignore the palette, so every one is
overridden with a glyph.

## The quoting trap

This is the one thing to know before editing the file.

Escape sequences work in TOML **basic** strings (double quotes) and are kept
verbatim in **literal** strings (single quotes). Starship's format parser then
fails on the stray backslash:

<!-- dprint-ignore -->

```toml
discharging_symbol = '\U0001f4a6'   # ✗ literal string → parser error
discharging_symbol = "\U0001f4a6"   # ✓ basic string   → 💦
```

The failure is quiet and conditional — the module has to actually render before
the parser sees the bad string. A previous version of this config had the whole
`git_status` symbol set in single quotes, so the prompt silently printed no git
status in every dirty repo, and battery threw a warning only once the charge
dropped below 30%. Both looked like starship bugs; both were quoting.

Rule: **any value containing a backslash escape uses double quotes.**

### The Private Use Area trap

The same rule has a second, nastier form. Most Nerd Font glyphs live in the
Private Use Area, `U+E000`–`U+F8FF`. Those codepoints survive a byte-exact copy
but are silently dropped by anything that re-encodes the text along the way. The
result is a config that parses cleanly, passes every lint, and shows nothing:

<!-- dprint-ignore -->

```toml
symbol = " "        # what you meant:  (U+F418)
symbol = " "         # what got written: one space
```

This happened here to 40 of 47 preset symbols at once. Only the handful above
`U+F0000` — rust, package, meson — came through, because they sit outside the
BMP. The prompt looked _almost_ right, which is why it survived a review: the
spacing was intact, so nothing was obviously missing except the icons.

Two defences, both used in this config:

1. **Never retype glyphs.** The symbol block is piped straight from
   `starship preset nerd-font-symbols` into the file. Regenerate, don't edit.
2. **Everywhere else, write `\uXXXX`.** An escape is plain ASCII, so nothing can
   eat it, and the codepoint stays greppable. Each one carries a `# U+XXXX`
   comment.

To audit a config for this, look for values that are only whitespace:

```fish
rg '= "\s*"' ~/.config/starship/starship.toml
```

And to confirm your font actually has a codepoint before using it:

```fish
fc-query --format '%{charset}\n' (fc-match -f '%{file}' "JetBrainsMono Nerd Font")
```

## Cost of a module

Modules that spawn a process are expensive; modules that check for a file are
free. Measure, never assume:

```fish
starship timings          # per-module cost in the current directory
starship explain          # what each visible segment means
starship module <name>    # render one module in isolation
STARSHIP_LOG=trace starship module <name>   # see the commands it runs
```

Two decisions came from that command:

- **`custom.cloudflare` has no `command`.** Gating on `detect_files` costs <1ms
  and shows nothing outside a Worker repo. Adding `command = "…"` — even
  `echo` — cost ~51ms per prompt, because it spawns a shell.
- **There is no `mise` module.** It shells out to `mise doctor`, measured at
  ~230ms, several times the cost of everything else combined. The runtime modules
  already report the versions mise resolves, which is the part that changes.

For comparison, this prompt's slowest module in a real project is `git_status` at
about 5ms.

## Adding a language

Usually nothing to do — the preset already covers 52 modules and the default
format supplies the connector. For something outside the preset, one line:

<!-- dprint-ignore -->

```toml
[gleam]
symbol = " "
```

Do **not** add a `format`; that is what breaks the sentence. Add a `style` only if
the default is a 256-colour index or hex rather than an ANSI name — check with
`starship print-config`.

## Troubleshooting

- **`expected escaped_char` in a warning** — a single-quoted string containing a
  backslash escape. See the quoting trap above.
- **`duplicate key` on startup** — a module is declared twice, easy to do when
  adding a `style` override separately from the preset's symbol block. Merge them
  into one table.
- **A module never appears** — it is context-gated. Confirm with
  `starship module <name>` in a directory that should trigger it; if that is empty
  too, the marker file is missing or the tool is not on `PATH`.
- **A module appears twice** — it is named in `right_format` _and_ explicitly in
  `format`. Use `$all` and let it do the exclusion.
- **The prompt feels slow** — run `starship timings`. Anything over ~20ms is
  almost always a module running a command.
- **Colours look wrong after a theme switch** — check for a hex or 256-colour
  value that should be an ANSI name; see
  [ADR 0009](adr/0009-starship-ansi-colours-over-hex-palette.md).
- **Boxes instead of glyphs** — the terminal font is not a Nerd Font. Ghostty's is
  set in [ghostty.md](ghostty.md).

## References

- [starship configuration](https://starship.rs/config/) — every module and option
- [Nerd Font symbols preset](https://starship.rs/presets/nerd-font) — the symbol block
- [TOML string types](https://toml.io/en/v1.0.0#string) — the basic vs literal distinction
