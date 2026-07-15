# zoxide — smarter directory jumping

## Why

[zoxide](https://github.com/ajeetdsouza/zoxide) is a frecency-based `cd`: it
remembers the directories you visit and lets you jump to them by a fragment of the
path. It **replaced** the older `jethrokuan/z` fisher plugin here — faster,
SQLite-backed, and actively maintained. See [fish.md](fish.md) for how it slots
into the shell, and [ADR 0008](adr/0008-terminal-workspace-model.md) for the swap.

## Install

```sh
yay -S --needed zoxide
```

It's in [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt).
`config.fish` runs `zoxide init fish | source` (guarded by `type -q zoxide`), which
defines the commands below and hooks directory changes.

## Usage

| Command       | Action                                               |
| ------------- | ---------------------------------------------------- |
| `z <partial>` | Jump to the highest-ranked directory matching.       |
| `z a b`       | Match on multiple fragments (e.g. `z conf ghostty`). |
| `zi`          | **Interactive** fuzzy pick via `fzf`.                |
| `z -`         | Jump back to the previous directory.                 |

The builtin `cd` is left intact (zoxide only adds `z`/`zi`). There is **no**
`selectall` subcommand — the interactive picker is `zi`.

## Migrating from the old `z`

The previous `jethrokuan/z` stored its database at `~/.local/share/z/data`.
zoxide **0.10** imports via an `import <source>` subcommand (not `--from`), and
`import z` reads a hard-coded `~/.z`, so stage the file there first:

```fish
cp ~/.local/share/z/data ~/.z   # stage where `import z` looks
zoxide import z --merge         # merge into zoxide's db
rm ~/.z                         # clean up
```

Then verify and clear the old plugin's leftover universal variables:

```fish
zoxide query -l | head          # should list your imported paths
set -eU Z_CMD ZO_CMD Z_DATA Z_DATA_DIR Z_EXCLUDE
```

The old `__z*.fish` / `conf.d/z.fish` files are already removed from the repo and
from `$HOME` (via [`.chezmoiremove`](../home/.chezmoiremove)); `fisher update`
drops the plugin itself.

## Troubleshooting

- **`error: unexpected argument '--from'`** — that flag is from newer zoxide docs;
  0.10 uses the `import z` subcommand form above.
- **`import z` says `could not read "~/.z"`** — it only reads `~/.z`. Stage your
  real data there first (see the migration steps).
- **`z` does nothing yet** — the database is empty until you `cd` around (or import).
  zoxide learns as you navigate.

## Environment variables

Set in `config.fish` if needed: `_ZO_DATA_DIR` (db location), `_ZO_EXCLUDE_DIRS`
(globs to ignore), `_ZO_FZF_OPTS` (flags for the `zi` picker), `_ZO_ECHO=1` (print
the matched dir before jumping).

## References

- [zoxide documentation](https://github.com/ajeetdsouza/zoxide)
- [zoxide wiki — migration](https://github.com/ajeetdsouza/zoxide/wiki/Migration)
