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
global runtimes:

```toml
[tools]
bun = "1.3.9"
node = "24.13.1"
pnpm = "10.29.3"
wrangler = "latest"
yarn = "4.12.0"
```

Install them all:

```sh
mise install
```

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
