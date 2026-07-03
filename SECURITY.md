# Security Policy

These are personal dotfiles, but because the repo is public it deliberately
contains **no secrets** — machine-specific and identity values are injected by
[chezmoi](https://www.chezmoi.io/) templates at apply time (see
[docs/adr/0002](docs/adr/0002-private-data-via-templates.md)), and every commit
is scanned with [gitleaks](https://github.com/gitleaks/gitleaks) via the
pre-commit hook and CI.

## Reporting a vulnerability

If you find a leaked secret, a credential, or any private data in this repo or
its history, please **do not open a public issue**. Instead, email
`ngockhoi96.dev@gmail.com` with the details so it can be rotated and purged.

## If you fork or reuse these dotfiles

- Never hard-code tokens or passwords in tracked files. Put machine-local
  secrets in an untracked file (e.g. `~/.config/fish/local.fish`) that is
  sourced at runtime.
- Run `just secrets` (gitleaks) before pushing.
- Supply your own values via `chezmoi init` prompts — do not commit them.
