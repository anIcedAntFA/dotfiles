# Commit Conventions Reference

Complete rules for Conventional Commits with gitmoji in this project.

---

## Message Format

```
emoji type(scope): subject

[optional body]

[optional footer(s)]
```

- Header line: mandatory, ≤100 characters total (including emoji)
- Body: separated from header by one blank line, wrap at 100 chars
- Footer: separated from body by one blank line

---

## Types (Priority Order)

When a commit includes multiple concerns, pick the highest-priority type.

| #  | Type          | Emoji | Description                     | Example                                              |
| -- | ------------- | ----- | ------------------------------- | ---------------------------------------------------- |
| 1  | `init`        | 🎉    | Project kickoff                 | `🎉 init(all): scaffold project structure`           |
| 2  | `feat`        | ✨    | New user-facing feature         | `✨ feat(cart): add quantity selector`               |
| 3  | `fix`         | 🐛    | Bug fix                         | `🐛 fix(auth): prevent session timeout on refresh`   |
| 4  | `hotfix`      | 🚑️    | Critical production fix         | `🚑️ hotfix(api): patch null pointer in payment flow` |
| 5  | `refactor`    | ♻️     | Restructure, no behavior change | `♻️ refactor: extract validation into shared utils`   |
| 6  | `perf`        | ⚡️    | Performance improvement         | `⚡️ perf(db): add index on users.email`              |
| 7  | `test`        | ✅    | Tests only                      | `✅ test(api): add integration tests for /orders`    |
| 8  | `docs`        | 📝    | Documentation only              | `📝 docs: update API authentication guide`           |
| 9  | `update-deps` | ⬆️     | Dependency upgrades             | `⬆️ update-deps: upgrade react from 18.2 to 19.0`     |
| 10 | `configs`     | 🔧    | Config file changes             | `🔧 configs(biome): enable sorted imports rule`      |
| 11 | `chore`       | 🔨    | Maintenance, tooling            | `🔨 chore: clean up unused scripts`                  |
| 12 | `style`       | 💄    | CSS/visual, formatting only     | `💄 style: fix indentation in config files`          |
| 13 | `breaking`    | 💥    | Breaking changes                | `💥 breaking(api): require auth for all endpoints`   |
| 14 | `deploy`      | 🚀    | Deployment                      | `🚀 deploy(cloudflare): deploy production`           |

---

## Scope

The scope narrows down which area of the codebase was affected.

**Rules:**

- Lowercase, single word or hyphenated
- Derive from directory/module names: `src/auth/` → `auth`
- Keep consistent — don't alternate between `auth` and `authentication`
- Omit when changes span many unrelated areas

**Common scopes:** `api`, `auth`, `ui`, `db`, `cli`, `config`, `deps`, `core`,
`resume`, `seo`, `cf`, `pwa`, `rss`, `css`, `content`

**When to omit:**

- Change touches many modules equally: `♻️ refactor: rename userId to id`
- Scope adds no useful info: `🔨 chore: update lockfile`

---

## Subject

The text after `type(scope):` — this is what people read in `git log --oneline`.

1. **Imperative present tense** — "add", "fix", "remove" (not "added", "fixes")
2. **Lowercase first letter** — `fix: correct null check` not `fix: Correct null check`
3. **No period** at the end
4. **Describe the what** from a user/system perspective

Verification trick: your subject should complete "If applied, this commit will ___."

```
✨ feat(search): add autocomplete suggestions
→ "this commit will add autocomplete suggestions" ✓

✨ feat(search): added autocomplete suggestions
→ "this commit will added autocomplete suggestions" ✗
```

---

## Body

Include when the subject alone doesn't explain **why** the change exists.

**When to include:**

- Non-obvious bug fix (explain root cause)
- Trade-offs or alternatives considered
- Workaround with known limitations
- Context others need for a migration or refactor

**Format:**

- Each bullet starts with a verb: Add, Fix, Remove, Update, Refactor, Extract
- One fact per bullet — no filler
- Explain why, not what (the diff shows what)

```
🐛 fix(payments): retry failed charges with exponential backoff

- Stripe webhook delivery was unreliable during high traffic
- Charges marked as failed were not retried, causing lost revenue
- Add backoff (1s, 2s, 4s, 8s, max 5 retries) to handle transient errors
```

---

## Footer

**Issue/ticket references:**

- `Closes: #123` — GitHub issue (auto-closes on merge)
- `Fixes: #456` — same behavior as Closes
- `Refs: ELWB-1234` — external ticket reference (Jira, Linear, etc.)
- Multiple issues: one per line

```
✨ feat(auth): add refresh token rotation

- Implement automatic token refresh on 401 response
- Store refresh token in httpOnly cookie

Closes: #891
Refs: ELWB-1234
```

**Only include when:**

- User explicitly mentions a ticket/issue number
- The commit clearly resolves a tracked issue

---

## Breaking Changes

Two ways to mark:

1. Add `!` after type/scope:

```
💥 breaking(api)!: require authentication for all endpoints
```

2. Add `BREAKING CHANGE:` footer:

```
💥 breaking(api): require authentication for all endpoints

BREAKING CHANGE: all endpoints now require Bearer token.
Unauthenticated requests return 401.
```

---

## Special Rules

**AI attribution:** Never include. No "Generated by", "Co-Authored-By: AI",
or any AI tool credit in the commit message.

**.claude directory:**

- Commits only touching `.claude/` → `📝 docs(.claude): description`
- When `.claude/` changes accompany code → use the code change's type/scope,
  don't split `.claude/` into its own commit

---

## Good Examples

```
✨ feat(search): add autocomplete suggestions dropdown

⬆️ update-deps: upgrade react from 18.2 to 19.0

🐛 fix(api): prevent duplicate webhook deliveries

- The dispatcher retried on HTTP 202, treating them as failures
- Now only 4xx/5xx responses trigger retries

Closes: #342

♻️ refactor: extract validation logic into shared utility module

- Five controllers duplicated email and phone validation
- Centralize into src/utils/validators.ts

🚀 deploy(cloudflare): deploy v2.1.0 to production
```

## Bad Examples

```
feat: Changes                              ← vague, no emoji, capitalized
fixed the login bug.                       ← no type/emoji, past tense, period
✨ feat(auth): Add OAuth2 and fix billing  ← mixed concerns, capitalized
```
