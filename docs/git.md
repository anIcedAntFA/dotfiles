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

Two templated source files, applied by chezmoi:

| Source                                                             | Applies to             | Role                        |
| ------------------------------------------------------------------ | ---------------------- | --------------------------- |
| [`dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl)                 | `~/.gitconfig`         | default (personal) identity |
| [`dot_gitconfig-company.tmpl`](../home/dot_gitconfig-company.tmpl) | `~/.gitconfig-company` | work identity overrides     |

The private bits (`{{ .email }}`, `{{ .name }}`, `{{ .workEmail }}`, `ghq` roots)
come from your `chezmoi init` answers — see [chezmoi.md](chezmoi.md).

## Identity switching with `includeIf`

The default identity is personal. At the **bottom** of `~/.gitconfig`:

```gitconfig
[user]
	email = you@personal.example
	name  = Your Name
	signingkey = ~/.ssh/github.pub

[includeIf "gitdir:~/workspace/company/"]
	path = ./.gitconfig-company
```

`includeIf "gitdir:…"` pulls in `~/.gitconfig-company` **only** for repos under
that path. Because the include sits _after_ `[user]`, its values win there:

```gitconfig
# ~/.gitconfig-company
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
> **`.gitconfig-company` is a fixed filename, not your company name.** In the
> template, the `gitdir` path is a variable (`{{ .ghqCompanyRoot }}` → e.g.
> `~/workspace/ndvn/`) but `path = ./.gitconfig-company` is a literal — chezmoi can't
> template a target's _name_ ([chezmoi.md](chezmoi.md)). So the work file is always
> `~/.gitconfig-company` regardless of the company slug; only its _directory match_
> and _contents_ (email, signingkey) reflect your `chezmoi init` answers. If an older
> setup left a `~/.gitconfig-ndvn`, applying repoints the include to
> `.gitconfig-company` and the old file becomes an orphan you can `rm`.

## Signing commits with SSH (not GPG)

Commits and tags are signed so GitHub/GitLab show a **Verified** badge. We sign
with the **existing SSH key**, not GPG — no extra keys, no `gpg-agent`/`pinentry`,
and each identity signs with its own key. (Our one GPG key is dedicated to
[gopass](gopass.md); see [ADR 0004](adr/0004-terminal-password-manager-gopass.md).)

The config is already in the templates:

```gitconfig
[gpg]
	format = ssh
[commit]
	gpgsign = true
[tag]
	gpgsign = true
```

Two one-time steps you still do by hand:

1. **Tell the host it's a signing key** — the UX differs per host:
   - **GitHub** (_Settings → SSH and GPG keys_): add `~/.ssh/github.pub` a **second**
     time with key type **Signing key**. GitHub treats auth and signing as separate
     entries, so the same key appears twice.
   - **GitLab** (_Preferences → SSH Keys_): GitLab uses **one** entry per key with a
     **Usage type**, and won't accept the same key twice (`Fingerprint … already
been taken`). So **delete** the existing `gitlab.pub` (auth-only) entry and
     **re-add it once** with Usage type **Authentication & Signing**.

2. **(Optional) Verify signatures locally.** Point git at an allowed-signers file so
   `git log --show-signature` says _Good_:

   ```sh
   echo "you@personal.example $(cat ~/.ssh/github.pub)" >> ~/.ssh/allowed_signers
   git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
   ```

Check it works:

```sh
git commit -m "test"          # signed automatically
git log --show-signature -1    # "Good \"git\" signature ..."
```

## The rest of `~/.gitconfig`

- **Aliases** — short forms (`st`, `co`, `ci`, `pr = pull --rebase`, `bda` to nuke
  merged branches). Read the source before adopting `bda`; it force-deletes.
- **`ghq` roots** — `ghq.root` (personal) and a host-scoped root for company repos
  keep clones organised. See [ghq.md](ghq.md).
- **`core.excludesfile`** — a global `~/.gitignore`.
- **`core.editor = nano`** — swap to your editor of choice.

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
- [GitHub: SSH commit signature verification](https://docs.github.com/authentication/managing-commit-signature-verification/about-commit-signature-verification)
