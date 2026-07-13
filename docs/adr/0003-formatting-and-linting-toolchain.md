# Formatting & linting toolchain

**Status:** superseded by [ADR 0007](./0007-node-free-toolchain-via-mise.md)

> Superseded 2026-07: oxfmt (beta, npm) and markdownlint-cli2 (npm) are replaced
> by **dprint** (format) + **rumdl** (Markdown lint), provisioned by **mise** — no
> Node/pnpm in the repo. The dprint-vs-oxfmt trade-off recorded below was resolved
> the other way once removing the repo's Node toolchain became the goal. See
> [ADR 0007](./0007-node-free-toolchain-via-mise.md). Retained for history.

This repo has no JS/TS source, so **oxlint** (a JS/TS-only linter) is not used.
For formatting we use **oxfmt** — since its 2026-02 beta it formats Markdown,
JSON/JSONC/JSON5, YAML, and TOML, which covers our docs and most config files
with one Prettier-compatible tool. We accept that oxfmt is **beta** and installed
via npm (Node is already present through mise/pnpm), choosing it over the stable
alternatives (Prettier, dprint) deliberately.

Formatters/linters by file type:

- **Markdown/JSON/JSONC/YAML/TOML** → `oxfmt` (format)
- **Markdown rules** → `markdownlint-cli2` (driven by `.markdownlint.yml`), with
  whitespace/line-length rules that overlap oxfmt disabled so the two don't fight
- **Shell** (`install.sh`, `.local/bin/*`) → `shellcheck` (lint) + `shfmt` (format)
- **Fish** → `fish_indent` (format) + `fish -n` (syntax check) — no oxc tool covers fish
- **KDL** (niri) → `niri validate`
- **Base whitespace/encoding** → `.editorconfig`

## Considered options

- **dprint** — stable single Rust binary, no Node, same md/json/toml/yaml coverage.
  Rejected in favour of oxfmt for the unified oxc ecosystem, despite oxfmt's beta status.
- **Prettier** — ubiquitous but slower and no native TOML. Rejected.

## Consequences

- oxfmt being beta means occasional formatting churn on upgrades; pin its version.
- Reversing to dprint/Prettier later is low-cost (swap the formatter, re-run once).
