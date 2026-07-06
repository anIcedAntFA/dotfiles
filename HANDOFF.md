# HANDOFF — work-access & tooling docs

> Transient continuation note (public-safe: no secrets/company data — all sensitive
> specifics live in the private gopass store or in `docs/*` with placeholders).
> Delete this file once the work below is picked up.

## Where things stand

- **Branch:** `feat/work-access-and-tooling-docs` (committed, **not pushed / no PR yet**).
- **Verification:** `just check` green (oxfmt, markdownlint, shellcheck, shfmt, fish,
  gitleaks), `just validate-niri` valid.
- **GitHub repo renamed** `linux-setup` → `dotfiles` (done). Local ghq folder kept as
  `linux-setup`; the `~/.local/share/chezmoi` symlink → that folder is intact and
  resolves (`chezmoi managed` lists ~113 paths). Full local-folder rename deliberately
  deferred (would need to fix the symlink + 8 hardcoded paths in
  `home/dot_config/noctalia/settings.json`).

## What shipped this branch

Docs/config for corporate access + tooling. Don't re-read the diffs — see:

- `docs/certs.md` + **ADR 0005** (`docs/adr/0005-system-certs-in-gopass.md`) — CA certs → gopass.
- `docs/vpn.md` + `home/dot_config/fish/functions/vpn-connect.fish.tmpl` (host = `{{ .workVpnPortal }}`).
- `docs/tuxedo.md` + niri `Mod+Shift+T` float keybind.
- `docs/chezmoi.md` — new **author edit-in-place** (symlink), **selective apply**, and
  **filename-not-templated** sections.
- `docs/git.md` — GitHub-vs-GitLab signing UX + `.gitconfig-company` literal note.
- `docs/gopass.md`, `docs/packages.md`, `docs/ghostty.md` (shaders vendored/MIT), rtk
  `filters.toml` tracked, `pw` alias, README/metadata renamed to `dotfiles`.

## Pending — manual steps only YOU can do (not doable in-session)

1. **Mark ripgrep explicit:** `sudo pacman -D --asexplicit ripgrep` (it's already listed
   in `packages/pacman-explicit.txt`; this makes reality match).
2. **Store the 3 corporate CA certs in gopass** then `gopass sync` — exact commands in
   `docs/certs.md` (`work/certs/vn-ca`, `aws-signin`, `aws-apps`).
3. **GitLab signing key:** delete the existing SSH key, re-add **once** with Usage type
   _Authentication & Signing_ (GitHub side already done). See `docs/git.md`.
4. **chezmoi first apply:** run `chezmoi init` (writes config only, no `$HOME` change),
   then apply **cluster by cluster** — `chezmoi diff ~/.gitconfig ~/.gitconfig-company`
   → `apply`, then `~/.config/fish`, etc. After the gitconfig include switches, `rm` the
   orphaned `~/.gitconfig-<old-slug>`. Full guide: `docs/chezmoi.md` (selective apply).

## Follow-ups / known issues (out of scope this branch)

- **Package snapshot drift** — `packages/pacman-explicit.txt` is out of sync with live
  `pacman -Qqe`: several wanted pkgs (incl. `gnupg`, `fd`, `github-cli`) lost explicit
  status; some tools (`just`, `lefthook`, `shellcheck`, `shfmt`) are explicit but
  untracked. **Do NOT blindly regenerate** (would drop wanted pkgs). Mark-explicit the
  wanted ones first, then regenerate. (Also saved in agent memory.)
- **noctalia `settings.json`** hardcodes 8 absolute repo paths (avatar/wallpapers) — not
  portable to a fresh machine/user. Worth templating or relativising.
- Consider whether `HANDOFF.md` should stay in the public repo long-term, or move to a
  private channel.

## Suggested skills for the next session

- **git-workflow** — if anything is left uncommitted; also to push + open the PR.
- **verify** — after `chezmoi apply`, confirm `pw`, `vpn-connect`, and work-repo signing
  (`git config user.signingkey` under the company ghq root) actually resolve.
- **grill-with-docs** — if picking up the follow-ups (package drift, noctalia paths).
