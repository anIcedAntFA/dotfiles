# Hooks & Tools Reference

Setup guide for lefthook, commitlint, and cz-git.

---

## Architecture Overview

```
pre-commit (fast, auto-fix)
├── biome check       → lint staged files
├── biome format      → format staged files
└── validate-branch   → enforce branch naming

commit-msg (validate message)
└── commitlint        → enforce conventional commit format

pre-push (slow, thorough)
├── type-check        → tsc per workspace
├── biome lint        → full project lint
└── gitleaks          → secret scanning
```

The principle: fast checks that auto-fix go in pre-commit, message validation
in commit-msg, and slow thorough checks in pre-push. This keeps the commit
cycle fast while catching serious issues before code leaves your machine.

---

## Lefthook

Git hooks manager. Replaces husky with better performance and simpler config.

**Install:**

```bash
# macOS / Arch / most systems — install once, globally
brew install lefthook        # macOS
sudo pacman -S lefthook      # Arch

# Init in repo (always needed, even with system install)
lefthook install
```

**Config** (`lefthook.yml`):

```yaml
pre-commit:
  parallel: true
  commands:
    biome-check:
      glob: "*.{js,ts,jsx,tsx,mjs,cjs,astro,svelte,json,jsonc,css,md,mdx}"
      run: bunx @biomejs/biome check --no-errors-on-unmatched --files-ignore-unknown=true {staged_files}
      stage_fixed: true
    biome-format:
      glob: "*.{js,ts,jsx,tsx,mjs,cjs,astro,svelte,json,jsonc,css,md,mdx}"
      run: bunx @biomejs/biome format --no-errors-on-unmatched --files-ignore-unknown=true --write {staged_files}
      stage_fixed: true

commit-msg:
  commands:
    commitlint:
      run: bunx commitlint --edit {1}

pre-push:
  parallel: true
  commands:
    check-types-site:
      run: "bun run --filter './apps/site' check:types"
    check-types-api:
      run: "bun run --filter './apps/api' check:types"
    biome-lint:
      run: bunx @biomejs/biome check .
    gitleaks:
      run: "gitleaks git --pre-commit --staged --verbose"
```

**Key options:**

- `parallel: true` — run commands simultaneously (faster)
- `glob` — only run on matching file types
- `stage_fixed: true` — auto-stage files that were auto-fixed
- `{staged_files}` — lefthook variable, expands to staged file list
- `{1}` — the commit message file path (for commit-msg hooks)

**Useful commands:**

```bash
lefthook install          # install hooks into .git/hooks/
lefthook uninstall        # remove hooks
lefthook run pre-commit   # manually run a hook stage
```

**Skip hooks temporarily:**

```bash
git commit --no-verify -m "🔨 chore: emergency fix"   # skip pre-commit + commit-msg
git push --no-verify                                    # skip pre-push
LEFTHOOK=0 git commit -m "..."                          # disable lefthook entirely
```

Use sparingly — hooks exist for good reason.

---

## Commitlint

Validates commit message format against conventional commit rules.

**Install:**

```bash
bun add -D @commitlint/cli
```

**Config** (`commitlint.config.mjs`):

