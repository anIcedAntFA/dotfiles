# ripgrep — fast recursive search

## Why

[ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) is a recursive grep that
respects `.gitignore`, skips binary files, and is fast. It's the default search
tool across this setup — fish, editors, and the AI agents all reach for `rg`.

## Config

ripgrep does **not** read an XDG path on its own. It only loads the file named by
`$RIPGREP_CONFIG_PATH`, so two pieces are needed:

1. [`home/dot_config/ripgrep/config`](../home/dot_config/ripgrep/config) — the flags.
2. `RIPGREP_CONFIG_PATH` exported in [`config.fish`](../home/dot_config/fish/config.fish):

   ```fish
   set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config
   ```

The config keeps to **behavioural** flags only:

```text
--smart-case      # case-insensitive unless the pattern has an uppercase letter
--hidden          # search dotfiles too (apt for a dotfiles repo)
--glob=!.git/     # but never descend into .git
--glob=!vendor/   # or vendored dependency trees
```

> [!NOTE]
> Display/grouping flags (`--no-heading`, `--sort=path`) are deliberately left
> out. This config applies to **every** `rg` invocation — including tools that
> shell out to rg and expect its default output — and `--sort=path` disables
> ripgrep's parallelism, slowing large searches. `--hidden` still respects
> `.gitignore`; it only lifts the "skip dotfiles" filter.

Override per-search on the command line (flags there win), or ignore the config
entirely for one call with `rg --no-config …`.

## References

- [ripgrep user guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [ripgrep config file](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file)
