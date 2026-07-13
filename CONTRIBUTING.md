# Contributing

These are my personal dotfiles, but fixes, suggestions, and questions are
welcome. 🎉

## Ground rules

- **Never commit private data** — emails, tokens, passwords, work hostnames, or
  company names. Machine-specific values are handled by
  [chezmoi templates](docs/adr/0002-private-data-via-templates.md); secrets go in
  an untracked local file (see [docs/fish.md](docs/fish.md)).
- **Keep changes focused.** One concern per pull request.
- **Review before applying.** Understand what a config does before suggesting it.

## Local setup

```sh
mise trust     # once: allow this repo's mise.toml
just setup     # installs pinned tooling via mise (no Node) + git hooks
```

All dev tools (dprint, rumdl, shellcheck, shfmt, just, lefthook, gitleaks) are
pinned in [`mise.toml`](mise.toml) and installed by [mise](https://mise.jdx.dev/) —
there's no `package.json`. `fish_indent` comes with fish itself. See
[ADR 0007](docs/adr/0007-node-free-toolchain-via-mise.md).

This is a [chezmoi](https://www.chezmoi.io/) repo with `.chezmoiroot` pointing at
[`home/`](home/). Edit the source files under `home/` — not your live `$HOME`.
Files are named with chezmoi conventions (`dot_config/`, `private_dot_ssh/`,
`*.tmpl`); see the [chezmoi docs](https://www.chezmoi.io/reference/source-state-attributes/).

## Before you open a PR

```sh
just check     # runs exactly what CI runs
```

`just check` must pass. It runs:

- **dprint** — format check for Markdown, JSON/JSONC, YAML, TOML
- **rumdl** — Markdown rules (`.markdownlint.yml`)
- **shellcheck** + **shfmt** — shell scripts
- **fish_indent** — fish scripts
- **gitleaks** — secret scan

Auto-fix formatting with `just fmt`. The pre-commit hook (lefthook) runs these on
staged files automatically.

## Code style

Whitespace is governed by [`.editorconfig`](.editorconfig): **tabs** by default
(width 2), **spaces** for JSON and YAML (where tabs are invalid), LF line endings,
UTF-8, final newline. Your editor should apply this automatically.

## Commit messages

This repo uses [gitmoji](https://gitmoji.dev/) + a
[Conventional Commits](https://www.conventionalcommits.org/) scope, e.g.:

```text
✨ feat(niri): add scroll-to-workspace binding
🐛 fix(fish): stop sourcing missing local.fish
📝 docs(ssh): explain IdentitiesOnly
```

## Questions

Open a [discussion](https://github.com/anIcedAntFA/dotfiles/discussions) or an
issue.

By contributing, you agree your contributions are licensed under the
[MIT License](LICENSE).
