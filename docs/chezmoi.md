# chezmoi — how these dotfiles are managed

[chezmoi](https://www.chezmoi.io/) is what turns this repo into your live `$HOME`.
This guide is the practical "how I actually use it day to day" — for _why_ we chose
it, see [ADR 0001](adr/0001-adopt-chezmoi.md) and [0002](adr/0002-private-data-via-templates.md).

## The mental model: three states

chezmoi always reasons about three things:

| State            | Where                                  | In this repo                                   |
| ---------------- | -------------------------------------- | ---------------------------------------------- |
| **Source state** | the git repo                           | `home/` (that's what `.chezmoiroot` points at) |
| **Target state** | what chezmoi _computes_ home should be | source rendered through templates + your data  |
| **Destination**  | your actual `$HOME`                    | the real files on disk                         |

Every command is some flavour of "compare two of these and reconcile them":

```text
  edit source ─┐                        ┌─ chezmoi apply ─► overwrites $HOME
   (home/…)    │  chezmoi diff/status   │
              ▼         (compare)       ▼
        SOURCE  ◄── chezmoi add/re-add ── DESTINATION ($HOME)
```

The single most important thing to internalise: **you never edit `~/.config/foo`
and expect the repo to notice.** The repo is the source; `$HOME` is a rendered
_output_. To capture a change you made live, you pull it _back_ into the source
(next section).

## "Do I back up files into `home/` by hand?" — no

This is the question that trips everyone up. You do **not** hand-copy a file into
`home/dot_config/…`. You let chezmoi do the translation (real path → source name
with `dot_`, `private_`, `.tmpl`):

```sh
# Start tracking a new file that exists in $HOME:
chezmoi add ~/.config/foo/config.toml
#  → creates home/dot_config/foo/config.toml in the repo

# You changed an already-tracked file live in $HOME and want the repo to catch up:
chezmoi re-add            # re-import ALL managed files that changed
chezmoi re-add ~/.config/foo/config.toml   # or just one

# Add a whole directory:
chezmoi add ~/.config/niri

# Add a file that must be 0600 (SSH keys, tokens):
chezmoi add --encrypt   ~/.ssh/id_ed25519     # (we don't use encryption here yet)
```

`add` vs `re-add`:

- **`chezmoi add`** — first time, or to pick up brand-new files.
- **`chezmoi re-add`** — a file is _already_ managed and you edited the live copy;
  re-import its current contents. It will **not** clobber templated files with your
  machine's rendered values (it refuses to re-add a `.tmpl` unless it still matches).

The other direction — edit the source without leaving your editor confused about
templates:

```sh
chezmoi edit ~/.config/fish/config.fish   # opens the SOURCE file for that target
chezmoi edit --apply ~/.gitconfig         # edit source, then apply immediately
chezmoi cd                                # drop into a shell at the source dir (home/)
```

## The daily loop

```sh
chezmoi diff            # preview: what WOULD apply change in $HOME? (read this first)
chezmoi status          # short per-file status (like git status)
chezmoi apply           # render source → write $HOME  (the actual "install")
chezmoi apply -v -n     # verbose dry-run — show without writing
chezmoi update          # git pull the repo, then apply  (sync a second machine)
chezmoi managed         # list every path chezmoi controls
chezmoi unmanaged ~/.config   # list what's NOT tracked yet (find candidates to add)
chezmoi forget ~/.config/foo  # stop managing (keep the live file, drop from source)
chezmoi destroy ~/.config/foo # stop managing AND delete the live file (careful)
```

Rule of thumb: **`chezmoi diff` before every `chezmoi apply`.** Applying overwrites
`$HOME`, so read the diff the way you'd read a `git diff` before committing.

## Source-name conventions (attributes)

The filename in `home/` _is_ the metadata. chezmoi decodes prefixes/suffixes:

| Source name                      | Applies as                       | Meaning                                  |
| -------------------------------- | -------------------------------- | ---------------------------------------- |
| `dot_config/`                    | `~/.config/`                     | `dot_` → leading `.`                     |
| `private_dot_ssh/`               | `~/.ssh/` (0600)                 | `private_` → not group/world readable    |
| `dot_gitconfig.tmpl`             | `~/.gitconfig`                   | `.tmpl` → rendered as a template         |
| `executable_foo.sh`              | `~/foo.sh` (+x)                  | `executable_` → sets the execute bit     |
| `.chezmoiroot`                   | —                                | points chezmoi at `home/` as the root    |
| `.chezmoi.toml.tmpl`             | `~/.config/chezmoi/chezmoi.toml` | the prompt/data template (see below)     |
| `.chezmoiignore`                 | —                                | targets to skip (like `.gitignore`)      |
| `.chezmoiscripts/run_once_*`     | runs once                        | one-time setup scripts                   |
| `.chezmoiscripts/run_onchange_*` | runs when its content changes    | re-runs when a hash embedded in it moves |
| `.chezmoiexternal.toml`          | —                                | pull files/archives from URLs on apply   |

Set attributes on an existing managed file without renaming by hand:

```sh
chezmoi chattr +private,+template ~/.ssh/config
```

## Templates + your machine data

Private and per-machine values never live in the repo — they're **template
variables** filled from data you supply once. The flow:

1. On `chezmoi init`, [`home/.chezmoi.toml.tmpl`](../home/.chezmoi.toml.tmpl)
   prompts for `email`, `name`, work git host/port, `ghq` roots, and whether to
   auto-install packages.
2. Your answers are written to `~/.config/chezmoi/chezmoi.toml` — **gitignored,
   never committed**.
3. Any `*.tmpl` source file can reference them: `{{ .email }}`, `{{ .workGitHost }}`.

```sh
chezmoi data             # dump the data available to templates (your answers)
chezmoi execute-template '{{ .email }}'   # test a template snippet
chezmoi init             # re-run the prompts (promptStringOnce keeps prior answers)
```

So [`dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl) commits `email = {{ .email }}`,
and _your_ machine renders it to your real address. The public repo stays clean.
See [git.md](git.md) for how that gitconfig is structured.

## Scripts (bootstrap on apply)

Scripts under `home/.chezmoiscripts/` run during `chezmoi apply`:

- **`run_once_*`** — runs a single time per machine (idempotent bootstrap).
- **`run_onchange_*`** — re-runs whenever the script's rendered content changes.
  This repo's [package installer](../home/.chezmoiscripts/run_onchange_install-packages.sh.tmpl)
  embeds the `sha256sum` of `packages/*.txt`, so editing a package list re-triggers
  it. See [packages.md](packages.md).

## What this repo does NOT manage

- **`etc/` system files** (`/etc/hosts`, greetd, grub…) are _not_ chezmoi-managed —
  they need root and are applied by hand with `sudo`. See each guide.
- **Secrets** — no secret is committed, encrypted or not. Machine-local secrets go
  in an untracked file (e.g. `~/.config/fish/local.fish`); passwords live in
  [gopass](gopass.md), a separate encrypted store. chezmoi's own `encrypted_` +
  age/gpg support exists but we deliberately don't use it (see
  [ADR 0002](adr/0002-private-data-via-templates.md)).

## References

- [chezmoi — user guide](https://www.chezmoi.io/user-guide/command-overview/)
- [chezmoi — target types & attributes](https://www.chezmoi.io/reference/source-state-attributes/)
- [twpayne/dotfiles](https://github.com/twpayne/dotfiles) — the chezmoi author's own
  dotfiles; the canonical reference for advanced patterns (`.chezmoiexternal`,
  `.chezmoidata`, `.chezmoitemplates`, scripts).
