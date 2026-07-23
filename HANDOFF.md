# Handoff — starship prompt migration

**Branch:** `feat/starship-ansi-palette` (off `main`)
**Repo:** public dotfiles (EndeavourOS/Arch, niri + Noctalia, chezmoi). Never
commit secrets or private data; run `just check` before committing.

## What this change does

Migrates the starship prompt from a static config to a templated one that tracks
the desktop light/dark mode for free, and documents the reasoning.

- `home/dot_config/starship/starship.toml` → **`starship.toml.tmpl`** (renamed).
  Every module `style` now uses **ANSI colour names** (`red`, `cyan`,
  `bright-black`…) instead of hex, so the prompt resolves against Ghostty's
  palette slots and follows the Latte/Dracula swap automatically. Two brand marks
  (bun `#f9f1e1`, Cloudflare `#f6821f`) keep hex on purpose. Upstream preset
  256-colour indices (`c`/`cpp`/`php`/`package`/`terraform`) were remapped to the
  nearest ANSI name and marked `# was NNN`.
- New chezmoi template var **`hostAlias`** — short label the prompt shows instead
  of the real hostname (keeps work/company hostnames out of the public repo).
  Added to `home/.chezmoi.toml.tmpl` (prompt + `[data]`), documented in
  `README.md` and `docs/chezmoi.md`.
- New guide **`docs/starship.md`** (prompt layout, TOML quoting trap, module cost).
- New **`docs/adr/0009-starship-ansi-colours-over-hex-palette.md`** — full
  rationale for ANSI-over-hex and the rejected alternatives. Read this first.
- `.gitignore`: adds `skills-lock.json`.

## Where the detail lives (don't re-summarise)

- Design rationale + rejected options: `docs/adr/0009-starship-ansi-colours-over-hex-palette.md`
- User-facing guide: `docs/starship.md`
- Actual changes: `git diff` on this branch (all changes are currently unstaged).

## State / next steps

- All changes are **unstaged** in the working tree. Nothing committed yet on this
  branch (this handoff commit aside).
- The rename shows as `RM home/dot_config/starship/starship.toml -> …toml.tmpl`;
  stage both sides so git records it as a rename.
- Before committing the feature: run `just check` (dprint format-check + rumdl +
  gitleaks). Note the vendored/app-managed excludes in `dprint.json`.
- Verify the templated `hostAlias` renders: `chezmoi execute-template` or a dry
  `chezmoi apply -n`.

## Suggested skills

- **git-workflow** — stage and split into atomic gitmoji + Conventional Commit(s)
  (likely a `✨ feat(starship): …` for the config/template plus a `📝 docs`
  follow-up, or fold per the repo's fewer-denser-commits preference), then commit.
