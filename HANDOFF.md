# Handoff — zellij validation

The Ghostty/zoxide side of the terminal workflow is done and documented
([ADR 0008](docs/adr/0008-terminal-workspace-model.md), [docs/ghostty.md](docs/ghostty.md),
[docs/zellij.md](docs/zellij.md)). One thing is still outstanding.

## zellij artifacts are unvalidated

They were written from the docs alone, **before zellij was installed**. It's 0.44.3
now, so they can finally be exercised. Test:

- layout `~` cwd expansion in `_template.kdl`
- the `zj` picker flow
- `theme_dark` / `theme_light`

Delete this file once that's done — it's a transient work note.
