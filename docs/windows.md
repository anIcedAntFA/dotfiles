# Windows host + WSL guest

How this setup runs on a box where Linux may not be the booted OS: Windows 11 on
the metal, Arch Linux inside WSL2 for everything terminal-shaped.

- **Why this shape:** [ADR 0025](adr/0025-wsl-guest-for-the-terminal-layer-on-windows.md)
- **Terms** (_Desktop host_, _WSL guest_, _Windows host_): [CONTEXT.md](../CONTEXT.md)
- **Per-tool evidence** (versions, licences, sources): [research/windows-migration.md](research/windows-migration.md)

> **Status: written on Linux, not yet run on Windows.** Everything in
> [What to verify on Windows](#what-to-verify-on-windows) is still open. Tick the
> boxes as you go and fix this page where reality disagrees.

## The split

| Layer                                            | Lives in          | Managed by                                    |
| ------------------------------------------------ | ----------------- | --------------------------------------------- |
| fish, zellij, starship, git, mise, ghq, gopass   | WSL guest         | chezmoi — the same `home/` source as on Linux |
| Repos (`ghqRoot`), Docker, Claude Code           | WSL guest         | —                                             |
| Terminal emulator, tiling WM, launcher, IME      | Windows host      | by hand, from [`windows/`](../windows/)       |
| Editors, browsers, chat                          | Windows host      | `winget import` of `packages/winget.json`     |
| niri, Noctalia, darkman, fcitx5, greetd, Ghostty | Desktop host only | chezmoi — skipped on a WSL guest              |

chezmoi tells a WSL guest from a Desktop host by the kernel release string (WSL2
tags it `microsoft`); nothing is prompted. On a guest, `home/.chezmoiignore`
drops every desktop target and the package script switches to the terminal-only
lists. The **machine profile** does not change: a WSL guest on the work box is
still `work`.

### What replaces what

| On the Desktop host         | On the Windows host                                         |
| --------------------------- | ----------------------------------------------------------- |
| niri                        | GlazeWM — `windows/glazewm/config.yaml`, niri-style keys    |
| Ghostty                     | WezTerm (nightly) — `windows/wezterm/wezterm.lua`           |
| Noctalia launcher           | PowerToys Command Palette                                   |
| Noctalia clipboard          | `Win+V`                                                     |
| darkman                     | PowerToys Light Switch                                      |
| fcitx5-bamboo / -hangul     | Built-in Vietnamese Telex and Korean IMEs                   |
| satty, dot-screenshot       | Snipping Tool (`Win+Shift+S`) or ShareX                     |
| gpu-screen-recorder         | OBS Studio                                                  |
| zathura                     | SumatraPDF                                                  |
| gnome-keyring               | Not needed — nothing in the guest asks for a Secret Service |
| GlobalProtect (openconnect) | The official client, deployed by IT                         |

GlazeWM is an i3-style tree, not a scrolling strip. komorebi does have a
scrolling layout, but its licence forbids use at work without a paid individual
licence, so it is not used here.

## Before leaving Linux

Windows cannot read the Linux partition on this box: `wsl --mount` attaches
whole disks only and refuses the disk Windows booted from. Anything needed on
the other side has to be pushed out first; anything forgotten costs a reboot.

1. Push what belongs on a remote. List what is not there yet:

   ```sh
   for r in $(ghq list -p); do
     git -C "$r" status -sb | head -1
     git -C "$r" stash list | wc -l
     git -C "$r" log --branches --not --remotes --oneline | wc -l
   done
   ```

2. Pack the rest — whole repo directories that carry stashes or gitignored
   files, plus keys and per-machine config — into **one encrypted archive**. Copy
   repos as an archive, never as loose files: NTFS drops modes, ownership and
   symlinks, and leaves private keys world-readable.

   ```sh
   tar --zstd -cf handoff.tar.zst -C ~ <paths…>
   gpg --symmetric --cipher-algo AES256 -o handoff.tar.zst.gpg handoff.tar.zst
   ```

   Include `~/.ssh`, `~/.config/chezmoi/chezmoi.toml`, the gopass store, an
   export of the GPG secret keys (`gpg --export-secret-keys --armor`,
   `gpg --export-ownertrust`), `~/.config/fish/local.fish`, and `~/.claude*`.

3. Write it to an NTFS volume with `ntfs-3g`, and check the mount came up
   read-write. A **read-only** mount means Windows is hibernated or Fast Startup
   holds the volume: stop, boot Windows, run `powercfg /h off`, try again. Never
   force it. Check `lsblk -f` first — `BitLocker` instead of `ntfs` means hands off.

## Windows host

Run in order. Each step that needs an elevated terminal says so.

1. **WSL + Arch** (elevated, then reboot):

   ```powershell
   wsl --install archlinux
   wsl --set-default archlinux
   ```

   The second line matters when another distro is already there (this box
   shipped with `Ubuntu-22.04` as the default): bare `wsl`, VS Code's WSL
   extension and `\\wsl.localhost\` all follow the default. Leave the old
   distro alone until the checklist below is ticked, then drop it with
   `wsl --unregister <name>` — that deletes its filesystem for good.

2. **Apps:**

   ```powershell
   winget import -i packages\winget.json --ignore-unavailable --accept-package-agreements
   ```

   The repo is not on Windows yet at this point — open it from the guest once
   step 1 of the next section is done (`\\wsl.localhost\archlinux\home\<you>\…`),
   or install the handful of ids by hand.

3. **`windows/` files** — copy, do not symlink (symlinks need Developer Mode):

   | From                                   | To                                           |
   | -------------------------------------- | -------------------------------------------- |
   | `windows/wsl/.wslconfig`               | `%USERPROFILE%\.wslconfig`                   |
   | `windows/glazewm/config.yaml`          | `%USERPROFILE%\.glzr\glazewm\config.yaml`    |
   | `windows/wezterm/wezterm.lua`          | `%USERPROFILE%\.config\wezterm\wezterm.lua`  |
   | `home/dot_config/ghostty/backgrounds/` | `%USERPROFILE%\.config\wezterm\backgrounds\` |

   WezTerm is a port of the Ghostty config: same palettes, background images,
   light/dark follow and `Alt` keybinds. It opens straight into the Arch guest
   once that distro exists, and in PowerShell until then. The **nightly** build
   is used on purpose — the last tagged release is from February 2024. Ghostty
   has no Windows build; Windows Terminal and Alacritty were passed over because
   neither does a per-mode background image.

4. **Input:** Settings → Time & language → Language & region → add Vietnamese
   (Telex) and Korean.

5. **PowerToys:** enable Command Palette and Light Switch. Rebind Command
   Palette to `Win+D` if GlazeWM leaves that key free.

6. **Editors:** VS Code with the _WSL_ extension, or Zed's WSL remote — both open
   folders that live in the guest. Settings: turn on Settings Sync, or copy
   `home/dot_config/Code/User/settings.json` and `home/dot_config/zed/` across.

## WSL guest

1. **User and sudo.** The Arch image boots as root with no user:

   ```sh
   pacman -Syu sudo
   useradd -m -G wheel <you> && passwd <you>
   EDITOR=nano visudo          # uncomment the %wheel line
   ```

   Then, back in PowerShell: `wsl --manage archlinux --set-default-user <you>`.

2. **Restore the hand-off archive** from the mounted Windows drive:

   ```sh
   sudo pacman -S --needed gnupg zstd
   gpg -d /mnt/<drive>/linux-handoff/linux-handoff.tar.zst.gpg | tar --zstd -xf - -C ~
   gpg --import ~/gpg-secret-keys.asc && gpg --import-ownertrust ~/gpg-ownertrust.txt
   shred -u ~/gpg-secret-keys.asc ~/gpg-ownertrust.txt
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
   ```

3. **Dotfiles:**

   ```sh
   sudo pacman -S --needed git chezmoi
   chezmoi init --apply <this repo>      # reuses the restored chezmoi.toml
   sudo cp "$(chezmoi source-path)/../etc/wsl.conf" /etc/wsl.conf
   ```

4. **Packages:**

   ```sh
   cd "$(chezmoi source-path)/.."
   sudo pacman -S --needed - < <(grep -v '^#' packages/pacman-wsl.txt)
   chsh -s /usr/bin/fish
   ```

   `yay` is an EndeavourOS package, not an Arch one — build it from the AUR
   first if `packages/aur-wsl.txt` is wanted. `rtk` and `lefthook` are in
   neither; install them as on Linux ([rtk.md](rtk.md), `mise install`).

5. **Restart the guest** so `wsl.conf` and the new shell take effect:
   `wsl --shutdown` from PowerShell, then open the Arch profile.

6. **Repos:** `ghq get` the clean ones. Keep them in the guest's filesystem, never
   under `/mnt/c` — cross-OS file access is the slow path, and NTFS loses modes
   and case sensitivity.

7. **Docker:** `sudo systemctl enable --now docker` and add yourself to the
   `docker` group. No Docker Desktop, so no licence question.

## What to verify on Windows

Nothing below could be checked from Linux.

- [ ] Account rights: local admin, on-demand elevation, or neither?
- [ ] `wsl --status` works and `wsl --install archlinux` is allowed by policy.
      _2026-10-12: works — WSL 2, an `Ubuntu-22.04` distro is already the
      default. The Arch install is still untried._
- [x] `manage-bde -status C:` — is BitLocker on, or about to be? If so, stop
      mounting Windows volumes from Linux. _2026-10-12: off, fully decrypted._
- [x] `powercfg /a` — Fast Startup / hibernation state; may it be turned off?
      _2026-10-12: `powercfg /h off` accepted; hibernation and Fast Startup are
      both unavailable, only S3 standby is left._
- [ ] `winget --version` works and reaches its source through the proxy.
      _2026-10-12: v1.29.380. Reaching the source is still untried._
- [ ] Is a third-party window manager allowed? GlazeWM starts and takes the
      `Win` binds (`Win+L` cannot be rebound; `Win+digit` should be).
- [ ] WezTerm loads `wezterm.lua` without a config error and opens in the Arch
      guest (domain `WSL:archlinux`).
- [ ] WezTerm: the background image shows, and palette + image flip when
      Windows switches light/dark.
- [ ] WezTerm: `Alt+Space` works as the leader (Windows uses it for the window
      menu) and the `Alt` binds do not collide with GlazeWM.
- [ ] Networking inside the guest with the VPN up. If it fails, uncomment the
      three lines in `.wslconfig`.
- [ ] `gopass ls` decrypts one secret; `git commit -S` signs; `ssh -T` reaches
      both git hosts — **before** anything on the Linux side is removed.
- [ ] Claude Code inside the guest: both accounts (`claude`, `claude-work`), the
      search-guard hook, the status line.
- [ ] `wl-copy` / `wl-paste` reach the Windows clipboard through WSLg (used by
      `dot-clip-copy` / `dot-clip-paste`).
- [ ] fish theme: `auto-sync-theme` is a no-op without dconf, so the guest keeps
      whichever theme was last chosen. Decide whether to pin one.
- [ ] Fonts: JetBrainsMono Nerd Font renders prompt glyphs in WezTerm.

## References

- [Arch Linux WSL image](https://gitlab.archlinux.org/archlinux/archlinux-wsl)
- [WSL configuration (`wsl.conf`, `.wslconfig`)](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
- [Mount a Linux disk in WSL 2 — limitations](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
- [GlazeWM](https://github.com/glzr-io/glazewm) · [komorebi licence](https://github.com/LGUG2Z/komorebi/blob/master/LICENSE.md)
- [WezTerm configuration files](https://wezterm.org/config/files.html) · [WSL domains](https://wezterm.org/config/lua/WslDomain.html)
- [`winget import`](https://learn.microsoft.com/en-us/windows/package-manager/winget/import)
- [chezmoi: detect WSL](https://www.chezmoi.io/user-guide/machines/windows/#detect-windows-subsystem-for-linux-wsl)
