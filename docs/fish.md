# fish shell

## Why

[fish](https://fishshell.com/) is a shell tuned for **interactive** use:
sane autosuggestions, syntax highlighting, and readable scripting — with almost
no config needed to feel good. This setup layers a plugin manager, a directory
jumper, fuzzy history/cd, and theming on top.

## Install

```sh
yay -S --needed fish fisher peco
```

Make it your login shell:

```sh
chsh -s "$(command -v fish)"
```

## Plugins (via fisher)

Managed in [`home/dot_config/fish/fish_plugins`](../home/dot_config/fish/fish_plugins):

| Plugin                                                                                                      | Purpose                                          |
| ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`jorgebucaran/fisher`](https://github.com/jorgebucaran/fisher)                                             | The plugin manager itself.                       |
| [`jethrokuan/z`](https://github.com/jethrokuan/z)                                                           | `z <dir>` — jump to frequently used directories. |
| [`catppuccin/fish`](https://github.com/catppuccin/fish) · [`dracula/fish`](https://github.com/dracula/fish) | Color themes.                                    |

Install/sync them:

```sh
fisher update
```

## Key bindings

From [`functions/fish_user_key_bindings.fish`](../home/dot_config/fish/functions/fish_user_key_bindings.fish):

| Key      | Action                                 |
| -------- | -------------------------------------- |
| `Ctrl-R` | Fuzzy-search shell history (peco).     |
| `Ctrl-F` | Fuzzy-jump to a subdirectory (peco).   |
| `Ctrl-L` | Accept one char of the autosuggestion. |

## Handy custom functions

Under [`functions/`](../home/dot_config/fish/functions/): `take` (mkdir + cd),
`refresh` (reload config), `show_path` (pretty-print `$PATH`), plus the
peco-powered history/cd helpers.

## Secrets & machine-local config

Never hard-code tokens in [`config.fish`](../home/dot_config/fish/config.fish).
It sources an **untracked** file at the end if present:

```fish
test -f $HOME/.config/fish/local.fish && source $HOME/.config/fish/local.fish
```

Put per-machine secrets (npm registry tokens, work-only vars) there — it's
gitignored and not managed by chezmoi.

## What config.fish wires up

`mise` (runtimes — see [mise.md](mise.md)), `direnv` (per-project env),
`pnpm`/`bun` paths, and the `local.fish` secrets hook.

## References

- [fish documentation](https://fishshell.com/docs/current/)
- [fisher](https://github.com/jorgebucaran/fisher)