```javascript
import { defineConfig } from 'cz-git';

const types = [
  '🎉 init',
  '✨ feat',
  '🐛 fix',
  '🚑️ hotfix',
  '📝 docs',
  '💄 style',
  '♻️ refactor',
  '⚡️ perf',
  '✅ test',
  '⬆️ update-deps',
  '🔧 configs',
  '🔨 chore',
  '💥 breaking',
  '🚀 deploy',
];

export default defineConfig({
  parserPreset: {
    parserOpts: {
      // Custom regex to parse emoji-prefixed types
      headerPattern: /^(?<type>.+?)(?:\((?<scope>.*)\))?!?:\s(?<subject>.+)$/,
      headerCorrespondence: ['type', 'scope', 'subject'],
    },
  },
  rules: {
    'body-leading-blank': [1, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'footer-leading-blank': [1, 'always'],
    'footer-max-line-length': [2, 'always', 100],
    'header-max-length': [2, 'always', 100],
    'header-trim': [2, 'always'],
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'type-enum': [2, 'always', types],
  },
  prompt: {
    // cz-git interactive prompt config (for manual use)
    useEmoji: true,
    emojiAlign: 'left',
    types: [
      { value: 'init',        name: 'init:            🎉  Begin a project.',           emoji: '🎉' },
      { value: 'feat',        name: 'feat:            ✨  A new feature',              emoji: '✨' },
      { value: 'fix',         name: 'fix:             🐛  A bug fix',                  emoji: '🐛' },
      { value: 'hotfix',      name: 'hotfix:          🚑️  Critical hotfix.',           emoji: '🚑️' },
      { value: 'docs',        name: 'docs:            📝  Documentation only changes', emoji: '📝' },
      { value: 'style',       name: 'style:           💄  Visual/formatting changes',  emoji: '💄' },
      { value: 'refactor',    name: 'refactor:        ♻️   Code restructure',           emoji: '♻️' },
      { value: 'perf',        name: 'perf:            ⚡️  Performance improvement',     emoji: '⚡️' },
      { value: 'test',        name: 'test:            ✅  Tests',                       emoji: '✅' },
      { value: 'update-deps', name: 'update-deps:     ⬆️  Upgrade dependencies.',       emoji: '⬆️' },
      { value: 'configs',     name: 'configs:         🔧  Config files.',               emoji: '🔧' },
      { value: 'chore',       name: "chore:           🔨  Maintenance",                 emoji: '🔨' },
      { value: 'breaking',    name: 'breaking-change: 💥  Breaking changes.',           emoji: '💥' },
      { value: 'deploy',      name: 'deploy:          🚀  Deploy stuff.',               emoji: '🚀' },
    ],
  },
});
```

**How it integrates:**

- Lefthook calls `bunx commitlint --edit {1}` at `commit-msg` stage
- Commitlint parses the message using the custom `headerPattern` regex
- The regex handles emoji-prefixed types: `✨ feat(scope): subject`
- If validation fails, the commit is rejected

**Rule reference:**

| Rule                 | Level    | Meaning                         |
| -------------------- | -------- | ------------------------------- |
| `[2, 'always', ...]` | Error    | Commit rejected if violated     |
| `[1, 'always', ...]` | Warning  | Shows warning but allows commit |
| `[0, ...]`           | Disabled | Rule not enforced               |

---

## cz-git

Interactive commit prompt. Used for **manual commits** (not Claude Code).

**Install:**

```bash
bun add -D cz-git commitizen
```

**Add to package.json:**

```json
{
  "config": {
    "commitizen": {
      "path": "node_modules/cz-git"
    }
  },
  "scripts": {
    "cz": "cz"
  }
}
```

**Usage:**

```bash
bun run cz          # interactive commit wizard
git cz              # alternative (if installed globally)
```

cz-git reads the `prompt` section of `commitlint.config.mjs` for its UI.
This means commitlint and cz-git share the same config file — single source
of truth for types, emojis, and rules.

**Aliases** (defined in config):

```bash
# Quick commits using aliases
bun run cz --alias=b    # → "🔨 chore: bump dependencies"
bun run cz --alias=c    # → "🔧 configs: update config files"
bun run cz --alias=f    # → "📝 docs: fix typos"
```

---

## Claude Code vs Manual Workflow

| Aspect                | Claude Code                  | Manual (cz-git)              |
| --------------------- | ---------------------------- | ---------------------------- |
| **Analyze diff**      | Automatic                    | You read the diff yourself   |
| **Choose type/scope** | Claude proposes              | cz-git prompts you           |
| **Write message**     | Claude drafts, you confirm   | You type it                  |
| **Validation**        | Lefthook + commitlint (same) | Lefthook + commitlint (same) |
| **Split commits**     | Claude suggests grouping     | You decide manually          |

Both paths go through the same lefthook hooks — validation is identical.

---

## New Project Setup Checklist

```bash
# 1. Install JS packages (lefthook and gitleaks are system-wide binaries, not devDeps)
bun add -D @commitlint/cli cz-git commitizen

# 2. Install lefthook hooks into .git/hooks/
lefthook install

# 3. Create config files
# - commitlint.config.mjs (see template above)
# - lefthook.yml (see template above)
# - .gitleaks.toml (optional, for allowlist rules)

# 4. Add to package.json scripts + commitizen config
# "cz": "cz"
# "config": { "commitizen": { "path": "node_modules/cz-git" } }

# 5. Verify
lefthook run pre-commit        # test pre-commit hooks manually
echo "test" | bunx commitlint  # test commitlint rejects bad messages
gitleaks detect --source .     # test gitleaks secret scan
```
