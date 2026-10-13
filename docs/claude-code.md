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

| Shared into work                                         | Kept per-account                        |
| -------------------------------------------------------- | --------------------------------------- |
| `skills/` (symlink)                                      | `.credentials.json` — the login itself  |
| statusline script (same abs. path)                       | `projects/` — session history           |
| `RTK.md` + `SEARCH.md` — the rules (by `@`import)        | `memory/` — auto-memory                 |
| the **RTK** and **search guard** hooks (same abs. paths) | `settings.json` — plugins, model, theme |

What stays apart is what the Teams policy is about: who is logged in, and where
the conversation history and memory live. Everything shared is local tooling.

[RTK](rtk.md) crosses too. It was personal-only at first, on the reading that a
"token proxy" sits between the session and the network. It does not: it filters
command output on this machine and its telemetry is off, so it sends nothing the
policy cares about. The one consequence is that company command output lands in
RTK's local store (`~/.local/share/rtk/`: `history.db` and the plaintext tee
logs) next to personal output — on a par with shell history, and accepted.

`settings.json` is **not** shared, but no longer for RTK's sake: Claude Code
rewrites it per account (enabled plugins, model settings, theme), so each dir
keeps its own and both are wired to the same hook scripts.

The work `CLAUDE.md` is its own small file importing `~/.claude/RTK.md` and
`~/.claude/SEARCH.md` by absolute path. chezmoi writes it, and the `skills`
symlink, into `~/.claude.work` on every apply — the shared set is correct by
construction rather than by remembering a bootstrap step.

## Bootstrap (once, machine-local — not committed)

```sh
# 1. Apply the dotfiles: the fish wrappers, plus ~/.claude.work/CLAUDE.md and
#    the ~/.claude.work/skills symlink
chezmoi apply

# 2. Log in with the company Teams account
claude-work            # browser OAuth flow → approve as the company identity
```

