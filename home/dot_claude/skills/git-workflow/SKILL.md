---
name: git-workflow
description: >
  Commit git changes as atomic commits with gitmoji + Conventional Commit
  messages that pass the repo's own commit-msg check. Also sets up commit hooks
  (lefthook, commit-msg lint) and handles secret scanning or a leaked secret.
  Use when the user asks to commit, asks how to word or split a commit, sets up
  git hooks, or scans for secrets.
---

# Git Workflow

Two branches: **Commit** (most runs) and **Setup** (one-time). Pick from the request.

## Commit

### 1. Read the changes and the convention

Run together:

```bash
git status --short
git diff HEAD
git log --format=%s -20
ls commitlint.config.* .commitlintrc* .husky/commit-msg 2>/dev/null
rg -n -A8 '^commit-msg:' lefthook.yml 2>/dev/null
```

The repo's **enforced convention** is whatever its commit-msg check accepts: the
`type-enum` list in a commitlint config, or the type alternation in a hook's
regex. Read the file the commands above turn up. It overrides everything in
this skill.

Where the repo enforces nothing, follow the convention the last 20 subjects
share. Where they share none, use the **default convention** in step 3.

Done when you can state three things: the accepted types, whether a leading
emoji is required, and the header length limit.

### 2. Group into atomic commits

Group the changed files by concern. One commit per group; a group is **atomic**
when it has one type, one scope, and leaves the repo working on its own.

| One commit                               | Split                               |
| ---------------------------------------- | ----------------------------------- |
| Same type and scope                      | Mixed types (feat + fix)            |
| Splitting would break intermediate state | Mixed scopes (auth + billing)       |
|                                          | Deps mixed with code changes        |
|                                          | Formatting mixed with logic changes |

One file holding two concerns is split by hunk (`git add -p`), not kept whole.

### 3. Write each message

```text
emoji type(scope): subject

- Body bullet
- Body bullet

Closes: #123
```

**Default convention** — type and emoji, highest priority first when a group
could take two:

| Type          | Emoji | When                             |
| ------------- | ----- | -------------------------------- |
| `init`        | 🎉    | Project kickoff                  |
| `feat`        | ✨    | New user-facing capability       |
| `fix`         | 🐛    | Bug fix                          |
| `hotfix`      | 🚑️    | Critical production fix          |
| `refactor`    | ♻️     | Restructure, behaviour unchanged |
| `perf`        | ⚡️    | Performance improvement          |
| `test`        | ✅    | Tests only                       |
| `docs`        | 📝    | Documentation only               |
| `update-deps` | ⬆️     | Dependency upgrades              |
| `configs`     | 🔧    | Config file changes              |
| `chore`       | 🔨    | Maintenance, tooling             |
| `style`       | 💄    | Visual changes, formatting only  |
| `breaking`    | 💥    | Breaking change                  |
| `deploy`      | 🚀    | Deployment                       |

**Under an enforced convention that lacks the default type**, keep the emoji and
take the nearest accepted type:

| Default type  | Use instead                      |
| ------------- | -------------------------------- |
| `configs`     | `chore`                          |
| `update-deps` | `build`, else `chore`            |
| `init`        | `chore`                          |
| `hotfix`      | `fix`                            |
| `breaking`    | the change's real type, with `!` |
| `deploy`      | `ci`, else `chore`               |

A commitlint `type-enum` whose entries carry the emoji (`'🔨 chore'`) fixes the
pair: use an entry verbatim, since `🔧 chore` fails where `🔨 chore` passes. A
convention with no emoji (a repo whose checked subjects carry none) gets none.

- **Scope**: lowercase, one word or hyphenated, taken from the path
  (`src/auth/` → `auth`) and spelled the way `git log` already spells it. Omit
  when the group spans unrelated areas.
- **Subject**: imperative, lowercase first letter, no trailing period. Header
  within the limit from step 1 (100 by default).
- **Body**: include when the subject cannot carry the reason. Bullets, each
  opening with a verb, each stating why rather than repeating the diff. Wrap at
  100.
- **Footer**: `Closes: #123` or `Refs: ABC-123`, one per line, only for a
  ticket the user named or the commit plainly resolves.
- The message ends at the footer. Authorship lives in the commit's author
  field, so it carries no attribution trailer of any kind.

Detailed rules and worked examples: `references/commit-conventions.md`.

### 4. Confirm the plan — only when it has more than one commit

A single commit goes straight to step 5.

For two or more, show every message in its own code block with the files it
takes, then ask **"Commit this plan? (yes / edit / cancel)"** and wait. The
grouping is what the user is approving: a wrong split means rewriting history,
where a wrong word is one `--amend`.

### 5. Commit, one at a time

Order: deps → refactors → features → fixes → docs. For each commit:

1. Stage by explicit path: `git add path/a path/b`, or `git add -p path` for
   some hunks. Leave out secrets and env files, anything gitignored, and
   lockfiles or generated files unless they are what the commit is about.
2. `git diff --cached --stat` lists exactly this commit's files.
3. Commit through a heredoc so the body keeps its lines:

   ```bash
   git commit -m "$(cat <<'EOF'
   ✨ feat(scope): subject

   - Bullet one
   - Bullet two
   EOF
   )"
   ```

4. The commit **landed** when `git log -1 --format=%s` prints the header you
   wrote and `git diff --cached --quiet` exits 0.

A rejected commit lands nothing and leaves its files staged, so the next
`git commit` would swallow them. On a rejection, fix the cause and retry the
same commit: reword for a commit-msg failure, fix and re-stage the file for a
lint or format failure. Start the next commit only after this one landed.

After the last one, show `git log --oneline -N` for the N commits made. For a
single commit made without asking, show its message too, so the user can ask for
a reword.

## Setup

Read the reference that matches the request:

- **`references/hooks-and-tools.md`** — lefthook plus a commit-msg check, in two
  variants: commitlint + cz-git for a repo with a `package.json`, and a
  dependency-free `grep` hook for one without. Read when setting up hooks or
  commit linting.
- **`references/security.md`** — gitleaks, what to do when a secret is found
  before or after a push, commit signing, CODEOWNERS. Read for secret scanning
  or a leaked secret.
- **`references/commit-conventions.md`** — scope, subject, body, footer and
  breaking-change rules with good and bad examples. Read when asked about
  message conventions.
- **`references/commit-workflow.md`** — staging, hunk-level `git add -p`,
  amending, done by hand. Read when the user wants the manual process.
