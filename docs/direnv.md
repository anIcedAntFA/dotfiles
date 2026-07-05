# direnv — per-directory environments

## Why

Some settings should only exist _inside a project_: a `DATABASE_URL`, an API token,
a bumped `PATH`, a specific runtime version. [direnv](https://direnv.net/) loads an
`.envrc` when you `cd` into a directory and **unloads it when you leave** — so your
global shell stays clean and each project carries its own environment. It pairs
naturally with [mise](mise.md): mise pins the _tool versions_, direnv sets the
_environment_ around them.

## How it hooks in

direnv works by a shell hook that runs on every prompt. It's already wired for fish
in [`config.fish`](../home/dot_config/fish/config.fish):

```fish
# direnv
direnv hook fish | source
```

That's the only wiring needed — the `direnv` package is in
[packages.md](packages.md). For bash/zsh the equivalent is `direnv hook bash|zsh`.

## Using it

Drop an `.envrc` in a project root:

```sh
# .envrc
export DATABASE_URL="postgres://localhost/myapp_dev"
export RAILS_ENV=development
PATH_add bin            # prepend ./bin to PATH while in this dir
```

The first time (and after every edit) direnv **blocks** the file until you approve
it — this is the security model, so a cloned repo can't run code at you silently:

```sh
direnv allow      # trust and load this .envrc
direnv deny       # revoke trust
direnv reload     # re-evaluate after an external change
```

When you `cd` out, everything the `.envrc` exported is unset automatically.

## With mise

Two good patterns — pick one, don't stack them:

- **Let mise own runtimes, direnv own env.** Keep tool versions in `mise.toml` (or
  `.tool-versions`) and put only environment variables in `.envrc`. Simplest.
- **Bridge mise through direnv.** If you want direnv to _also_ activate mise's tools
  for a directory, add `use mise` to `.envrc`. Only do this if you're _not_ already
  running `mise activate fish` globally (you are — see
  [`config.fish`](../home/dot_config/fish/config.fish)), or you'll double-activate.

## Gotchas

- **Never commit secrets in a tracked `.envrc`.** Put secret values in an untracked
  `.envrc.local` and `source_env_if_exists .envrc.local`, or pull them from
  [gopass](gopass.md). Same repo rule as everywhere else.
- Add `.envrc.local` (and often `.direnv/`) to the project's `.gitignore`.

## References

- [direnv — getting started](https://direnv.net/#getting-started)
- [`direnv-stdlib`](https://direnv.net/man/direnv-stdlib.1.html) — `PATH_add`,
  `layout`, `use`, `source_env`, etc.
