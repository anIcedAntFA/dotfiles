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

## Personal account bootstrap (new machine)

`chezmoi apply` drops `~/.claude/statusline-command.sh`, `~/.claude/CLAUDE.md`,
and `~/.claude/RTK.md` — but **not** `settings.json` (see
[What's tracked](#whats-tracked-and-what-isnt) for why). Two manual steps wire up
the rest.

1. Point `settings.json` at the statusline and re-add the RTK hook — merge into
   `~/.claude/settings.json` (`<you>` = your `$HOME` user):

   ```jsonc
   {
     "statusLine": {
       "type": "command",
       "command": "bash /home/<you>/.claude/statusline-command.sh"
     },
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [{ "type": "command", "command": "rtk hook claude" }]
         }
       ]
     }
   }
   ```

2. Re-add the plugin marketplaces and enable the plugins through `/plugin` (the
   enabled set lives in the untracked `settings.json`):

   | Marketplace               | Source                                                                                        | Plugins enabled from it                                                                                  |
   | ------------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
   | `claude-plugins-official` | built-in                                                                                      | skill-creator, context7, code-simplifier, claude-md-management, gopls-lsp, playwright, mattpocock-skills |
   | `karpathy-skills`         | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | andrej-karpathy-skills                                                                                   |
   | `cloudflare`              | [cloudflare/skills](https://github.com/cloudflare/skills)                                     | (skills only — cloudflare, wrangler, workers…)                                                           |
   | `svelte`                  | [sveltejs/ai-tools](https://github.com/sveltejs/ai-tools)                                     | (none enabled yet — kept as a known marketplace)                                                         |

3. Re-install the cross-agent skills. These come from the `npx skills` manager
   (state in `~/.agents/.skill-lock.json`), **not** the Claude plugins — the
   Claude plugin for the same author exposes a _different_ set and does not
   include these (`caveman`, `grill-with-docs`, …), so a plugin can't replace
   them:

   ```sh
   # caveman, grill-with-docs, handoff, teach, write-a-skill, improve-codebase-architecture
   npx skills@latest add mattpocock/skills
   ```

   See [mattpocock/skills → Get the skills](https://github.com/mattpocock/skills#1-get-the-skills).

> **Skills use two install paths, on purpose.** Claude _plugins_ are Claude-only;
> the `npx skills` manager symlinks a skill into every agent's dir (`~/.agents` is
> its shared home), which is why cross-agent skills go through it. The one
> hand-authored skill — [`git-workflow`](#whats-tracked-and-what-isnt) — is
> vendored into this repo instead (it encodes this repo's own commit
> conventions). `caveman` is the skill layer only; the token-**proxy** layer is
> owned by RTK, so [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)'s
> proxy is deliberately not installed (it would double up on RTK). If Codex (or
> any second agent) is adopted, relocate `git-workflow` to `~/.agents/skills` and
> symlink it in, matching the manager's own layout.

## Knowing which account you're in

The statusline (`~/.claude/statusline-command.sh`, shared by both dirs) reads
`$CLAUDE_CONFIG_DIR` and leads with a colored tag — green **personal**, red
**work** — so every session, auto or forced, shows its account. That variable is
exported by the wrapper and inherited by the statusline subprocess.

> Verify inheritance once: run `claude-work`, and check the tag is red. If your
> Claude build doesn't pass `CLAUDE_CONFIG_DIR` through to the statusline, have
> the wrappers also export a plain `CLAUDE_ACCOUNT` and read that instead.

## What's tracked (and what isn't)

**Tracked** (public repo, no secrets):

- the three fish functions and this guide — `claude.fish.tmpl` renders
  `{{ .ghqCompanyRoot }}` per machine, so the company path stays out of the
  source (same pattern as [git.md](git.md) and [vpn.md](vpn.md));
- `home/dot_claude/statusline-command.sh` → `~/.claude/statusline-command.sh` — a
  static, self-authored script with no per-machine value (it only reads
  `$CLAUDE_CONFIG_DIR` and matches a generic `*/.claude.work`);
- `home/dot_claude/CLAUDE.md` (`@RTK.md`) and `RTK.md` — the personal global
  instructions. Secret-free and portable; the RTK proxy they describe is already
  tracked under [`dot_config/rtk`](../home/dot_config/rtk);
- `home/dot_claude/skills/git-workflow/` → `~/.claude/skills/git-workflow` — the
  one hand-authored, repo-agnostic skill (it encodes this repo's own commit
  conventions), so it is vendored and available in every project. Everything else
  under `skills/` is installed, not authored (see below).

**Never tracked** (machine-local `$HOME`, or trivially reinstalled): both
`.credentials.json`, all `projects/` history and `memory/`, the installed
`plugins/` and the rest of `skills/` (plugin dirs, or `npx skills` symlinks into
`~/.agents` — reinstalled from their source repos, see the bootstrap above), and
both `settings.json`.

`settings.json` is left out on purpose. Claude Code rewrites it behind your back —
a theme toggle, enabling a plugin — so tracking it would mean the same
app-owned-snapshot drift as noctalia
([ADR 0012](adr/0012-noctalia-config-tracked-as-app-owned-snapshot.md)):
re-syncing source from the live file after every UI change. The little worth
reproducing (the statusline wiring, the RTK hook, the plugin list) is captured as
a copy-paste bootstrap above instead.

## Related

- [git.md](git.md) — the same personal/work identity split for git (`includeIf`)
- [ghq.md](ghq.md) — where the company root (`ghqCompanyRoot`) comes from
- [direnv.md](direnv.md) — path-based env, the editor-proof upgrade
- [ADR 0023](adr/0023-multi-account-claude-code-via-config-dir.md) — why this design
- [ADR 0002](adr/0002-private-data-via-templates.md) — private paths via templates

## References

- Claude Code — [`CLAUDE_CONFIG_DIR` / settings](https://docs.claude.com/en/docs/claude-code/settings)
