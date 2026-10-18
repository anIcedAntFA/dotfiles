# Handoff

Temporary. Two independent threads; delete a section when its thread is done,
and the file when both are.

- [Plain Arch on the laptop](#plain-arch-on-the-laptop-guide-written-not-yet-run) —
  guide written, waiting to be run on the laptop.
- [Windows host + WSL guest migration](#windows-host--wsl-guest-migration-in-progress)
  — the `work` box.

---

## Plain Arch on the laptop (guide written, not yet run)

### State as of 2026-10-18

The `grill-with-docs` session finished (rounds 1–3 answered, shared
understanding confirmed). The guide is written; **nothing has run on the laptop
yet** apart from the hardware snapshot and the BitLocker check. Delete this
section once the install is done and the guide has been corrected against
reality.

- Steps: [docs/arch-install.vi.md](docs/arch-install.vi.md)
- Theory: [docs/boot-disk-network-concepts.vi.md](docs/boot-disk-network-concepts.vi.md)
- Evidence: [docs/research/arch-install-ideapad-5-pro-14.md](docs/research/arch-install-ideapad-5-pro-14.md)
  (open questions updated with the on-machine answers)

### Decisions in one line each

14ACN6 · Ryzen 7 5800U · MX450 · MT7921 · dual-boot, Windows untouched ·
manual install over SSH from the `home` box · ESP `p1` (100 MB, shared) at
`/efi`, not formatted · XBOOTLDR `p4` reformatted FAT32 at `/boot` · `p5` LUKS2 +
ext4, TRIM via `--allow-discards --persistent` + `fstrim.timer` · systemd-boot ·
mkinitcpio with `sd-encrypt`, passphrase only · `linux` + `linux-lts` ·
`nvidia-open` + `nvidia-open-lts` + `nvidia-prime`, RTD3 (`0x02`), no NVIDIA in
the initramfs · zram only, `zswap.enabled=0` in the entries · keep s2idle · MT7921
ASPM only as troubleshooting · Secure Boot off (`sbctl` + UKI + TPM2 later) ·
NetworkManager + systemd-resolved, mDNS via resolved (the `home` box uses Avahi) ·
BIOS update to GECN39WW from Windows first · `chezmoi init` with
`installPackages = no`, package list filtered by hand.

### Still to verify on the machine

Each of these is written in the guide as expected behaviour; correct the guide
where reality disagrees.

1. The default `HOOKS=` line only lacks `sd-encrypt`.
2. `bootctl list` shows `auto-windows`, and the firmware does not skip XBOOTLDR
   (Fast Boot).
3. MX450 `runtime_status` reaches `suspended` with the `0x02` setting.
4. `charge_types` vs `conservation_mode`, and whether the mode survives a
   reboot.
5. The archinstall appendix (unverified for the `/efi` + XBOOTLDR layout).
6. ESP free space after removing `fedora` / `archcraft`.

### Suggested skills

`git-workflow` for commits; `mattpocock-skills:diagnosing-bugs` if a boot step
fails; `mattpocock-skills:research` for anything marked unverified.

---

## Windows host + WSL guest migration (in progress)

Delete this section once the checklist in
[docs/windows.md](docs/windows.md#what-to-verify-on-windows) is fully ticked.

### State as of 2026-10-12

The repo side is done and committed on `chore/sync-work-machine`; nothing under
`windows/` has run on a real Windows machine yet. The work box still boots Linux.

### Next steps

1. ~~Boot Windows, run `powercfg /h off` in an elevated terminal, record the
   output of `wsl --status`, `winget --version`, `manage-bde -status C:` and
   `powercfg /a`, then leave via **Restart** (not Shut down).~~ Done
   2026-10-12; results are in the checklist in `docs/windows.md`.
2. ~~Back on Linux, copy the already-built hand-off archive to the NTFS data disk
   (it was refused once because Fast Startup held the volume).~~ Done
   2026-10-12; the copy's checksum was verified.
3. Boot Windows for good and follow [docs/windows.md](docs/windows.md) from
   "Windows host" down, ticking its checklist and correcting the guide where
   reality disagrees.

### Where the rest is

- **Machine-specific notes** (what the archive holds, what was deliberately left
  behind, deviations from the guide's restore step) are **not** in this public
  repo. They are in a second `HANDOFF.md` that travels beside the archive, in
  `linux-handoff/` on the data disk. Read that one first.
- Decisions and rejected options:
  [ADR 0025](docs/adr/0025-wsl-guest-for-the-terminal-layer-on-windows.md).
- Per-tool evidence: [docs/research/windows-migration.md](docs/research/windows-migration.md).
- Terms: "Desktop host vs WSL guest vs Windows host" in [CONTEXT.md](CONTEXT.md).

### Suggested skills (Windows)

`grill-with-docs` (the session ran under it), `mattpocock-skills:research` for
anything the research note marks unverified, `mattpocock-skills:diagnosing-bugs`
when a `windows/` config misbehaves, `git-workflow` for commits.
