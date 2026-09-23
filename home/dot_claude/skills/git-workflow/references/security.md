# Security Reference

Secret scanning, response procedures, commit signing, and access control.

---

## Quick Scan (Manual)

Run on staged changes before committing:

```bash
git diff --cached -U0 | grep -nE \
  'AKIA[A-Z0-9]{16}|-----BEGIN .* PRIVATE KEY-----|xox[bpors]-|[sr]k_(live|test)_|ghp_[A-Za-z0-9]{36}|eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+|AIza[0-9A-Za-z_-]{35}|mongodb\+srv://[^[:space:]]+|postgres://[^[:space:]]+@' \
  && echo "SECRETS DETECTED — DO NOT COMMIT" || echo "Clean"
```

## Secret Patterns

| Category       | Pattern                          | Example                      |
| -------------- | -------------------------------- | ---------------------------- |
| AWS Access Key | `AKIA[A-Z0-9]{16}`               | `AKIAIOSFODNN7EXAMPLE`       |
| Private Key    | `-----BEGIN .* PRIVATE KEY-----` | PEM files                    |
| GitHub Token   | `ghp_`, `gho_`, `github_pat_`    | `ghp_abc123def456...`        |
| Slack Token    | `xox[bpors]-`                    | `xoxb-1234567890-abc`        |
| Stripe Key     | `[sr]k_(live                     | test)_`                      |
| Google API Key | `AIza` + 35 chars                | `AIzaSyA1b2c3d4...`          |
| JWT            | `eyJ...\.eyJ...`                 | `eyJhbGciOiJIUzI1NiJ9...`    |
| Database URL   | `protocol://user:pass@host`      | `postgres://admin:s3cret@db` |

---

## Gitleaks

Gitleaks runs automatically at **pre-push** via lefthook. It scans the entire
git history, not just staged files.

**Manual run:**

```bash
gitleaks git --verbose                    # scan full history
gitleaks git --pre-commit --staged        # scan staged only
gitleaks detect --source .                # scan working directory
```

**Configuration** (`.gitleaks.toml`):

```toml
[allowlist]
description = "Global allowlist"
paths = [
  '''vendor/''',
  '''node_modules/''',
  '''\.test\.''',
]

[[rules]]
id = "custom-api-key"
description = "Custom API key pattern"
regex = '''MYAPP_KEY_[A-Za-z0-9]{32}'''
```

**Adding exceptions:**

```toml
# Allow specific strings (false positives)
[allowlist]
commits = ["abc123def456"]              # specific commit hash
regexes = ['''EXAMPLE_KEY_[A-Z]+''']    # pattern to allow

# Inline suppression (in source code)
# gitleaks:allow
const EXAMPLE_KEY = "not-a-real-key"    # gitleaks:allow
```

---

## Response: Secrets Found BEFORE Push

The secret hasn't left your machine. You have time.

```bash
# 1. STOP — do not commit or push

# 2. Unstage the file
git restore --staged <file-with-secret>

# 3. Remove secret from source — use env var instead
#    const key = process.env.STRIPE_SECRET_KEY

# 4. Add to .gitignore if the file should never be tracked
echo ".env.local" >> .gitignore

# 5. Stage the cleaned version
git add <cleaned-file> .gitignore

# 6. Rotate the secret — treat it as compromised
#    Even if never pushed, it existed in a diff on disk
```

## Response: Secrets Found AFTER Push

The secret is compromised. Rotate first, clean history second.

```bash
# 1. ROTATE THE SECRET IMMEDIATELY
#    Generate new credentials in AWS/GitHub/Stripe console
#    Update all services using the old secret

# 2. Remove from history — BFG Repo-Cleaner (preferred)
brew install bfg
git clone --mirror git@github.com:org/repo.git
bfg --replace-text passwords.txt repo.git    # one secret per line
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force

# 3. Alternative — git-filter-repo
pip install git-filter-repo
git filter-repo --blob-callback '
  return blob.data.replace(b"sk_live_abc123", b"REDACTED")
'
git push --force origin --all
```

Force push rewrites history for all collaborators — coordinate with team.

---

## Files to Always Ignore

```gitignore
# Secrets and environment
.env
.env.*
!.env.example
.envrc

# Keys and certificates
*.pem
*.key
*.p12
*.pfx
id_rsa
id_ed25519

# Credential files
credentials.json
*secret*.json
service-account*.json
.npmrc
.pypirc

# OS
.DS_Store
Thumbs.db

# Dependencies
node_modules/
.venv/
__pycache__/

# Build output
dist/
build/
```

---

## Commit Signing

### SSH signing (recommended — simpler)

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

Add the same SSH public key to GitHub: **Settings > SSH and GPG keys** → key type "Signing Key".

### GPG signing

```bash
gpg --full-generate-key                            # RSA 4096
gpg --list-secret-keys --keyid-format=long         # copy key ID
gpg --armor --export <KEY_ID>                      # add to GitHub

git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```

Verify: `git log --show-signature -1`

---

## CODEOWNERS

Protect sensitive paths by requiring review from specific teams.

```
# .github/CODEOWNERS
/.env.example                @org/security
/.github/workflows/          @org/devops
/src/auth/                   @org/security @org/backend
/src/payments/               @org/billing @org/security
/migrations/                 @org/backend-leads
```

Enable: Repository Settings > Branch protection > Require review from Code Owners.

---

## GitHub Secret Scanning

```
Repository Settings > Code security and analysis > Secret scanning > Enable
Repository Settings > Code security and analysis > Push protection > Enable
```

False positive config (`.github/secret_scanning.yml`):

```yaml
paths-ignore:
  - "docs/**"
  - "tests/fixtures/**"
```