Step 3: give the work dir a `settings.json` with the statusline and both hooks.
The commands point at the same absolute scripts the personal account uses
(`<you>` = your `$HOME` user). If Claude Code already wrote a `settings.json`
there, merge these keys into it:

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
        "hooks": [
          { "type": "command", "command": "rtk hook claude" },
          {
            "type": "command",
            "command": "bash /home/<you>/.claude/hooks/search-guard.sh"
          }
        ]
      }
    ]
  }
}
```

## Personal account bootstrap (new machine)

`chezmoi apply` drops `~/.claude/statusline-command.sh`, `~/.claude/CLAUDE.md`,
`~/.claude/RTK.md`, `~/.claude/SEARCH.md`, and `~/.claude/hooks/search-guard.sh`
— but **not** `settings.json` (see
[What's tracked](#whats-tracked-and-what-isnt) for why). Two manual steps wire up
the rest.

1. Point `settings.json` at the statusline and re-add both hooks — merge into
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
           "hooks": [
             { "type": "command", "command": "rtk hook claude" },
             {
               "type": "command",
               "command": "bash /home/<you>/.claude/hooks/search-guard.sh"
             }
           ]
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

3. Re-install the one cross-agent skill. `find-skills` comes from the
   `npx skills` manager (state in `~/.agents/.skill-lock.json`), not from a Claude
   plugin:

   ```sh
   npx skills@latest add vercel-labs/skills
   ```

> **Skills come from three places, on purpose.** Claude _plugins_ carry
> everything that has one: the `mattpocock-skills` plugin ships `grilling`,
> `grill-with-docs`, `research`, `domain-modeling`, `handoff` and the rest, so
> those are **not** installed per project — a project-level copy under
> `.claude/skills/` only duplicates the plugin and goes stale. The `npx skills`
> manager symlinks a skill into every agent's dir (`~/.agents` is its shared
> home); it is kept for what no plugin offers. The one hand-authored skill —
> [`git-workflow`](#whats-tracked-and-what-isnt) — is vendored into this repo and
> applied globally (it carries a personal default commit convention, and defers
> to whatever commit-msg check the repo it runs in enforces). The
> token-**proxy** layer is owned by [RTK](rtk.md), so no second proxy is
> installed alongside it. If Codex (or any second agent) is adopted, relocate
> `git-workflow` to `~/.agents/skills` and symlink it in, matching the manager's
> own layout.

## Search rule and guard hook

Agents search through the shell, and left alone they type `grep -r` and `find`.
Two pieces, shared by both accounts, move them to [`rg`](ripgrep.md) and
[`fd`](fd.md):

- **The rule** — [`SEARCH.md`](../home/dot_claude/SEARCH.md), imported from each
  account's `CLAUDE.md`. It names the tools, and it sets the **escalation
  ladder**: `rg` → `rg -uu`, `fd -H` → `fd -HI -E .git`, and no "it does not
  exist" until the unrestricted step comes back empty. `rg` and `fd` skip
  gitignored files without saying so; the ladder is what makes that safe.
- **The guard hook** —
  [`search-guard.sh`](../home/dot_claude/hooks/executable_search-guard.sh), a
  `PreToolUse` hook on Bash. A rule is advice; the hook is the part that holds.

The guard **refuses** and explains; it never rewrites. Translating `grep` to `rg`
or `find` to `fd` mechanically is not safe (different regex dialects, no 1:1 for
`find` expressions), and a refusal leaves the agent knowing which tool it is
running and what that tool cannot see.

| Command                                         | Guard   | Why                                            |
| ----------------------------------------------- | ------- | ---------------------------------------------- |
| `grep -rn foo docs` (`-r`, `-R`, `--recursive`) | refused | that is `rg`'s job                             |
| `find . -name '*.md'`                           | refused | that is `fd`'s job                             |
| `cmd \| grep foo`                               | allowed | filtering a stream — nothing is skipped        |
| `grep foo file.txt`                             | allowed | one named file — nothing is skipped            |
| `git grep foo`                                  | allowed | different tool, explicit scope (tracked files) |
| `command find …` · `command grep -r …`          | allowed | the escape hatch                               |

`command …` is for what `fd` and `rg` cannot express (`find -perm`, `-newer`,
`-delete`; POSIX BRE). It also sidesteps the RTK hook, so it runs the real tool
and sees every file. `rtk grep …` and `rtk find …` typed by hand are judged as
`grep` and `find`.

On both accounts the guard sits **next to** the RTK rewrite hook, and for
`find` that pairing matters. RTK alone turns `find` into `rtk find`, which is not
`find`: it skips gitignored files and dotfiles and rejects most predicates — the
agent types a tool that sees everything and silently gets one that does not
([rtk.md](rtk.md#what-rtk-can-cost-you)). Both hooks run in parallel on the same
call, and when they disagree Claude Code takes the strictest answer (`deny` >
`defer` > `ask` > `allow`), so the guard's refusal beats RTK's rewrite. Verified
in a live session: `find . -maxdepth 0` is refused, not run as `rtk find`.

Test the guard without Claude:

```sh
echo '{"tool_input":{"command":"find . -name x"}}' | bash ~/.claude/hooks/search-guard.sh
```

It fails open: no `jq`, or input it cannot parse, lets the command through. It is
a nudge for a cooperative agent, not a security boundary — a heredoc body or a
`bash -c '…'` string is not inspected.

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
- `home/dot_claude/CLAUDE.md` (`@RTK.md`, `@SEARCH.md`) and `RTK.md` — the
  personal global instructions. Secret-free and portable; the RTK proxy they
  describe is already tracked under [`dot_config/rtk`](../home/dot_config/rtk);
- `home/dot_claude.work/CLAUDE.md` and `symlink_skills` → `~/.claude.work/CLAUDE.md`,
  `~/.claude.work/skills` — the work account's share of the above: two absolute
  `@`imports and a symlink, no secrets, harmless on a machine with no work login;
- `home/dot_claude/SEARCH.md` and `home/dot_claude/hooks/executable_search-guard.sh`
  → `~/.claude/SEARCH.md`, `~/.claude/hooks/search-guard.sh` — the
  [search rule and guard](#search-rule-and-guard-hook), written to be
  account-neutral so the work dir can point at the same files;
- `home/dot_claude/skills/git-workflow/` → `~/.claude/skills/git-workflow` — the
  one hand-authored, repo-agnostic skill: it reads each repo's commit-msg check
  and falls back to a personal default convention, so it is vendored and
  available in every project. Everything else
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
reproducing (the statusline wiring, the two hooks, the plugin list) is captured as
a copy-paste bootstrap above instead.

## Related

- [git.md](git.md) — the same personal/work identity split for git (`includeIf`)
- [ghq.md](ghq.md) — where the company root (`ghqCompanyRoot`) comes from
- [direnv.md](direnv.md) — path-based env, the editor-proof upgrade
- [rtk.md](rtk.md) — the output filter behind the RTK hook, shared by both accounts
- [ripgrep.md](ripgrep.md) · [fd.md](fd.md) — the tools the search rule points at
- [ADR 0023](adr/0023-multi-account-claude-code-via-config-dir.md) — why this design
- [ADR 0002](adr/0002-private-data-via-templates.md) — private paths via templates

## References

- Claude Code — [`CLAUDE_CONFIG_DIR` / settings](https://docs.claude.com/en/docs/claude-code/settings)
