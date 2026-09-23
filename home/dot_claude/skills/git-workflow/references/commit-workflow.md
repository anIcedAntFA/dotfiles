# Commit Workflow Reference

Step-by-step manual process for staging, analyzing, splitting, and committing.
This is the reference for when working without Claude Code automation.

---

## Stage Intentionally

Never blindly stage everything.

```bash
git add src/auth/login.ts src/auth/login.test.ts   # specific files
git add -p src/api/handler.ts                       # individual hunks
```

Interactive hunk prompts: `y` = stage, `n` = skip, `s` = split smaller, `q` = quit.

**Inspect staged changes:**

```bash
git diff --cached                   # full diff of staged
git diff --cached --stat            # summary: files, insertions, deletions
git diff --cached --name-only       # just file paths
git diff --cached --shortstat       # one-line: 3 files, +42, -17
```

**Unstage:**

```bash
git restore --staged <file>         # unstage one file
git restore --staged .              # unstage everything
```

---

## Split Decision

| Single commit                       | Split into multiple                   |
| ----------------------------------- | ------------------------------------- |
| Same type AND scope                 | Mixed types (feat + fix)              |
| ≤3 files                            | Mixed scopes (auth + billing)         |
| ≤50 lines total                     | >10 files across unrelated areas      |
| Splitting breaks intermediate state | Deps mixed with code changes          |
|                                     | Formatting mixed with logic changes   |
|                                     | Migration mixed with application code |

### Grouping example

```
Staged diff:
  M src/auth/login.ts         (feat — new OAuth flow)
  M src/auth/login.test.ts    (test — tests for OAuth)
  M src/billing/invoice.ts    (fix — tax calculation)
  M package.json              (chore — add oauth library)
  M bun.lock                  (chore — lockfile)

Split into 3 commits:
  1. package.json + bun.lock        → ⬆️ update-deps: add oauth2 client library
  2. src/auth/login.ts + test.ts    → ✨ feat(auth): add OAuth2 PKCE flow
  3. src/billing/invoice.ts         → 🐛 fix(billing): correct tax rate calculation
```

---

## Multi-Commit Execution

```bash
git restore --staged .

# --- Commit 1: deps ---
git add package.json bun.lock
git diff --cached --stat
git commit -m "⬆️ update-deps: add oauth2-client library"

# --- Commit 2: feature ---
git add src/auth/login.ts src/auth/login.test.ts
git diff --cached --stat
git commit -m "$(cat <<'EOF'
✨ feat(auth): add OAuth2 PKCE flow

- Implement authorization code flow with PKCE for mobile clients
- Use oauth2-client library for token exchange

Closes: #214
EOF
)"

# --- Commit 3: bugfix ---
git add src/billing/invoice.ts
git commit -m "🐛 fix(billing): correct tax rate for EU customers"
```

### Partial file staging

When one file contains changes for different commits:

```bash
git add -p src/api/handler.ts       # stage only relevant hunks
git commit -m "🐛 fix(api): validate request body before processing"

git add -p src/api/handler.ts       # stage remaining hunks
git commit -m "✨ feat(api): add rate limiting headers to response"
```

---

## Commit Message (manual)

**Single-line:**

```bash
git commit -m "✨ feat(scope): imperative description"
```

**Multi-line with HEREDOC:**

```bash
git commit -m "$(cat <<'EOF'
✨ feat(auth): add session timeout configuration

- Allow admins to configure session timeout per role
- Default remains 30 minutes, enterprise supports 24 hours
- Add timeout_minutes column to roles table

Closes: #187
EOF
)"
```

---

## Verify

```bash
git log --oneline -5                # confirm commits in history
git show --stat HEAD                # files and line counts in last commit
git status                          # working tree should be clean
```

### Amend (only before push)

```bash
# Safe — not yet pushed
git commit --amend -m "🐛 fix(api): correct the error message format"

# Already pushed — create a NEW commit instead
git commit -m "🐛 fix(api): update error message wording"
```

Never `git push --force` after amending shared history.

---

## Common Mistakes

| Mistake                     | Fix                                                 |
| --------------------------- | --------------------------------------------------- |
| `git add .` then commit     | Stage specific files, review with `--stat`          |
| Giant mixed commit          | Split by type and scope                             |
| Vague message: "fix bug"    | Be specific: "fix(cart): prevent negative quantity" |
| Past tense: "added feature" | Imperative: "add feature"                           |
| Amend after push            | New commit instead                                  |
