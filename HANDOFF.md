# Handoff — Windows host + WSL guest migration (in progress)

Temporary. Delete this file once the checklist in
[docs/windows.md](docs/windows.md#what-to-verify-on-windows) is fully ticked.

## State as of 2026-10-12

The repo side is done and committed on `chore/sync-work-machine`; nothing under
`windows/` has run on a real Windows machine yet. The work box still boots Linux.

## Next steps

1. Boot Windows, run `powercfg /h off` in an elevated terminal, record the
   output of `wsl --status`, `winget --version`, `manage-bde -status C:` and
   `powercfg /a`, then leave via **Restart** (not Shut down).
2. Back on Linux, copy the already-built hand-off archive to the NTFS data disk
   (it was refused once because Fast Startup held the volume).
3. Boot Windows for good and follow [docs/windows.md](docs/windows.md) from
   "Windows host" down, ticking its checklist and correcting the guide where
   reality disagrees.

## Where the rest is

- **Machine-specific notes** (what the archive holds, what was deliberately left
  behind, deviations from the guide's restore step) are **not** in this public
  repo. They are in a second `HANDOFF.md` that travels beside the archive, in
  `linux-handoff/` on the data disk. Read that one first.
- Decisions and rejected options:
  [ADR 0025](docs/adr/0025-wsl-guest-for-the-terminal-layer-on-windows.md).
- Per-tool evidence: [docs/research/windows-migration.md](docs/research/windows-migration.md).
- Terms: "Desktop host vs WSL guest vs Windows host" in [CONTEXT.md](CONTEXT.md).

## Suggested skills

`grill-with-docs` (the session ran under it), `mattpocock-skills:research` for
anything the research note marks unverified, `mattpocock-skills:diagnosing-bugs`
when a `windows/` config misbehaves, `git-workflow` for commits.
