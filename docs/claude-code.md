# Claude Code — one machine, two accounts

Run a **personal** Claude subscription and a **company Teams** account on the same
box without them ever colliding — the same "one machine, two identities" idea as
[git.md](git.md), applied to Claude Code.

## Why

The company Teams account has its own data-retention and privacy policy, so
company work must run under it — not under the personal login. But there is no
`/switch` command and no profile picker in Claude Code. What it does have is one
environment variable, `CLAUDE_CONFIG_DIR`, that relocates **everything** for an
account: the OAuth credential (`.credentials.json`), the full session history
(`projects/`), skills, plugins, and settings. Point two shells at two dirs and
you get two fully isolated accounts.

We drive that variable from a directory boundary — the **same** `ghqCompanyRoot`
that git's `includeIf` already uses — so the account follows where the repo lives,
with zero manual switching. No third-party tool; the wrappers are ~10 lines of fish.

## The layout — asymmetric on purpose

| Account      | Config dir            | How it's reached                                    |
| ------------ | --------------------- | --------------------------------------------------- |
| **personal** | `~/.claude` (default) | anything outside the company root; `command claude` |
| **work**     | `~/.claude.work`      | inside the company root; `claude-work`              |

Personal stays as the stock `~/.claude` — already logged in, nothing to migrate.
Only `~/.claude.work` is new. Neither dir is tracked by chezmoi; both live in
`$HOME` and hold a **plaintext** `.credentials.json` (mode 0600) — they must never
enter this public repo.

## The wrappers

Three autoloaded fish functions (`home/dot_config/fish/functions/`):

- **`claude`** — auto. If `$PWD` is inside `{{ .ghqCompanyRoot }}` it exports
  `CLAUDE_CONFIG_DIR=~/.claude.work`; otherwise it runs the personal default.
  `claude.fish.tmpl` is templated so the company path never lands in the repo.
- **`claude-work`** — force the work account from anywhere.
- **`claude-personal`** — force personal even inside a work dir (`env -u
  CLAUDE_CONFIG_DIR`).

Fish has no `VAR=val cmd` prefix syntax, so the wrappers use `set -lx` (local +
exported, function-scoped) and `env -u`. Each forwards `$argv` verbatim, so every
Claude flag and subcommand passes straight through.

> **Terminal only.** A fish function shadows `claude` only in an interactive
> shell. If you ever launch Claude Code from an editor (Zed's agent, say), the
> wrapper is bypassed and you get the default `~/.claude` (personal). To make the
> boundary editor-proof, drop a `.envrc` under the company root that exports
> `CLAUDE_CONFIG_DIR` — see [direnv.md](direnv.md). Not needed today: nothing
> launches Claude outside the terminal.

## What crosses the boundary (and what doesn't)

Everything inside a config dir is per-account, so `~/.claude.work` is a blank
slate. The chosen split:

| Shared into work                   | Kept personal-only                               |
| ---------------------------------- | ------------------------------------------------ |
| `skills/` (symlink)                | `CLAUDE.md` (`@RTK.md`) — RTK is a personal tool |
| statusline script (same abs. path) | `memory/` — personal auto-memory                 |
|                                    | `projects/` — session history                    |
|                                    | `.credentials.json` — the login itself           |
|                                    | the **RTK hook** (lives in `settings.json`)      |

`settings.json` is **not** shared: it carries the RTK command-rewrite hook, so the
work dir gets its own minimal `settings.json` (statusline block only, no hook).
That keeps RTK — and its token proxy — off every company session by construction.

## Bootstrap (once, machine-local — not committed)

```sh
# 1. Apply the dotfiles so the fish wrappers exist
chezmoi apply

# 2. Create the work dir and log in with the company Teams account
mkdir -p ~/.claude.work
claude-work            # browser OAuth flow → approve as the company identity

# 3. Share skills; keep everything else separate
ln -s ~/.claude/skills ~/.claude.work/skills

# 4. Give the work dir a settings.json with the statusline but NO RTK hook.
#    Point it at the same absolute script the personal one uses:
#    "statusLine": { "type": "command",
#                    "command": "bash /home/<you>/.claude/statusline-command.sh" }
```

## Knowing which account you're in

The statusline (`~/.claude/statusline-command.sh`, shared by both dirs) reads
`$CLAUDE_CONFIG_DIR` and leads with a colored tag — green **personal**, red
**work** — so every session, auto or forced, shows its account. That variable is
exported by the wrapper and inherited by the statusline subprocess.

> Verify inheritance once: run `claude-work`, and check the tag is red. If your
> Claude build doesn't pass `CLAUDE_CONFIG_DIR` through to the statusline, have
> the wrappers also export a plain `CLAUDE_ACCOUNT` and read that instead.

## What's tracked (and what isn't)

**Tracked** (public repo, no secrets): the three fish functions and this guide.
`claude.fish.tmpl` renders `{{ .ghqCompanyRoot }}` per machine, so the company
path stays out of the source — same pattern as [git.md](git.md) and
[vpn.md](vpn.md).

**Never tracked** (machine-local `$HOME`): `~/.claude`, `~/.claude.work`, both
`.credentials.json`, all history, the statusline script, and the work
`settings.json`.

## Related

- [git.md](git.md) — the same personal/work identity split for git (`includeIf`)
- [ghq.md](ghq.md) — where the company root (`ghqCompanyRoot`) comes from
- [direnv.md](direnv.md) — path-based env, the editor-proof upgrade
- [ADR 0023](adr/0023-multi-account-claude-code-via-config-dir.md) — why this design
- [ADR 0002](adr/0002-private-data-via-templates.md) — private paths via templates

## References

- Claude Code — [`CLAUDE_CONFIG_DIR` / settings](https://docs.claude.com/en/docs/claude-code/settings)
