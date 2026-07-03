# ghq — tidy repository management

## Why

Cloning repos into random folders gets messy fast. [`ghq`](https://github.com/x-motemen/ghq)
clones everything into a predictable tree mirroring the remote URL:

```text
~/workspace/
	github.com/anIcedAntFA/linux-setup/
	github.com/<org>/<repo>/
~/workspace/company/
	gitlab.example.com/<group>/<repo>/
```

One glance tells you where any repo lives, and it pairs beautifully with a fuzzy
finder to jump between them.

## Install

```sh
yay -S --needed ghq peco
```

## How it's configured

The roots live in [`home/dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl) (values
come from `chezmoi init` prompts):

```gitconfig
[ghq]
	root = ~/workspace

# Work repos get their own root, keyed by the work git host
[ghq "ssh://git@gitlab.example.com:22/"]
	root = ~/workspace/company
```

Because work repos live under `~/workspace/company/`, git automatically switches
to your **work identity** there via the `includeIf` block in the same file — so
commits are attributed to the right email without you thinking about it.

## Daily use

```sh
ghq get github.com/anIcedAntFA/linux-setup   # clone into the tree
ghq list                                      # list all managed repos
ghq get -p <org>/<repo>                        # clone via SSH
```

### Jump to any repo (fish + peco)

```fish
function repo
	cd (ghq root)/(ghq list | peco)
end
```

Type `repo`, fuzzy-search, land in the repo. (See [fish.md](fish.md) for the
peco-powered history/cd bindings this setup already ships.)

## References

- [ghq README](https://github.com/x-motemen/ghq)
- [Multiple git identities](ssh.md)
