# SSH — multiple identities (personal + work)

## Why

Most developers juggle at least two git identities: a **personal** one
(GitHub) and a **work** one (a company GitLab). Each needs its own SSH key, and
git must pick the right key per host automatically. `~/.ssh/config` makes that
declarative.

In this repo the config is a **chezmoi template**
([`home/private_dot_ssh/config.tmpl`](../home/private_dot_ssh/config.tmpl)) — the
work host is a variable so no employer detail is committed. `private_` gives the
applied file `0600` permissions.

## 1. Generate a key per identity

```sh
ssh-keygen -t ed25519 -C "you@example.com"     -f ~/.ssh/github
ssh-keygen -t ed25519 -C "you@company.example" -f ~/.ssh/gitlab
```

`ed25519` is the modern, short, fast key type — prefer it over RSA.

## 2. Add the public keys to each host

Copy `~/.ssh/github.pub` into GitHub → _Settings → SSH keys_, and
`~/.ssh/gitlab.pub` into your GitLab equivalent.

## 3. The config (what chezmoi renders)

```ssh-config
# Personal — GitHub
Host github.com
	HostName github.com
	User git
	IdentityFile ~/.ssh/github
	IdentitiesOnly yes

# Work — host comes from `chezmoi init` prompts
Host gitlab.example.com
	HostName gitlab.example.com
	User git
	IdentityFile ~/.ssh/gitlab
	IdentitiesOnly yes
```

- **`IdentitiesOnly yes`** — only offer the listed key, so SSH doesn't try every
  loaded key and trip a host's failed-auth limit.
- Add `Port 2222` under a host if it uses a non-standard SSH port.

## 4. Test

```sh
ssh -T git@github.com          # "Hi <you>! You've successfully authenticated…"
ssh -T git@gitlab.example.com
```

## Related

- Git picks your work identity by path — see [ghq.md](ghq.md) and the
  `includeIf` block in [`home/dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl).

## References

- [GitHub: connecting with SSH](https://docs.github.com/authentication/connecting-to-github-with-ssh)
- [`ssh_config` manual](https://man.openbsd.org/ssh_config)
