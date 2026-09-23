# Multiple Claude Code accounts via `CLAUDE_CONFIG_DIR`, keyed on the git company root

**Status:** accepted

We run a personal Claude subscription and a company **Teams** account on the same
machine. The Teams account carries the company's data-retention/privacy policy, so
company work must not run under the personal login. Claude Code has no account
switcher, but `CLAUDE_CONFIG_DIR` relocates an account's entire state — credential,
`projects/` history, skills, plugins, settings — so two dirs give two isolated
accounts.

## Decision

Drive `CLAUDE_CONFIG_DIR` from a directory boundary with three autoloaded fish
wrappers. `claude` auto-selects: inside the company ghq root it exports
`~/.claude.work`, elsewhere it uses the personal default `~/.claude`; `claude-work`
and `claude-personal` force a choice. The boundary is the **same**
`{{ .ghqCompanyRoot }}` template variable git's `includeIf` uses — one definition of
"this path is work" for both tools.

Choices worth recording:

- **Asymmetric dirs.** Personal stays the stock `~/.claude` (already logged in,
  no migration); only `~/.claude.work` is added. The symmetric alternative
  (`~/.claude.personal` + `~/.claude.work`, with an empty `~/.claude` as a
  "you forgot to pick" tripwire) was rejected as needless re-login + history
  migration for a fail-safe that a terminal-only launch path doesn't need.
- **fish wrapper, not direnv.** A wrapper needs zero per-repo files and covers the
  real launch path (the terminal). direnv would be editor-proof but wants a
  `.envrc` + `direnv allow` under the company root; recorded as the upgrade for if
  Claude ever gets launched from an editor.
- **Porous boundary, deliberately.** Skills and the statusline are shared across
  both accounts; `CLAUDE.md` (`@RTK.md`), `memory/`, history, credentials, and the
  RTK hook stay personal-only. `settings.json` is therefore _not_ shared — it
  carries the RTK command-rewrite hook — so the work dir gets its own hook-free
  `settings.json`, keeping RTK off every company session by construction.

## Consequences

- The company path never enters the public repo: `claude.fish.tmpl` renders
  `{{ .ghqCompanyRoot }}` per machine, and both config dirs (with plaintext
  `.credentials.json`) live untracked in `$HOME` — consistent with
  [ADR 0002](0002-private-data-via-templates.md).
- Only terminal launches auto-switch; an editor-launched session falls back to
  personal. Acceptable until something launches Claude outside fish, at which point
  add a company-root `.envrc`.
- The account signal depends on the statusline inheriting `CLAUDE_CONFIG_DIR` from
  the wrapper; if a future build stops passing it through, export a dedicated
  `CLAUDE_ACCOUNT` instead.
- Full guide: [docs/claude-code.md](../claude-code.md).
