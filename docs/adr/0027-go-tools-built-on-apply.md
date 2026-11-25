# Small Go tools in tools/, built on chezmoi apply

**Status:** accepted

Zed has no word count, so a Zed task runs a counter that parses Markdown and
counts prose only ([docs/zed.md → Word count](../zed.md#word-count)). It is
written in **Go**, lives in [`tools/wordcount/`](../../tools/wordcount) as its
own module (outside the chezmoi source root, so the source never reaches
`$HOME`), and a `run_onchange_after_` script
([`build-wordcount`](../../home/.chezmoiscripts/run_onchange_after_build-wordcount.sh.tmpl))
compiles it into `~/.local/bin/dot-wordcount` whenever its source hash changes.
The binary is never committed. This is the first compiled code in the repo, and
the pattern for any later tool: one module per `tools/<name>/`, built on apply,
checked by `just check-go` (gofmt, vet, `go test -race`).

## Considered options

- **Go + goldmark, built on apply** — chosen. goldmark gives a real CommonMark +
  GFM AST, so "drop code, URLs and markup; keep the text" is a tree walk rather
  than a pile of regexes that misread nested lists, reference links or indented
  code. It is pure Go with no transitive dependencies. Go is already installed
  on every Linux box (`packages/pacman-explicit.txt`, `pacman-wsl.txt`), and Go is
  the preferred language here.
- **Python 3 stdlib script** — rejected. Zero build step (chezmoi copies it as
  is), but the stdlib has no Markdown parser, so accuracy rests on regexes.
- **Node + remark/mdast** — rejected. The most accurate for MDX, but it needs
  `node_modules`, against the Node-free toolchain of
  [ADR 0007](0007-node-free-toolchain-via-mise.md).
- **Separate repo + `go install …@latest`** — rejected. No build logic here, but
  a whole repo, release flow and version bump for a ~270-line tool.

## Consequences

- `chezmoi apply` needs `go` and network access (module download) the first time
  a tool changes. Without `go` the script prints a hint and skips; the task then
  fails with "command not found" until it is installed.
- CI provisions Go with `actions/setup-go` (not `mise.toml`, which keeps daily
  runtimes out of the repo pin list) and runs `just check-go`.
- Editing a `_test.go` file does not trigger a rebuild; any other file in the
  module does.
