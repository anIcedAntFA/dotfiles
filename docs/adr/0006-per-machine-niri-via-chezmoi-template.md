# Per-machine niri config via a chezmoi template

**Status:** accepted

The niri config must serve three machines with different hardware — an office
desktop (dual ASUS PA278CV, one portrait), a personal laptop (single HiDPI
panel), and a home desktop — that differ in outputs, scale/DPI, workspace→monitor
pinning, and which apps autostart. Rather than keep divergent copies, the source
is a single chezmoi template, [`config.kdl.tmpl`](../../home/dot_config/niri/config.kdl.tmpl),
that branches on a `machine` variable (`work` | `laptop` | `home`) prompted at
`chezmoi init` and stored in the gitignored `chezmoi.toml`. A profile table at
the top holds each machine's scalars; multi-line blocks branch inline with
`{{ if eq $machine ... }}`.

## Considered options

- **chezmoi template keyed on a `machine` var** — chosen. One source of truth,
  all three machines' presets version-controlled and reviewable together, and the
  selector is a generic form-factor label so the real (company-tagged) hostname
  never enters this public repo — consistent with
  [ADR 0002](./0002-private-data-via-templates.md). Cost: the config is no longer
  plain KDL, so `niri validate` needs a render step (`just validate-niri` handles
  it) and edits require `chezmoi apply` before niri hot-reloads the result.
- **One static `config.kdl` listing every machine's outputs** — rejected.
  Unconnected outputs are ignored, so this _almost_ works, but two desktops share
  connector names (`DP-1`) while needing different scale/mode, and workspace
  pinning can't vary per machine. It also can't gate the touchpad block or the
  work-only chat apps.
- **Shared static config + a machine-local `include`** (the `local.fish` pattern)
  — rejected as the primary mechanism. It keeps machine specifics off the repo
  entirely, which is clean, but then the presets are **not** committed or
  commented in the repo — the opposite of the stated goal of having all three
  boxes documented in one place. `include` remains available for genuinely
  secret per-machine bits if that need ever arises.
- **Keying on `.chezmoi.hostname`** — rejected. It removes the prompt but bakes
  the hostname into template conditions; the work hostname carries a company tag
  and must stay out of the public repo (see [CLAUDE.md](../../CLAUDE.md)).

## Consequences

- niri hot-reloads the **applied** `~/.config/niri/config.kdl`, not the template.
  The edit loop is `chezmoi edit` → `just validate-niri` → `chezmoi apply`.
  Editing the applied file directly still reloads instantly but is overwritten on
  the next apply.
- `just validate-niri` renders the template (next to `noctalia.kdl`, so the
  relative `include` resolves) before calling `niri validate`. CI's `just check`
  does not run it — it needs a niri binary — so the `.tmpl` never breaks CI.
- Adding a machine means one row in the profile table, one `output` block, and a
  prompt-hint update. An unknown `machine` value fails the render loudly.
- The `machine` var is now part of the fresh-install prompts in
  [`.chezmoi.toml.tmpl`](../../home/.chezmoi.toml.tmpl); existing machines pick it
  up on the next `chezmoi init`.
