# Linux Setup — task runner (https://github.com/casey/just)
# Run `just` with no arguments to list every recipe.

# List all recipes
default:
    @just --list

# One-time setup: install pinned tooling (mise) + git hooks.
# All dev tools are pinned in ./mise.toml — no Node/pnpm. Run `mise trust` first
# if this is a fresh checkout. See docs/adr/0007-node-free-toolchain-via-mise.md.
setup:
    mise install
    lefthook install
    @echo "✅ setup complete — hooks installed, tooling ready"

# Format everything in place (dprint + shfmt + fish_indent)
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    shell=$(shfmt -f . | grep -vE 'node_modules|/\.(agents|gemini|claude)/')
    dprint fmt
    [ -n "$shell" ] && shfmt -w $shell
    fish_indent -w $(find home -name '*.fish')

# Run every check without writing — this is exactly what CI runs
check:
    #!/usr/bin/env bash
    set -euo pipefail
    shell=$(shfmt -f . | grep -vE 'node_modules|/\.(agents|gemini|claude)/')
    echo "▶ dprint";      dprint check
    echo "▶ rumdl";       rumdl check . --exclude 'home/,node_modules/,.agents/,.claude/,.gemini/,.docs/'
    echo "▶ shellcheck";  [ -n "$shell" ] && shellcheck $shell
    echo "▶ shfmt";       [ -n "$shell" ] && shfmt -d $shell
    echo "▶ fish-fmt";    fish_indent --check $(find home -name '*.fish')
    echo "▶ fish-syntax"; for f in $(find home -name '*.fish'); do fish -n "$f" || exit 1; done
    just secrets

# Scan the repository (working tree + history) for leaked secrets
secrets:
    gitleaks git . --no-banner --redact

# Validate the niri config — local only, needs niri + chezmoi installed.
# config.kdl is a chezmoi template, so render it (next to noctalia.kdl, so the
# `include "./noctalia.kdl"` resolves) before handing it to `niri validate`.
validate-niri:
    chezmoi execute-template < home/dot_config/niri/config.kdl.tmpl > home/dot_config/niri/.rendered.kdl
    niri validate -c home/dot_config/niri/.rendered.kdl
    rm -f home/dot_config/niri/.rendered.kdl

# Validate the fastfetch config — local only, needs fastfetch + chezmoi.
# config.jsonc is a chezmoi template; render it and let fastfetch parse it
# (--logo none, since the logo script/files aren't applied into this checkout).
validate-fastfetch:
    chezmoi execute-template < home/dot_config/fastfetch/config.jsonc.tmpl > home/dot_config/fastfetch/.rendered.jsonc
    fastfetch -c home/dot_config/fastfetch/.rendered.jsonc --logo none > /dev/null
    rm -f home/dot_config/fastfetch/.rendered.jsonc
    @echo "✅ fastfetch config is valid"
