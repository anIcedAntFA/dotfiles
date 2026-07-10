# Git — one machine, two identities, signed commits

## Why

A single laptop carries two git identities: a **personal** one (GitHub) and a
**work** one (company GitLab). They must never bleed into each other — a work
email on a personal commit, or vice-versa, is the classic footgun. Git solves this
with **conditional includes** (`includeIf`) that switch identity by directory, and
this repo wires that up through chezmoi templates so no private value is committed.

The counterpart to identity is _authentication_ (which SSH key reaches which host)
— that's in [ssh.md](ssh.md). This page is about **config + signing**.

## The layout

Config lives in the XDG directory `~/.config/git/`, not a single `~/.gitconfig`.
Three source files, applied by chezmoi:

| Source (`home/dot_config/git/`)                               | Applies to                  | Role                                          |
| ------------------------------------------------------------- | --------------------------- | --------------------------------------------- |
| [`config.tmpl`](../home/dot_config/git/config.tmpl)           | `~/.config/git/config`      | default (personal) identity + shared settings |
| [`config-work.tmpl`](../home/dot_config/git/config-work.tmpl) | `~/.config/git/config-work` | work identity overrides                       |
| [`ignore`](../home/dot_config/git/ignore)                     | `~/.config/git/ignore`      | global gitignore (auto-detected)              |

The private bits (`{{ .email }}`, `{{ .name }}`, `{{ .workEmail }}`, `ghq` roots)
come from your `chezmoi init` answers — see [chezmoi.md](chezmoi.md).

