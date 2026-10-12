# On Windows, the terminal layer runs in a WSL guest; the host is configured by hand

**Status:** accepted (2026-10-12) — not yet exercised on a Windows machine

The work box may no longer boot Linux, so this config has to run under Windows 11.
Rather than port it to native Windows, everything terminal-shaped — fish, zellij,
git, mise, ghq, gopass, the repos themselves — runs in an Arch Linux WSL2 guest
and is applied by chezmoi from the same `home/` source as on a Desktop host. The
Windows host only supplies the desktop the guest lacks (terminal emulator, tiling
WM, input method, GUI apps); its few config files live in `windows/` at the repo
root and are copied by hand, the way `etc/` already is.

chezmoi recognises a WSL guest from the kernel release string and skips the
desktop targets. That is a second axis next to the machine profile, not a fourth
profile: a profile names a box, and the same box can be a Desktop host on one
boot and a Windows host with a WSL guest on the next.

## Considered options

- **WSL guest + hand-applied `windows/`** — chosen. The CLI layer is reused
  unchanged (same Arch userland, same package names, `.chezmoi.os` is still
  `linux`), so the change to `home/` is one ignore block and one branch in the
  package script. The Windows side is about three files.
- **Native Windows, chezmoi on both sides** — rejected. fish has no native
  Windows build, so the shell, its twelve functions, the bash hooks and every
  `dot-*` script would need a PowerShell twin kept in step forever. chezmoi on
  Windows also ignores `private_`/`executable_`, has no interpreter for `.sh`
  scripts, and needs Developer Mode for the one `symlink_` target; nearly all of
  the 127 existing targets would have to be excluded there.
- **`wsl` as a fourth machine profile** — rejected. It would turn "profile" from
  "which box" into "what is booted", and a laptop running WSL would then have no
  way to say it is still the laptop.
- **chezmoi-managed Windows targets in `home/`** — rejected for now. Too few
  files to justify a second checkout and an OS-templated ignore file. Easy to
  adopt later if `windows/` grows.

## Consequences

- **Depends on policy we do not control.** If WSL is disabled on the machine,
  this design has nothing to stand on and the native route above is the only one
  left.
- **No scrolling window manager.** The one Windows WM with a scrolling layout,
  komorebi, is not licensed for use at work; GlazeWM is used instead and is
  i3-style. Muscle memory for niri's column operations does not transfer.
- **The Linux partition is unreachable from Windows** on a single-disk dual
  boot, so the move is a one-way hand-off of data, not a shared filesystem.
- **`windows/` can drift.** Nothing applies or checks it; like `etc/`, it is only
  as current as the last time it was copied back.
- The research behind the tool choices is in
  [docs/research/windows-migration.md](../research/windows-migration.md); the
  procedure is [docs/windows.md](../windows.md).
