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

## Setup: pointing chezmoi at this working copy (author flow)

The README quick-start (`chezmoi init --apply <url>`) is the **consumer** path — it
clones a _fresh_ copy into chezmoi's default source dir, `~/.local/share/chezmoi`.
As the **author** you already have this repo checked out (e.g. via `ghq` at
`~/workspace/github.com/<you>/dotfiles`) and want to edit it **in place** while
chezmoi reads from it. Point chezmoi's source dir at your working copy with a symlink:

```sh
# The symlink must BE ~/.local/share/chezmoi and point at the repo ROOT.
ln -s ~/workspace/github.com/<you>/dotfiles ~/.local/share/chezmoi
```

> [!WARNING]
> **Gotcha:** if `~/.local/share/chezmoi` already exists _as a directory_, then
> `ln -s <repo> ~/.local/share/chezmoi` silently drops the link **inside** it
> (`~/.local/share/chezmoi/dotfiles`). chezmoi then sees `dotfiles` as an entry to
> create at `~/dotfiles` — a nonsense diff. Fix: `rm -rf ~/.local/share/chezmoi`
> **first**, then create the symlink so it _is_ the link.

Then generate your machine data. `chezmoi init` **does not touch `$HOME`** — it only
writes `~/.config/chezmoi/chezmoi.toml` (your prompt answers), so it's safe to run:

```sh
chezmoi init            # runs the prompts → writes ~/.config/chezmoi/chezmoi.toml
chezmoi source-path     # sanity check: must resolve into the repo
chezmoi execute-template '{{ .chezmoi.sourceDir }}'   # should end in …/dotfiles/home
```

`.chezmoiroot` is `home`, so the _effective_ source is `<repo>/home`. Because it's a
symlink, `chezmoi git …` and edits under `home/` act directly on your working copy —
one source of truth, no second clone. Only **after** this does `chezmoi diff/apply`
work (templates need the data from `init`).

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
chezmoi edit --apply ~/.config/git/config # edit source, then apply immediately
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

## Applying selectively (when a full apply scares you)

The **first** apply on an already-configured machine shows changes to _everything_ —
that's normal. chezmoi has never written these files, so every managed path looks
new (much of it is just whitespace/permission normalisation, e.g. `mode 40700 →
40755`). You don't have to take it all at once — scope apply to a path:

```sh
chezmoi diff  ~/.config/fish                       # preview one path
chezmoi apply ~/.config/fish                        # apply just that dir
chezmoi apply ~/.config/git/config ~/.ssh/config    # several explicit paths

chezmoi apply -i                       # interactive: confirm each change (y/n/all/quit)
chezmoi apply -n -v ~/.config/fish     # dry-run + verbose — writes nothing
chezmoi apply --exclude=scripts <path> # skip run_ scripts (e.g. the package installer)
chezmoi merge ~/.config/fish/config.fish   # 3-way merge instead of overwrite (keep live edits)
```

Go cluster by cluster, low-risk first (`~/.config/git`, `~/.config/fish`): `diff` →
`apply <path>` → verify → next.

> [!NOTE]
> **Orphans.** A path chezmoi _stops_ referencing — e.g. an old `~/.config/git/config-ndvn`
> after the include switches to `~/.config/git/config-work` — is **not** deleted. chezmoi
> never removes unmanaged files. Confirm the replacement works, then `rm` the orphan
> yourself (or `chezmoi destroy` while it was still managed).

## Source-name conventions (attributes)

The filename in `home/` _is_ the metadata. chezmoi decodes prefixes/suffixes:

| Source name                      | Applies as                       | Meaning                                  |
| -------------------------------- | -------------------------------- | ---------------------------------------- |
| `dot_config/`                    | `~/.config/`                     | `dot_` → leading `.`                     |
| `private_dot_ssh/`               | `~/.ssh/` (0600)                 | `private_` → not group/world readable    |
| `dot_config/git/config.tmpl`     | `~/.config/git/config`           | `.tmpl` → rendered as a template         |
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

> [!IMPORTANT]
> **Only file _contents_ are templated, never the target _name_.** chezmoi does not
> interpolate `.data` into a filename. So the work-identity file is always
> `~/.config/git/config-work` (from `dot_config/git/config-work.tmpl`) — even though its
> _contents_ and the `includeIf` directory _are_ templated from your answers. Seeing
> `path = ./config-work` while your company slug is `ndvn` is **correct**:
> the `gitdir` uses your value, the filename is a fixed convention. See [git.md](git.md).

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

So [`dot_config/git/config.tmpl`](../home/dot_config/git/config.tmpl) commits `email = {{ .email }}`,
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
