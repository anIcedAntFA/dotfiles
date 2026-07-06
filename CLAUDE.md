# CLAUDE.md

Guidance for AI agents working in this repo. Keep changes surgical and verified.

## What this is

Personal **dotfiles** for an EndeavourOS (Arch) desktop — niri compositor +
Noctalia shell, fish, Ghostty. Managed with [chezmoi](https://www.chezmoi.io/).
The repo is **public** and feeds a blog, so it must stay free of private data.

## Non-negotiable rules

1. **Never commit secrets or private data** — tokens, passwords, real emails,
   work hostnames, company names. Machine/identity values are chezmoi template
   variables (`{{ .email }}`, `{{ .workGitHost }}`…) filled from
   `~/.config/chezmoi/chezmoi.toml` (gitignored). Machine-local secrets go in an
   untracked file (e.g. `~/.config/fish/local.fish`), never in the repo.
   `gitleaks` guards this via the pre-commit hook and CI.
2. **Edit source files under `home/`, not your live `$HOME`.** `.chezmoiroot`
   points chezmoi at `home/`. Source files use chezmoi naming: `dot_config/` →
   `~/.config/`, `private_dot_ssh/` → `~/.ssh/` (0600), `*.tmpl` = templated.
3. **System files under `etc/` are NOT chezmoi-managed.** They mirror `/etc/*`
   and are applied by hand (`sudo cp`), documented per guide. Keep them at the
   repo root, never under `home/`.
4. **Run `just check` before committing.** It's what CI runs.

## Layout

```text
home/        chezmoi source (dot_config/, private_dot_ssh/, *.tmpl, .chezmoi.toml.tmpl)
docs/        per-tool guides + adr/ (Architecture Decision Records)
packages/    pacman-explicit.txt + aur.txt snapshots
etc/         /etc system files (manual apply)
images/      screenshots & wallpapers
```

## Toolchain

- `just fmt` — format everything · `just check` — format-check + lint + secret scan
- **oxfmt** formats md/json/jsonc/yaml/toml (config `.oxfmtrc.json`, embedded
  formatting is **off** so code samples in docs stay verbatim)
- **markdownlint-cli2** (`.markdownlint.yml`) — MD013/MD043 are intentionally off
- **shellcheck** + **shfmt** (shell), **fish_indent** (fish — canonical, forces
  4 spaces; `.editorconfig` matches), **gitleaks** (`.gitleaks.toml`)
- **KDL** (niri) isn't formatted — validate with `just validate-niri`
- oxfmt + markdownlint-cli2 install via `pnpm`; the rest via `just setup` (yay)

## Conventions

- Whitespace: `.editorconfig` (tabs default; spaces for JSON/YAML; 4-space fish).
- Commits: gitmoji + Conventional Commits, e.g. `✨ feat(niri): …`, `🐛 fix(fish): …`.
- Searching: prefer `rg` (ripgrep — installed) over `grep` in shell commands;
  it's `.gitignore`-aware and faster. Don't alias `grep` itself.

## Adding a new config

1. Put the file under `home/dot_config/<app>/…` (dotfiles inside also get `dot_`).
2. Needs a private/per-machine value? Rename to `…​.tmpl`, use `{{ .var }}`, and
   add a prompt to `home/.chezmoi.toml.tmpl`.
3. Worth explaining? Add/extend a guide in `docs/` and link it from the README.
4. `just fmt && just check`.

## Gotchas

- Don't format app-managed configs (e.g. `home/dot_config/noctalia/**` is
  excluded in `.oxfmtrc.json`).
- A hard-to-reverse decision with real trade-offs → record an ADR in `docs/adr/`.
