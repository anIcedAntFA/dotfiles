# mise — runtime & dev-env manager

## Why

[mise](https://mise.jdx.dev/) manages language runtimes (Node, Bun, pnpm, Yarn,
Go…) per project and globally — one tool replacing nvm/fnm/volta/asdf. It reads a
declarative config and installs the exact versions, so every machine and project
gets the same toolchain.

## Install

```sh
yay -S --needed mise
```

Activate it in [fish](fish.md) (already wired in `config.fish`):

```fish
mise activate fish | source
```

## Global tools

[`home/dot_config/mise/config.toml`](../home/dot_config/mise/config.toml) pins the
global runtimes to exact versions: **node** (the current LTS line), **pnpm**,
**yarn**, **bun** and **go**, plus `gopls` and `wrangler` tracking `latest`. The
file is the source of truth; this guide doesn't repeat the numbers, so it can't
drift from them.

A recent pnpm switches to whatever version a project's `packageManager` field
names, so bumping the global pnpm across a major leaves pinned work repos alone.

To upgrade, edit the source file (not `~/.config/mise/config.toml`, which
`mise use -g` would also write to), then:

```sh
chezmoi apply ~/.config/mise/config.toml
mise install
```

Install them all on a fresh machine:

```sh
mise install
```

These are the runtimes you want on **every** machine. Project-specific linters
(gofumpt, golangci-lint, …) belong in a project's own `mise.toml`, not here.

## Repo tooling vs global runtimes

There are two mise files, with different jobs — don't conflate them:

| File                         | Scope                       | chezmoi?       | Holds                           |
| ---------------------------- | --------------------------- | -------------- | ------------------------------- |
| `~/.config/mise/config.toml` | your machine, every project | yes (dotfile)  | daily runtimes (node, go, bun…) |
| `<repo>/mise.toml`           | one project                 | no (repo file) | that project's build/lint tools |

This dotfiles repo carries its own [`mise.toml`](../mise.toml) pinning
`dprint`, `rumdl`, `just`, `lefthook`, `gitleaks`, `shfmt`, and `shellcheck`, so a
fresh checkout is one command — no Node required:

```sh
mise trust      # once, to allow the repo's mise.toml
mise install    # or: just setup
```

See [ADR 0007](adr/0007-node-free-toolchain-via-mise.md) for why the repo dropped
its Node/pnpm toolchain in favour of mise-provisioned single binaries.

## Per-project versions

```sh
cd my-project
mise use node@22        # writes .mise.toml, pins node 22 here
mise install            # install anything missing
```

mise pairs with [`direnv`](https://direnv.net/) (also active in `config.fish`)
for per-directory environment variables.

## References

- [mise documentation](https://mise.jdx.dev/)
- [Configuration](https://mise.jdx.dev/configuration.html)
