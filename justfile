# Linux Setup — task runner (https://github.com/casey/just)
# Run `just` with no arguments to list every recipe.

# List all recipes
default:
    @just --list

# One-time setup: system tools + node dev deps + git hooks.
# Uses yay because `lefthook` lives in the AUR (plain `pacman` can't install it).
setup:
    yay -S --needed shellcheck shfmt just lefthook gitleaks
    pnpm install
    lefthook install
    @echo "✅ setup complete — hooks installed, tooling ready"

# Format everything in place (oxfmt + shfmt + fish_indent)
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    shell=$(shfmt -f . | grep -vE 'node_modules|/\.(agents|gemini|claude)/')
    pnpm exec oxfmt
    [ -n "$shell" ] && shfmt -w $shell
    fish_indent -w $(find home -name '*.fish')

# Run every check without writing — this is exactly what CI runs
check:
    #!/usr/bin/env bash
    set -euo pipefail
    shell=$(shfmt -f . | grep -vE 'node_modules|/\.(agents|gemini|claude)/')
    echo "▶ oxfmt";        pnpm exec oxfmt --check
    echo "▶ markdownlint"; pnpm exec markdownlint-cli2 "**/*.md" "!**/node_modules/**" "!home/**" "!.agents/**" "!.claude/**"
    echo "▶ shellcheck";   [ -n "$shell" ] && shellcheck $shell
    echo "▶ shfmt";        [ -n "$shell" ] && shfmt -d $shell
    echo "▶ fish";         fish_indent --check $(find home -name '*.fish')
    just secrets

# Scan the repository (working tree + history) for leaked secrets
secrets:
    gitleaks git . --no-banner --redact

# Validate the niri config — local only, needs niri installed
validate-niri:
    niri validate -c home/dot_config/niri/config.kdl
