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
#
# Also guards the Private Use Area trap documented in docs/starship.md: a PUA
# glyph in the BMP (U+E000–U+F8FF) typed as a literal character gets silently
# eaten by anything that re-encodes the file, leaving an EMPTY string that still
# parses, still lints, and renders nothing. So every icon is written as \uXXXX,
# and an empty "keyIcon" is treated as a failure rather than a blank column.
validate-fastfetch:
    #!/usr/bin/env bash
    set -euo pipefail
    src=home/dot_config/fastfetch/config.jsonc.tmpl
    if grep -nP '"keyIcon": "\s*"' "$src"; then
        echo "❌ empty keyIcon above — a PUA glyph was eaten (docs/starship.md)" >&2
        exit 1
    fi
    if grep -nP '"(keyIcon|text|key|format)": "[^"]*[\x{E000}-\x{F8FF}]' "$src"; then
        echo "❌ literal BMP Private Use Area glyph above — write \\uXXXX instead" >&2
        exit 1
    fi
    chezmoi execute-template < "$src" > home/dot_config/fastfetch/.rendered.jsonc
    fastfetch -c home/dot_config/fastfetch/.rendered.jsonc --logo none > /dev/null
    rm -f home/dot_config/fastfetch/.rendered.jsonc
    # Mask logos (ADR 0024): a colour key that is used but not defined renders as
    # an EMPTY escape — the art silently loses a whole region and still lines up,
    # which is the same failure shape as the PUA trap above. So: both palettes
    # must exist, agree on their key set, and match the grid exactly.
    for f in home/dot_config/fastfetch/logos/*/*.txt; do
        head -n1 "$f" | grep -q '^#light ' || continue   # legacy raw-escape logo
        awk -v f="$f" '
            /^#(light|dark) / {
                for (i = 2; i <= NF; i++) {
                    split($i, kv, "=")
                    if (kv[2] !~ /^#[0-9a-fA-F]{6}$/) { print f ": " $1 " " $i " is not #rrggbb" > "/dev/stderr"; bad = 1 }
                    if ($1 == "#light") L[kv[1]] = 1; else D[kv[1]] = 1
                }
                next
            }
            { for (i = 1; i <= length($0); i++) { c = substr($0, i, 1); if (c != ".") U[c] = 1 } }
            END {
                for (k in L) if (!(k in D)) { print f ": " k " in #light but not #dark" > "/dev/stderr"; bad = 1 }
                for (k in D) if (!(k in L)) { print f ": " k " in #dark but not #light" > "/dev/stderr"; bad = 1 }
                for (k in U) if (!(k in L)) { print f ": grid uses " k " with no palette entry" > "/dev/stderr"; bad = 1 }
                for (k in L) if (!(k in U)) { print f ": palette defines unused " k > "/dev/stderr"; bad = 1 }
                exit bad
            }' "$f" || { echo "❌ mask palette error above (docs/adr/0024-…)" >&2; exit 1; }
    done
    echo "✅ fastfetch config is valid"

# Preview ONE logo, straight from the checkout, in both modes side by side.
# The rotation is random, so re-running `ff` is a bad way to look at a specific
# piece of art. Renders through the real random-logo so what you see is exactly
# what fastfetch would draw — canvas padding included. Must be run in a real
# terminal: truecolor half-blocks are the whole point.
#   just preview-logo nuxcut
preview-logo name="nuxcut" subset="pc":
    #!/usr/bin/env bash
    set -euo pipefail
    src=home/dot_config/fastfetch/logos/{{ subset }}/{{ name }}.txt
    [ -f "$src" ] || { echo "❌ no such logo: $src" >&2; exit 1; }
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    mkdir -p "$tmp/fastfetch/logos"
    cp -r home/dot_config/fastfetch/logos/. "$tmp/fastfetch/logos/"
    for mode in light dark; do
        echo "── {{ name }} · $mode ──"
        sed "s|^case \"\$(dconf read.*|case \"$mode\" in|" \
            home/dot_config/fastfetch/executable_random-logo > "$tmp/render"
        XDG_CONFIG_HOME="$tmp" sh "$tmp/render" {{ subset }} {{ name }}
        echo
    done