> [!NOTE]
> **Config scope is by _layer_, not by directory tree.** `~/.config/git/config`
> and `~/.gitconfig` are the **same** scope (git's "global" layer) — the XDG path
> is just the modern location. It is _not_ scoped to `~/.config/*`; it applies to
> every repo, including `~/workspace/*`. The only way to scope config to a
> directory is `includeIf "gitdir:…"` (below). Because both files are global,
> `~/.gitconfig` — if present — is read _last_ and would **shadow** the XDG file.
> [`.chezmoiremove`](../home/.chezmoiremove) deletes the old `~/.gitconfig` and
> `~/.gitconfig-company` on apply so this can't happen; it also keeps future
> `git config --global …` writes flowing to the XDG file.

## Identity switching with `includeIf`

The default identity is personal. At the **bottom** of `~/.config/git/config`:

```gitconfig
[user]
	name = Your Name
	email = you@personal.example
	signingkey = ~/.ssh/github.pub

[includeIf "gitdir:~/workspace/company/"]
	path = ./config-work
```

`includeIf "gitdir:…"` pulls in `~/.config/git/config-work` **only** for repos under
that path. The relative `path = ./config-work` resolves next to the including file
(`~/.config/git/`). Because the include sits _after_ `[user]`, its values win there:

```gitconfig
# ~/.config/git/config-work
[user]
	email = you@company.example
	name  = Your Name
	signingkey = ~/.ssh/gitlab.pub
```

So any repo you clone under `~/workspace/company/…` is automatically your work
identity — email **and** signing key. Everything else stays personal. This pairs
with [ghq](ghq.md), which clones company repos under exactly that root. Verify:

```sh
cd ~/workspace/some-personal-repo && git config user.email   # personal
cd ~/workspace/company/some-repo   && git config user.email  # work
```

> The trailing slash in `gitdir:…/` matters, and `~` is expanded. Prefer
> `gitdir:` (case-sensitive) unless you specifically need `gitdir/i`.

One naming subtlety catches people out:

> [!NOTE]
> **`config-work` is a fixed filename, not your company name.** In the template
> the `gitdir` path is a variable (`{{ .ghqCompanyRoot }}` → e.g. `~/workspace/ndvn/`)
> but `path = ./config-work` is a literal — chezmoi can't template a target's
> _name_ ([chezmoi.md](chezmoi.md)). So the work file is always `config-work`
> regardless of the company slug; only its _directory match_ and _contents_
> (email, signingkey) reflect your `chezmoi init` answers.

## Signing commits with SSH (not GPG)

Commits and tags are signed so GitHub/GitLab show a **Verified** badge. We sign
with the **existing SSH key**, not GPG — no extra keys, no `gpg-agent`/`pinentry`,
and each identity signs with its own key. (Our one GPG key is dedicated to
[gopass](gopass.md); see [ADR 0004](adr/0004-terminal-password-manager-gopass.md).)

The config is in `config`:

```gitconfig
[gpg]
	format = ssh
[gpg "ssh"]
	allowedSignersFile = ~/.ssh/allowed_signers
[commit]
	gpgsign = true
[tag]
	gpgsign = true
```

**Local verification is automated.** The
[`run_onchange_after_setup-git-signers.sh.tmpl`](../home/.chezmoiscripts/run_onchange_after_setup-git-signers.sh.tmpl)
script builds `~/.ssh/allowed_signers` from whichever of `~/.ssh/github.pub` /
`~/.ssh/gitlab.pub` exist, pairing each with its identity email. It re-runs when
an email changes. That's why `git log --show-signature` reports _Good_ locally —
no manual step. (The pubkeys are machine-local and never committed, so the file
is generated on each box rather than templated.)

One one-time step you still do by hand — **tell the host it's a signing key**
(the UX differs per host):

- **GitHub** (_Settings → SSH and GPG keys_): add `~/.ssh/github.pub` a **second**
  time with key type **Signing key**. GitHub treats auth and signing as separate
  entries, so the same key appears twice.
- **GitLab** (_Preferences → SSH Keys_): GitLab uses **one** entry per key with a
  **Usage type**, and won't accept the same key twice (`Fingerprint … already been
taken`). So **delete** the existing `gitlab.pub` (auth-only) entry and **re-add
  it once** with Usage type **Authentication & Signing**.

Check it works:

```sh
git commit -m "test"          # signed automatically
git log --show-signature -1    # "Good \"git\" signature ..."
```

## The rest of `config`

Beyond identity and signing, `config` adopts a modern, DX-focused baseline. The
picks follow the consensus of the git core developers (see [References](#references)).

- **Diff pager: [delta](https://github.com/dandavison/delta)** (`core.pager`,
  `interactive.diffFilter`, `[delta]`). Syntax-highlighted, line-numbered diffs;
  `n`/`N` navigate between files. Requires the `git-delta` package.
- **Editor: `nano`** (`core.editor`). Switching to `nvim` later is a one-line
  change on that key.
- **Better defaults** (strictly nicer, no downside): `column.ui`, `branch.sort`,
  `tag.sort`, `diff.algorithm = histogram`, `diff.colorMoved`, `diff.mnemonicPrefix`,
  `push.autoSetupRemote`, `push.followTags`, `fetch.prune`/`pruneTags`,
  `commit.verbose`, `help.autocorrect = prompt`, `init.defaultBranch = main`.
- **Rebase-first workflow**: `pull.rebase`, `rebase.autoSquash`/`autoStash`, and
  `rebase.updateRefs` (rebasing the bottom of a stack moves every branch above it)
  — plus `rebase.missingCommitsCheck = error` so an interactive rebase can't silently
  drop a commit. `merge.conflictStyle = zdiff3` shows the common ancestor in conflicts.
- **`rerere`** records conflict resolutions and replays them, so repeated
  rebase/merge conflicts only get solved once (`enabled` + `autoupdate`).
- **Data integrity**: `transfer`/`fetch`/`receive.fsckObjects` detect repo
  corruption eagerly on transfer.
- **`url.insteadOf`** rewrites `https://github.com/anIcedAntFA/…` to SSH — but only
  _your own_ namespace, so public clones and Go modules keep using HTTPS.
- **`gh` credential helper** is wired only if `gh` is installed (template `lookPath`).
- **`ghq` roots** — `ghq.root` (personal) and a host-scoped root for company repos
  keep clones organised. See [ghq.md](ghq.md).

### Aliases

Short forms grouped by workflow area: staging/commit (`a`, `ap`, `ci`, `cm`, `ca`,
`cam`, `cane`, `cf`, `undo` = `reset --soft HEAD~1`, `unstage`), branches (`br`,
`ba`, `bm`, `bn`, `bda`, `co`, `cob`), sync (`pr` = `pull --rebase`, `pf` =
`push --force-with-lease --force-if-includes`, `f`, `rpo`), rebase (`rb`, `ri`,
`rc`, `rab`), cherry-pick (`cp`, `cpc`, `cpa`), worktree (`wt`, `wta`, `wtl`,
`wtr`), and inspection (`st`, `s`, `d`, `dc`, `rl`, `last`, `lg`).

Two worth calling out:

- **`bda`** force-cleans branches already merged into develop/master/main. It uses
  `-d` (safe — refuses unmerged branches), and is a shell alias (leading `!`) so its
  pipeline actually runs.
- **`fu`** picks a recent commit in an `fzf` list and creates a `fixup!` commit
  targeting it; the next `git rebase -i` auto-squashes it (`rebase.autoSquash`).
  Requires the `fzf` package.

### Global gitignore

`~/.config/git/ignore` is auto-detected by git (no `core.excludesfile` needed). It
holds only universal cruft — editor swap files, `.direnv/`, `__pycache__`,
`**/.claude/settings.local.json`. Project-specific ignores belong in each repo's
own `.gitignore`. Note `.vscode/` is deliberately _not_ ignored globally, since
projects sometimes commit shared workspace settings.

## `gh` — GitHub from the terminal

[`github-cli`](https://cli.github.com/) (`gh`) handles PRs, issues, releases, and
auth without leaving the shell:

```sh
gh auth login              # once, per host
gh pr create --fill        # open a PR from the current branch
gh pr checkout 123         # check out someone's PR
```

`gh auth login` can also configure git to use HTTPS with a token — since we use SSH
(see [ssh.md](ssh.md)), choose **SSH** when it asks, so `gh` and `git` agree.

## Related

- [ssh.md](ssh.md) — the SSH keys these identities authenticate with
- [ghq.md](ghq.md) — why company repos land under the work `includeIf` path
- [chezmoi.md](chezmoi.md) — how the templated gitconfig is rendered

## References

- [git-config — `includeIf`](https://git-scm.com/docs/git-config#_conditional_includes)
- [How core git devs configure git](https://blog.gitbutler.com/how-git-core-devs-configure-git)
- [Popular git config options — Julia Evans](https://jvns.ca/blog/2024/02/16/popular-git-config-options/)
- [GitHub: SSH commit signature verification](https://docs.github.com/authentication/managing-commit-signature-verification/about-commit-signature-verification)
