# Handoff

Temporary. Two independent threads; delete a section when its thread is done,
and the file when both are.

- [Plain Arch on the laptop](#plain-arch-on-the-laptop-grilling-in-progress) —
  planning session paused, resumes when the laptop is at hand.
- [Windows host + WSL guest migration](#windows-host--wsl-guest-migration-in-progress)
  — the `work` box.

---

## Plain Arch on the laptop (grilling in progress)

### State as of 2026-10-16

A `grill-with-docs` session is planning a reinstall of the `laptop` profile box
— EndeavourOS → **plain Arch from the Arch ISO**, booted off a Ventoy USB — and
the guide that comes out of it. Round 1 is answered, round 2 was asked but
**not answered** (it needs the laptop), round 3 is not asked yet. No guide is
written yet.

Artifacts so far (both **uncommitted** at the time of writing — commit/push
before switching machines, or the next session won't see them):

- [docs/research/arch-install-ideapad-5-pro-14.md](docs/research/arch-install-ideapad-5-pro-14.md)
  — cited research: hardware per variant, Wi-Fi chips, BIOS keys + Secure Boot,
  Ventoy (v1.1.18, ISO verification commands), live-ISO and installed
  networking, archinstall 4.5, EndeavourOS → Arch gotchas, the manual install
  essentials, and open questions to check on the laptop. Use it; don't
  re-research what it already covers.
- [CONTEXT.md](CONTEXT.md) — new term **Base install** (EndeavourOS "no desktop"
  vs plain Arch, per box, independent of the machine profile).

### Who the guide is for

The user is not afraid of the CLI and wants to **learn the fundamentals**
(hardware, firmware, disks, boot, networking, Linux) — the guide must explain the
_why_ of every step, not just list commands. The grilling runs in Vietnamese.

### Settled (round 1)

1. **Hardware:** IdeaPad 5 Pro **14ACN6** (AMD Ryzen 5000 U-series; the user said
   "AMD" — the research shows "14ACH5" does not exist), 16 GB RAM, 1 TB NVMe,
   about half Windows, the rest the current EndeavourOS install. MX450 presence
   and the Wi-Fi chip are still unknown (Q9).
2. **Dual-boot:** keep Windows untouched; reinstall only the Linux half.
3. **Method:** manual install following the ArchWiki Installation guide, driven
   **over SSH** from another machine (set a root password on the ISO, connect
   to `archiso.local`) so commands are pasted, not typed. archinstall gets an
   appendix only — with the **Minimal** profile, never its `niri` profile
   (it pulls lightdm + waybar, which clash with greetd/Noctalia).
4. **Network:**
   - _During install:_ Wi-Fi via `iwctl`. The model has **no RJ45**, so the
     wired fallback is a USB-C Ethernet dongle or Android USB tethering.
   - _After install:_ a home-LAN section — stable address (DHCP reservation on
     the router), `.local` name via mDNS, `sshd` with key login.
   - The wired-Ethernet part must also be reusable by the home PC. The laptop
     may later become a **home lab** box.
5. **LUKS** on root: yes.
6. **NetworkManager** (`nmcli` / `nmtui`) + systemd-resolved after install.
7. **Plain Arch for the laptop only, for now**; `work` / `home` stay EndeavourOS.
   No ADR (cheap to reverse). Consequences to handle when writing:
   - The README "Distro" row and the `docs/packages.md` baseline still say
     EndeavourOS — they need per-box wording.
   - `packages/pacman-explicit.txt` holds 13 packages that don't exist on plain
     Arch (research note §6) — the guide must not feed it to `yay` unfiltered.
8. **Guide:** `docs/arch-install.vi.md`, in Vietnamese. It ends at "TTY with
   network + user/sudo + `yay` + `chezmoi init`" and hands over to the README
   Quick start (greetd / niri have their own guides). Link it from the README.

### Round 2 — asked, unanswered (recommendation in brackets)

**Q9 — hardware and disk snapshot.** Run on the laptop while it still boots
EndeavourOS. If the next session runs _on_ the laptop, the agent can run these
itself instead of asking:

```sh
lscpu | grep 'Model name'
lspci -nn | grep -iE 'vga|3d|network'      # MX450? which Wi-Fi chip?
lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME,LABEL,MOUNTPOINTS
findmnt -no SOURCE,TARGET,FSTYPE /boot /efi /boot/efi
sudo efibootmgr
cat /sys/power/mem_sleep                   # s2idle vs deep
sudo dmidecode -s system-version; sudo dmidecode -s bios-version
```

The **ESP size and location** decide round 3 — a Windows ESP is usually only
100–260 MB, too small to hold kernels.

**Q10 — Windows prep, before touching the BIOS.** Turning Secure Boot off can
make BitLocker ask for the recovery key. In an elevated PowerShell:

- `manage-bde -status C:` — is BitLocker on?
- If it is, store the recovery key off the machine first.
- `powercfg /h off` — Fast Startup off, or Windows keeps the NTFS volume locked.

This becomes **step 0** of the guide.

**Q11 — root filesystem.** ext4 vs btrfs + snapper. [ext4: simpler, the other
boxes use it, rollback via `downgrade` + the pacman cache. btrfs is fine if the
user wants to learn it now, but snapshot booting then constrains the
bootloader.]

**Q12 — Secure Boot long term.** It must be off for the install. Afterwards:
leave it off, or add a later appendix that re-enables it with self-signed keys
(`sbctl`). [The `sbctl` appendix, done after the system is stable; leaving it off
is fine if no Windows game needs anti-cheat.]

**Q13 — swap / hibernate.** [zram only, no hibernate — consistent with
[ADR 0015](docs/adr/0015-zram-swap-for-oom-resilience.md); a 16 GB swap inside
LUKS complicates the boot chain.]

**Q14 — fallback kernel.** [`linux` + `linux-lts`, for a boot entry that
survives a bad kernel.]

**Q15 — home lab scope.** [This guide covers `sshd` + DHCP reservation + mDNS +
the wired section + battery conservation mode (useful even without a home lab).
Lid-close behaviour, Docker, opening firewall ports and headless operation go to
a later guide. Add "home lab" to `CONTEXT.md` only once that role is real.]

**Q16 — doc split.** [Two files, matching the `zram.md` /
`memory-swap-concepts.vi.md` convention, linked both ways:

- `docs/arch-install.vi.md` — the steps.
- `docs/boot-disk-network-concepts.vi.md` — the theory: UEFI, GPT, ESP, LUKS,
  initramfs, bootloader, DHCP/DNS, mDNS.]

### Round 3 — not yet asked (blocked on Q9, Q11, Q12, Q14)

- **Partition and ESP plan.** Windows partitions stay untouched; the old
  EndeavourOS partitions are reused or wiped. Choose between:
  - reusing the Windows ESP;
  - an XBOOTLDR partition at `/boot` with the Windows ESP at `/efi`;
  - a separate Linux ESP.
- **Bootloader.** Whichever is chosen, the kernel-cmdline edits in
  [docs/zram.md](docs/zram.md) (`zswap.enabled=0`) and
  [docs/greetd.md](docs/greetd.md) must translate to it.
  - GRUB: the repo's docs assume it; `os-prober` finds Windows on another ESP.
  - systemd-boot: archinstall's default; it auto-detects Windows only on the
    same ESP.
  - Limine.
- **GPU.** With an MX450: `nvidia-open` + PRIME. Without one: `amd-ucode` +
  `mesa` + `vulkan-radeon`.
- **Wi-Fi workarounds** for the chip Q9 reveals (RTW89 / MT7921 ASPM — research
  note §1.2).
- **Placeholders.** Hostname and username appear as placeholders in the guide;
  the real values never go into the repo.

### After the frontier is empty

Wait for the user to confirm a shared understanding, then:

1. Write the two docs.
2. Update the README (Distro row, docs table) and the `docs/packages.md`
   baseline wording, and decide how a plain-Arch box installs the package list.
3. Run `just fmt && just check`.
4. Commit: gitmoji + Conventional Commits, **no** AI co-author trailer.

### Suggested skills

- `mattpocock-skills:grill-with-docs` — resume at **round 2**; do not re-ask
  round 1.
- `mattpocock-skills:research` — for anything the research note lists under
  "Open questions" or marks unverified.
- `git-workflow` — for the commits.

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
