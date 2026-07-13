# Node-free docs/config toolchain, provisioned by mise

**Status:** accepted — supersedes [ADR 0003](./0003-formatting-and-linting-toolchain.md)

The repo has no JS/TS source, yet [ADR 0003](./0003-formatting-and-linting-toolchain.md)
pulled a full Node toolchain into it — a `package.json`, `pnpm-lock.yaml`, and
`node_modules/` existed **only** to run `oxfmt` (beta) and `markdownlint-cli2` on
Markdown and config files. For a dotfiles repo whose whole value is being clonable
and reproducible, carrying a package manager and lockfile for two doc formatters is
disproportionate. The goal here is a repo with **no Node/pnpm footprint of its own**,
where every dev tool is a single binary pinned and installed by
[mise](https://mise.jdx.dev/) — `cd` in, `mise install`, done. (Node still exists on
the machine as a _global_ runtime via `home/dot_config/mise/config.toml`; it is just
no longer a _repo_ build dependency.)

Formatters/linters by file type:

- **Markdown/JSON/JSONC/YAML/TOML** → `dprint` (format) — one Rust binary. Official
  plugins cover md/json/toml; the community `g-plane/pretty_yaml` plugin covers YAML.
  Config in `dprint.json`.
- **Markdown rules** → `rumdl` (lint only, no `--fix` in the workflow) — a Rust
  markdownlint reimplementation that reads the existing `.markdownlint.yml`
  unchanged. Rules that overlap dprint's formatting (line length, list indent, blank
  lines) stay disabled so the two don't fight, exactly as with the old
  oxfmt + markdownlint-cli2 split.
- **Shell** (`install.sh`, `.local/bin/*`) → `shellcheck` (lint) + `shfmt` (format).
- **Fish** → `fish_indent` (format) + `fish -n` (syntax check) — ships with fish,
  stays a system tool, not mise-managed.
- **KDL** (niri) → `niri validate`.
- **Base whitespace/encoding** → `.editorconfig`.

The repo-root [`mise.toml`](../../mise.toml) (checked in, **not** chezmoi-managed —
it is this project's build tooling, not a dotfile) pins `dprint`, `rumdl`, `just`,
`lefthook`, `gitleaks`, `shfmt`, and `shellcheck`. `just setup` is now
`mise install && lefthook install`.

## Considered options

- **dprint + rumdl, mise-provisioned** — chosen. Single-binary tools, no Node/pnpm
  in the repo, `.markdownlint.yml` preserved verbatim, and mise gives one pinned,
  reproducible `mise install` for contributors. Cost: dprint's YAML support is a
  community plugin (not first-party), rumdl is younger than the reference
  markdownlint, and contributors run `mise trust` once per checkout.
- **Keep oxfmt + markdownlint-cli2 (status quo, ADR 0003)** — rejected. Works, but
  keeps a package manager, a lockfile, and `node_modules/` in the repo purely for
  docs tooling, and leans on a beta formatter (oxfmt).
- **Ruby `mdl` (github.com/markdownlint/markdownlint) for Markdown lint** — rejected.
  Trades a Node runtime for a **Ruby** one, uses a different config format
  (`.mdlrc` + a `.mdl_style.rb` DSL) that would discard the tuned `.markdownlint.yml`,
  and diverges from the `davidanson`/`rumdl` rule set the editor uses. No progress
  toward the node-free goal.
- **dprint only, drop the Markdown linter** — rejected. dprint normalizes
  whitespace/structure but can't enforce the semantic rules we actually tune
  (MD040 code-fence language, MD045 image alt-text, MD034 bare URLs, MD033 allowed
  inline HTML).

## Consequences

- `package.json`, `pnpm-lock.yaml`, and `node_modules/` are removed from the repo;
  `.oxfmtrc.json` is replaced by `dprint.json`.
- `justfile`, `lefthook.yml`, `.vscode/settings.json`, and `.vscode/extensions.json`
  switch from oxfmt/markdownlint-cli2 (and the `oxc`/`davidanson` extensions) to
  dprint/rumdl (and the `dprint.dprint`/`rvben.rumdl` extensions).
- `.markdownlint.yml` is consumed by rumdl directly. Its rule set is intact; only
  its oxfmt header comment is retargeted to dprint and two redundant sub-options
  rumdl doesn't recognize (`MD010.ignore_code_languages`, `MD040.language_only`,
  both no-ops given the other settings) are dropped to keep `just check` quiet.
- rumdl enforces a few rules the old markdownlint-cli2 didn't (e.g. MD057
  relative-link existence), which caught two stale `config.kdl` links now fixed.
- `just check` (what CI runs) no longer needs Node; it needs `mise install` to have
  populated the pinned tools. CI installs mise, then runs `mise install && just check`.
- Reversing is still low-cost: swap the formatter/linter back and re-run once. The
  `.markdownlint.yml` rule set is portable across markdownlint, markdownlint-cli2,
  and rumdl.
