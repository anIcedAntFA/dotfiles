# fd — find files by name

## Why

[fd](https://github.com/sharkdp/fd) is to `find` what ripgrep is to `grep`: it
walks a directory tree in parallel, respects `.gitignore`, and takes a pattern as
its first argument instead of an expression language. `fd readme` does what
`find . -iname '*readme*' -not -path '*/.git/*'` does. It is the default
file-finder here for the shell and for the AI agents (see
[claude-code.md](claude-code.md#search-rule-and-guard-hook)).

The theory — how it differs from `find` and what a search can silently miss — is
in [search-concepts.vi.md](search-concepts.vi.md).

## Install

```sh
yay -S --needed fd
```

It's in [`packages/pacman-explicit.txt`](../packages/pacman-explicit.txt).

## Usage

| Command                     | Action                                                   |
| --------------------------- | -------------------------------------------------------- |
| `fd PATTERN [PATH]`         | Regex match on the **file name**, under `PATH` (or `.`). |
| `fd -g '*.test.ts'`         | Glob instead of regex.                                   |
| `fd -e md`                  | By extension.                                            |
| `fd -t f` · `-t d` · `-t x` | Files · directories · executables.                       |
| `fd -p 'docs/adr/.*zram'`   | Match against the full path, not just the name.          |
| `fd -d 2`                   | Limit depth.                                             |
| `fd -E node_modules`        | Exclude a glob for this call.                            |
| `fd --changed-within 2d`    | Modified in the last two days.                           |
| `fd -e md -x wc -l`         | Run a command per result (parallel).                     |
| `fd -e md -X rumdl check`   | Run one command with every result as arguments.          |
| `fd -H` · `fd -HI -E .git`  | Widen what it sees — see below.                          |

Matching is smart-case: case-insensitive until the pattern contains an uppercase
letter.

## What fd sees

fd skips two kinds of entry by default, and prints nothing to say so:

| Flag          | Adds                                                    | Files seen in this repo |
| ------------- | ------------------------------------------------------- | ----------------------- |
| _(none)_      | —                                                       | 232                     |
| `-H`          | dotfiles (`.github/`, `.editorconfig`, …)               | 255                     |
| `-HI -E .git` | files matched by `.gitignore` / `.ignore` / `.fdignore` | 452                     |

(Counts from `fd -t f | wc -l` at the time of writing.)

Two consequences:

- **Always `-H` in this repo.** A dotfiles repo is mostly dotfiles, and ripgrep
  already searches them via its config. With `-H`, `fd -t f` and `rg --files`
  list the same set.
- **An empty result is "not seen", not "absent".** Before concluding a file does
  not exist, retry with `-HI -E .git`. The `-E .git` matters: `-I` also switches
  off the global ignore file below, so without it you get every git object.

`-u` is shorthand for `-HI`.

## Config

fd has **no config file for flags** and no environment variable for default
options — the upstream answer is a shell alias. What it does read is a global
ignore file:

[`home/dot_config/fd/ignore`](../home/dot_config/fd/ignore) → `~/.config/fd/ignore`

```text
.git/
vendor/
```

Same syntax as `.gitignore`, applied to every call (until `-I`). It mirrors the
`--glob=!.git/` and `--glob=!vendor/` lines in the
[ripgrep config](ripgrep.md#config) so that `-H` shows dotfiles without
descending into `.git/`.

There is deliberately no `alias fd='fd -H'`: an alias only exists in an
interactive fish, so scripts and agents would see a different fd than you do.
Type the flag.

Per-directory rules go in `.ignore` (read by fd **and** ripgrep) or `.fdignore`
(fd only). A `!path/` line there can un-hide something `.gitignore` hides — see
[ripgrep.md](ripgrep.md#un-hiding-a-gitignored-path). This repo has neither file.

## Troubleshooting

- **`fd foo` finds nothing but the file exists** — it is a dotfile (`-H`), is
  gitignored (`-I`), or sits behind a symlinked directory (`-L`).
- **`fd -HI` floods the terminal with `.git/objects/…`** — add `-E .git`.
- **Pattern with a `/` matches nothing** — fd matches the file name only; use
  `-p` for the full path.
- **`fd '*.md'` errors with a regex parse error** — that's a glob; use `-g '*.md'`
  or `-e md`.

## References

- [fd README](https://github.com/sharkdp/fd#readme)
- `man fd` · `fd --help`
- [docs/research/search-tools-and-rtk.md](research/search-tools-and-rtk.md) — sourced notes behind this guide
