# ripgrep — fast recursive search

## Why

[ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) is a recursive grep that
respects `.gitignore`, skips binary files, and is fast. It's the default search
tool across this setup — fish, editors, and the AI agents all reach for `rg`
(the agents are held to it: see
[claude-code.md](claude-code.md#search-rule-and-guard-hook)).

The theory — how it differs from `grep` and what a search can silently miss — is
in [search-concepts.vi.md](search-concepts.vi.md). Its file-finding counterpart
is [fd](fd.md).

## Install

```sh
yay -S --needed ripgrep
```

It's in [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt).

## Usage

| Command                         | Action                                             |
| ------------------------------- | -------------------------------------------------- |
| `rg PATTERN [PATH]`             | Regex search under `PATH` (or `.`), recursive.     |
| `rg -F 'a.b(c)'`                | Literal string — no regex escaping.                |
| `rg -w word` · `rg -i` · `-s`   | Whole word · ignore case · force case-sensitive.   |
| `rg -l PATTERN` · `rg -c`       | File names only · match count per file.            |
| `rg -A 2 -B 2` · `rg -C 2`      | Context lines after / before / around.             |
| `rg -g '*.md' -g '!docs/adr/*'` | Include / exclude by glob.                         |
| `rg -t fish` · `rg -T md`       | Include / exclude by file type (`rg --type-list`). |
| `rg --files`                    | List the files rg _would_ search — no pattern.     |
| `rg -U 'a\nb'`                  | Multi-line match.                                  |
| `rg -P '(?<=x)y'`               | PCRE2: lookaround and backreferences.              |
| `rg -r '$1' 'f(o+)'`            | Print matches rewritten (it never edits files).    |
| `rg -u` · `-uu` · `-uuu`        | Widen what it sees — see below.                    |

The default regex engine has no backreferences or lookaround; that is what keeps
its worst case linear. `-P` switches engine for the patterns that need them.

> **Give it a path in scripts.** With no path argument, `rg` searches stdin when
> stdin is a pipe or a file instead of walking the directory — inside a compound
> command that can mean waiting forever. `rg PATTERN .` is unambiguous.

## What rg sees

Stock ripgrep applies three filters and prints nothing about any of them:

| Level     | Stops skipping…                                         |
| --------- | ------------------------------------------------------- |
| _(stock)_ | — skips ignored files, dotfiles, and binary files       |
| `-u`      | ignored files (`.gitignore`, `.ignore`, `.rgignore`, …) |
| `-uu`     | …and dotfiles (same as `--no-ignore --hidden`)          |
| `-uuu`    | …and binary files (same as adding `--binary`)           |

The [config](#config) below already adds `--hidden`, so on this machine the
levels collapse to two, and this is what they cover in this repo:

| Command          | Files searched |
| ---------------- | -------------- |
| `rg --no-config` | 232            |
| `rg`             | 255            |
| `rg -uu`         | 452            |

(`rg --files . | wc -l` at the time of writing.)

**An empty result is "not seen", not "absent".** Before concluding a string does
not exist, retry with `rg -uu`. Use `-uu` rather than `-u` out of habit: it means
the same thing whether or not the config is loaded.

`rg` also does not follow symlinks; add `-L` when a tree is made of them.

## Config

ripgrep does **not** read an XDG path on its own. It only loads the file named by
`$RIPGREP_CONFIG_PATH`, so two pieces are needed:

1. [`home/dot_config/ripgrep/config`](../home/dot_config/ripgrep/config) — the flags.
2. `RIPGREP_CONFIG_PATH` exported in [`config.fish`](../home/dot_config/fish/config.fish):

   ```fish
   set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config
   ```

The config keeps to **behavioural** flags only:

```text
--smart-case      # case-insensitive unless the pattern has an uppercase letter
--hidden          # search dotfiles too (apt for a dotfiles repo)
--glob=!.git/     # but never descend into .git
--glob=!vendor/   # or vendored dependency trees
```

> [!NOTE]
> Display/grouping flags (`--no-heading`, `--sort=path`) are deliberately left
> out. This config applies to **every** `rg` invocation — including tools that
> shell out to rg and expect its default output — and `--sort=path` disables
> ripgrep's parallelism, slowing large searches. `--hidden` still respects
> `.gitignore`; it only lifts the "skip dotfiles" filter.

`--no-ignore` is also left out, on purpose. It would end the "not seen" problem
by searching `node_modules/`, `target/` and `dist/` in every other project —
which is the noise ripgrep exists to remove. The gap is closed by a rule (widen
before concluding) and, where a repo needs it, by a targeted whitelist.

Override per-search on the command line (flags there win), or ignore the config
entirely for one call with `rg --no-config …`. The two `--glob` excludes are
globs, not ignore rules, so `-uu` does **not** lift them — `.git/` stays out.

## Un-hiding a gitignored path

When a directory is rightly kept out of git but should still be searchable, do
not reach for `--no-ignore`. Add a `.ignore` file — read by ripgrep and fd, and
by nothing else; git never looks at it:

```text
!generated/
generated/cache/
```

A `!` line in `.ignore` overrides `.gitignore` because `.ignore` has higher
precedence (and `.rgignore` / `.fdignore` are higher still, but each is read by
one tool only — `.ignore` is the single file both honour). It also lifts the
dotfile filter for that path, so a whitelisted `.dir/` is seen without
`--hidden`. Three limits, all verified:

- Whitelist the **directory** the ignore rule names. `!dir/file` does nothing
  while `dir/` itself is ignored.
- A glob still wins: `-g '!dir/'`, `fd -E dir`, and the `--glob` lines in the
  config cannot be undone by any ignore file.
- Symlinks are not followed, so whitelisting a directory of symlinks shows the
  links, not what they point at.

This repo has no `.ignore`. It briefly had one for project-level agent skills;
those now come from a plugin, and nothing gitignored here needs to be searched by
default.

## References

- [ripgrep user guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [ripgrep config file](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file)
- [Automatic filtering](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#automatic-filtering) — the ignore-file precedence
- [docs/research/search-tools-and-rtk.md](research/search-tools-and-rtk.md) — sourced notes behind this guide
