# RTK — compress command output before the agent reads it

## Why

An AI coding agent pays for every byte a shell command prints: `git log`, a test
run, a directory listing all land in its context window as tokens.
[RTK](https://github.com/rtk-ai/rtk) ("Rust Token Killer") is a CLI proxy that
runs the real command and prints a **shorter** version of its output — grouped,
de-duplicated, truncated — so the agent reads less.

It is a **personal-account** tool here. Company sessions never go through it; see
[claude-code.md](claude-code.md#what-crosses-the-boundary-and-what-doesnt).

## How it works

Two halves:

1. **Filters.** `rtk <cmd> …` wraps a command with a purpose-built formatter —
   `rtk git status`, `rtk ls`, `rtk grep`, `rtk read`, `rtk go test`, … (`rtk
   --help` lists them all). Each one knows what in that tool's output is noise.
2. **A rewrite hook.** Nobody types `rtk` by hand. Claude Code runs
   `rtk hook claude` as a `PreToolUse` hook on every Bash call; the hook rewrites
   the command if it has a filter for it, and Claude Code runs the rewritten one.

Ask the hook what it would do without running anything:

```console
$ rtk hook check 'git status'
rtk git status
$ rtk hook check 'cd x && git log'
cd x && rtk git log
$ rtk hook check 'cat a | head'
No rewrite for: cat a | head
$ rtk hook check 'fd -e md'
No rewrite for: fd -e md
```

What the hook leaves alone, in 0.45:

- **Tools it has no filter for** — `fd`, `pacman`, `chezmoi`, `just`, …
- **The producing side of a pipe.** `grep -r foo . | head` stays raw, because
  rewriting it would change the bytes the next stage parses. The _final_ stage
  can be rewritten: `git log | grep fix` becomes `git log | rtk grep fix`.
- **Anything it cannot take apart safely** — `$(…)`, heredocs, loops, redirects
  to a file, absolute paths (`/usr/bin/grep`).

Both sides of `&&`, `||` and `;` are rewritten independently.

## Install

RTK is not a pacman package; the binary lives in `~/.local/bin/rtk` from the
upstream installer. Then wire it into Claude Code once:

```sh
rtk init -g      # hook in ~/.claude/settings.json + ~/.claude/RTK.md + @RTK.md
rtk init --show  # what is configured
rtk verify       # hook integrity + filter self-tests
```

`rtk init -g` writes three things, and chezmoi tracks two of them
([`home/dot_claude/`](../home/dot_claude)): `RTK.md` and the `@RTK.md` line in
`CLAUDE.md`. The hook entry lives in the untracked `settings.json` — it is part of
the [personal bootstrap](claude-code.md#personal-account-bootstrap-new-machine).

> **Name collision.** Another project ships a binary called `rtk` (Rust Type
> Kit). If `rtk gain` says "unknown command", the wrong one is on `PATH`.

## Reading `rtk gain`

```sh
rtk gain             # all projects
rtk gain -p          # this project only
rtk gain --history   # recent commands, one line each
rtk gain -F          # commands whose output RTK failed to parse
rtk session          # per-session share of commands that went through RTK
rtk discover         # commands in past sessions RTK could have handled
```

"Tokens" here are an estimate — bytes of output divided by four, no real
tokenizer — and "input" / "output" are **not** model tokens: they are the size of
one command's stdout before and after filtering. The percentage is the reliable
part; the absolute counts will not match a bill.

The headline percentage is a **token-weighted average**, so it follows whatever
you run most — not how good the filters are. A real reading from this machine:

| Command          | Count | Saved  | Avg % |
| ---------------- | ----- | ------ | ----- |
| `rtk read`       | 557   | 369.1K | 12.8% |
| `rtk grep`       | 722   | 25.7K  | 25.3% |
| `rtk diff`       | 2     | 12.5K  | 81.1% |
| `rtk ls -la .`   | 29    | 8.3K   | 78.4% |
| `rtk git commit` | 3     | 6.2K   | 99.9% |
| `rtk go test`    | 1     | 4.5K   | 99.8% |
| **Total**        | 3378  | 509.6K | 25.0% |

Read it by row, not by total:

- **`rtk read` dominates the volume and saves the least** — by design. Reading a
  file is the one place the agent needs the content, so the filter only trims.
- **Search saves about a quarter.** Matches are the payload; only padding and
  repetition go.
- **The 80–99% filters are the ones with real noise** — test runners, commit
  output, long listings — and they ran a handful of times.

A session of reading and searching (docs work, this repo) lands around 25%. A
session of builds and test runs lands far higher. Neither says anything is
misconfigured; `rtk verify` and `rtk init --show` are the checks for that.

What does **not** count: anything the hook did not rewrite. `rtk session` shows
that share — roughly 30% of commands here go through RTK; the rest are pipelines
and tools it has no filter for.

## What RTK can cost you

Compression is lossy. Two different failure shapes, and only one is acceptable
(the terms are from [CONTEXT.md](../CONTEXT.md#search)):

**Signalled truncation — fine.** Past a limit, RTK cuts the output and says so,
with the path of the full log:

```text
  +48 more in docs/zed.md [see remaining: tail -n +26 ~/.local/share/rtk/tee/…_grep_0_docs_zed_md.log]
+52 more files [see remaining: tail -n +1 ~/.local/share/rtk/tee/…_grep_skipped.log]
```

The limits are in `~/.config/rtk/config.toml` (`grep_max_results = 200`,
`grep_max_per_file = 25`, lines cut at 80 characters by default). The agent's
instruction is to treat `+N more` as "incomplete": narrow the pattern or read the
log.

**Silent narrowing — a defect.** The two search wrappers behave differently, and
only one of them is what it says:

- **`rtk grep` is real `grep`** with shorter output (likewise `rtk rg` and `rg`).
  It runs the engine you typed, adds `-n -H -I`, groups matches by file and caps
  them. It sees what `grep` sees — apart from binary files, which `-I` skips.
- **`rtk find` is not `find`.** It is a reimplementation on the same
  ignore-aware directory walker ripgrep uses: it **skips gitignored files and
  dotfiles**, caps at 50 results, and has no flag to turn any of that off.

| Typed                              | Ran         | Result in this repo |
| ---------------------------------- | ----------- | ------------------- |
| `find . -name settings.local.json` | real `find` | 1 file              |
| same, through the hook             | `rtk find`  | 0                   |

(The file is `.claude/settings.local.json` — hidden and gitignored, so `rtk find`
misses it twice over. A `!` whitelist in a `.ignore` file is the only thing that
changes what `rtk find` sees.)

The agent typed a tool that sees everything and got one that does not, with no
reason to look further. `rtk find` also rejects most of `find`'s expression
language (`-not`, `-o`, `-exec`, `-newer`, `-perm`, …) — yet the hook still
rewrites those commands, so `find . -perm -u+x` fails with "rtk find does not
support compound predicates or actions".

This is one reason a second hook — the
[search guard](claude-code.md#search-rule-and-guard-hook) — refuses `find`
outright: the agent types `fd` itself and knows it has to widen the search before
saying "not found", or types `command find …` and gets the real thing.

A smaller wart: RTK abbreviates repeated tokens in some outputs. When exact text
matters (a diff you will apply, a string you will search for), bypass the filter.

## Bypassing

```sh
rtk proxy <cmd>   # run the real command, unfiltered (still counted, at 0%)
command <cmd>     # the hook does not recognise it, so nothing is rewritten
```

## Config

| File                                                                | Tracked | Holds                                                           |
| ------------------------------------------------------------------- | ------- | --------------------------------------------------------------- |
| [`~/.config/rtk/filters.toml`](../home/dot_config/rtk/filters.toml) | yes     | Custom filters for tools RTK doesn't know. Currently empty.     |
| `~/.config/rtk/config.toml`                                         | no      | Limits, tee log, tracking, telemetry consent — machine state.   |
| `~/.local/share/rtk/`                                               | no      | `history.db` (what `rtk gain` reads) and `tee/` (full outputs). |

`config.toml` is gitignored on purpose: it records a telemetry-consent timestamp
and is rewritten by `rtk config`. Telemetry is off.

A project can add `.rtk/filters.toml`; RTK only loads it after `rtk trust` in that
directory. This repo has none.

No limits are tuned and no filter is written for `fd`: its output is already bare
paths, so a filter could only truncate — trading a better `rtk gain` number for
missed files.

## References

- [rtk-ai/rtk](https://github.com/rtk-ai/rtk) — README, filter list, custom filters
- `rtk --help` · `rtk <subcommand> --help`
- [docs/research/search-tools-and-rtk.md](research/search-tools-and-rtk.md) — sourced notes behind this guide
