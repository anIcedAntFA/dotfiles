# HANDOFF — Git config → XDG layout + modern rewrite

Status: **implemented & committed on branch `feat/git-config-xdg`**, `just check`
green. Not yet applied to the live machine. Delete this file once the manual
steps below are done (see the `chore: remove completed HANDOFF note` precedent).

## What was done

Migrated git config from a single `~/.gitconfig` to the XDG `~/.config/git/`
directory and modernised every setting. Full rationale and structure live in
[`docs/git.md`](docs/git.md) — **read that, not a recap here**. The change set is
in the branch diff; key files:

- `home/dot_config/git/{config.tmpl,config-work.tmpl,ignore}` (new)
- `home/.chezmoiremove` (removes shadowing `~/.gitconfig*`)
- `home/.chezmoiscripts/run_onchange_after_setup-git-signers.sh.tmpl` (builds `~/.ssh/allowed_signers`)
- `packages/pacman-explicit.txt` (+`git-delta`, +`fzf`)
- Deleted `home/dot_gitconfig.tmpl`, `home/dot_gitconfig-company.tmpl`
- Doc reference fixups: `README.md`, `docs/{chezmoi,ssh,ghq}.md`

## Manual TODOs (owner: ngockhoi96 — run yourself)

1. **Install the two new packages:**

   ```sh
   yay -S --needed git-delta fzf
   ```

2. **Apply the config** (review the diff first — the first thing shown is the old
   `~/.gitconfig` being removed):

   ```sh
   chezmoi diff
   chezmoi apply
   ```

3. **Verify after apply:**

   ```sh
   git config --show-origin user.email                 # resolves from ~/.config/git/config
   cd ~/workspace/<company>/<repo> && git config user.email   # work identity via includeIf
   git log --show-signature -1                          # "Good" signature (allowed_signers built)
   git lg                                               # alias sanity-check; delta paging works
   ```

4. **`fu` alias needs fzf** (installed in step 1) — picks a recent commit, makes a
   `fixup!`, auto-squashed by next `git rebase -i` (`rebase.autoSquash` is on).
5. **Host-side signing enrollment** (one-time, not automatable) — GitHub: re-add
   `github.pub` as a _Signing key_; GitLab: delete + re-add `gitlab.pub` as
   _Authentication & Signing_. Steps in [`docs/git.md`](docs/git.md#signing-commits-with-ssh-not-gpg).

## Open / deferred (not done — decide next session)

- **Optional fish `g` abbr.** The dead `g = git` git alias was dropped. If you want
  a `g` shortcut it belongs in fish (`abbr -a g git` in `home/dot_config/fish/`).
  Not implemented — was left as an explicit offer.
- **Editor swap nano → nvim.** `core.editor = nano` for now; single-line change in
  `home/dot_config/git/config.tmpl` when you commit to nvim.

## Notes / caveats

- `chezmoi execute-template` couldn't render the template in this dev checkout
  ("no entry for key name") because chezmoi data isn't initialised here — the
  template _parses_ fine and reuses the exact variables from the old working
  files, so it will render on the real machine.
- No ADR created (config is reversible; `docs/git.md` holds the "why"). No
  `CONTEXT.md` (git terms are general, not domain-specific).

## Suggested skills

- **`git-workflow`** — for the commit of this branch (gitmoji + Conventional
  Commits per repo convention).
- **`verify`** — after `chezmoi apply`, to drive the aliases/signing/delta end-to-end.
