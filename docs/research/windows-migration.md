# Migrating this setup from EndeavourOS + niri to Windows 11

Research note — investigated 2026-10-12. Question: the work machine may no
longer run Linux, so which parts of this repo's workflow (niri, Noctalia, fish,
Ghostty, the CLI layer, mise, chezmoi, gopass, Claude Code) survive on Windows
11, natively and under WSL2, and how does the data get across a dual-boot disk
safely? Whether WSL2 is permitted is unknown, so both paths are covered.

Method: primary sources only (project repos, release feeds, first-party docs,
Microsoft Learn). Release versions are what the project's own GitHub release
feed showed on 2026-10-12. Package ids were checked for existence against
`microsoft/winget-pkgs` and the `ScoopInstaller` buckets; "none found" means the
id I tried returned 404, not that no package exists. Anything not seen in a
primary source is marked **unverified**. The "config reuse" column is my
assessment, not a quoted claim.

## Verdict

**Fully portable (native Windows builds, same config format).** Almost the whole
CLI layer: starship, zoxide, fzf, fd, ripgrep, bat, eza, delta, jq, hyperfine,
duf, ouch, peco, curlie, fastfetch, direnv, ghq, just, lefthook, gitleaks,
dprint, rumdl, shellcheck, shfmt, gh, go, uv, git-cliff, lazydocker, neovim, Zed,
VS Code, mise, chezmoi, gopass, rtk, Claude Code. **zellij is on this list** —
native Windows since v0.44.0.

**Needs a Windows equivalent.**

- Shell: fish has no native Windows build (WSL, Cygwin or MSYS2 only) →
  PowerShell 7 natively, or keep fish inside WSL2.
- Terminal: Ghostty has no Windows app and the port was closed on 2026-10-10 →
  Windows Terminal (or WezTerm / Alacritty).
- Desktop: niri → komorebi (has a `scrolling` layout, but its licence forbids
  use at work without a paid licence) or GlazeWM (GPL-3.0, no scrolling layout);
  Noctalia → YASB or Zebar; fuzzel → PowerToys Command Palette / Flow Launcher;
  darkman → PowerToys Light Switch or Windows Auto Dark Mode; satty → ShareX /
  Snipping Tool; gpu-screen-recorder → OBS; cliphist → Win+V; zathura →
  SumatraPDF; fcitx5-bamboo → built-in Vietnamese Telex or UniKey; fcitx5-hangul
  → built-in Korean IME; btop → btop4win; gnome-keyring → Windows Credential
  Manager; globalprotect-openconnect → the official GlobalProtect app.
- Containers: every Linux-container option on Windows (Docker Desktop, Podman,
  Rancher Desktop) sits on WSL2 or Hyper-V. If WSL2 is banned, check Hyper-V.

**Dropped entirely.** niri, Noctalia, greetd, swaylock/swaybg, xdg-desktop-portal,
xwayland-satellite, wl-clipboard, nwg-look/qt5ct/qt6ct, `environment.d`, systemd
user units, zram, firewalld, and every `home/dot_local/bin/dot-*` script (all
drive Wayland tools).

**The three findings that change the plan.**

1. `wsl --mount` cannot read the ext4 partition because it lives on the same
   NVMe as Windows. There is no first-party way to read ext4 from Windows on this
   machine — the hand-off has to be pushed from the Linux side.
2. komorebi is the only Windows WM found with a scrolling layout, and its licence
   says plainly that it "does not permit any kind of commercial use (i.e. using
   `komorebi` at work)".
3. On Windows chezmoi has no default interpreter for `.sh`, so all five scripts
   in `home/.chezmoiscripts/` need gating, and `private_`/`executable_` are
   no-ops.

## 1. Per-tool status

### 1.1 Shell and terminal

| Tool      | Native Windows                        | winget                              | scoop                | Windows config path                                                             | Config reuse                            | Latest seen                   |
| --------- | ------------------------------------- | ----------------------------------- | -------------------- | ------------------------------------------------------------------------------- | --------------------------------------- | ----------------------------- |
| fish      | **no** (WSL / Cygwin / MSYS2)         | none found                          | none found           | n/a natively                                                                    | as-is inside WSL; rewrite for pwsh      | 4.9.3 (2026-09-08)            |
| Ghostty   | **no**                                | —                                   | —                    | —                                                                               | rewrite for Windows Terminal            | v1.3.1 (2026-03-13)           |
| zellij    | **yes** (since 0.44.0)                | `Zellij.Zellij`                     | `zellij`             | `ZELLIJ_CONFIG_DIR` or `--config-dir`; default Windows dir **unverified**       | as-is (KDL); default shell needs a tmpl | v0.45.1 (2026-08-28)          |
| starship  | yes                                   | `Starship.Starship`                 | `starship`           | `~/.config/starship.toml` or `STARSHIP_CONFIG`                                  | as-is                                   | v1.26.0 (2026-06-28)          |
| zoxide    | yes                                   | `ajeetdsouza.zoxide`                | `zoxide`             | data in `%LOCALAPPDATA%\zoxide`                                                 | no config file; init line per shell     | v0.10.0 (2026-07-04)          |
| fzf       | yes                                   | `junegunn.fzf`                      | `fzf`                | env vars                                                                        | env vars move to the pwsh profile       | v0.74.5 (2026-10-11)          |
| fd        | yes                                   | `sharkdp.fd`                        | `fd`                 | `%APPDATA%\fd\ignore`                                                           | as-is, new target path                  | v10.5.0 (2026-08-26)          |
| ripgrep   | yes                                   | `BurntSushi.ripgrep.MSVC`           | `ripgrep`            | whatever `RIPGREP_CONFIG_PATH` points at                                        | as-is                                   | 15.2.0 (2026-07-15)           |
| bat       | yes                                   | `sharkdp.bat`                       | `bat`                | `BAT_CONFIG_PATH` / `BAT_CONFIG_DIR`; default dir **unverified**                | as-is                                   | v0.26.1 (2025-12-02)          |
| eza       | yes                                   | `eza-community.eza`                 | `eza`                | **unverified**                                                                  | aliases move to the pwsh profile        | v0.23.5 (2026-07-09)          |
| git-delta | yes                                   | `dandavison.delta`                  | `delta`              | lives in git config                                                             | as-is                                   | 0.20.1 (2026-10-04)           |
| direnv    | yes (`.exe` assets, pwsh hook)        | `direnv.direnv`                     | `direnv`             | **unverified**                                                                  | `.envrc` is bash — needs a bash on PATH | v2.38.2 (2026-10-10)          |
| btop      | **no** — upstream: "not in the plans" | `aristocratos.btop4win`             | `btop` (is btop4win) | **unverified**                                                                  | rewrite / drop                          | btop4win v1.0.5 (2025-10-13)  |
| fastfetch | yes (Windows 8.1+)                    | `Fastfetch-cli.Fastfetch`           | `fastfetch`          | `~/.config/fastfetch/config.jsonc` per README; Windows specifics **unverified** | needs templating (Linux-only modules)   | 2.69.0 (2026-09-25)           |
| superfile | partial ("Not fully supported yet")   | `yorukot.superfile`                 | `superfile`          | **unverified**                                                                  | probably as-is                          | v1.6.0 (2026-06-07)           |
| tldr      | yes (other client)                    | `tldr-pages.tlrc`, `dbrgn.tealdeer` | `tlrc`, `tealdeer`   | —                                                                               | n/a                                     | tlrc v1.13.1, tealdeer v1.9.0 |
| jq        | yes                                   | `jqlang.jq`                         | `jq`                 | —                                                                               | n/a                                     | jq-1.8.2 (2026-06-20)         |
| hyperfine | yes                                   | `sharkdp.hyperfine`                 | `hyperfine`          | —                                                                               | n/a                                     | v2.0.0 (2026-10-07)           |
| duf       | yes                                   | `muesli.duf`                        | `duf`                | —                                                                               | n/a                                     | v0.9.1 (2025-09-08)           |
| ouch      | yes                                   | none found                          | `ouch`               | —                                                                               | n/a                                     | 0.8.3 (2026-09-13)            |
| peco      | yes                                   | `peco.peco`                         | `peco`               | —                                                                               | fish functions need a pwsh rewrite      | v0.6.0 (2026-02-24)           |
| curlie    | yes                                   | none found                          | `curlie`             | —                                                                               | n/a                                     | v1.8.2 (2025-03-07)           |

Evidence:

- **fish.** The README's Windows section lists only WSL and "Cygwin or MSYS2";
  there is no Windows asset on the 4.9.3 release. Cygwin support "has been
  reintroduced" in 4.1.0 (2025-09-27) because Rust gained a Cygwin target; 4.2.0
  and 4.3.0 carry MSYS2-specific fixes. MSYS2 packages fish 4.9.3-2.
  <https://github.com/fish-shell/fish-shell/blob/master/README.rst> ·
  <https://github.com/fish-shell/fish-shell/blob/master/CHANGELOG.rst> ·
  <https://packages.msys2.org/base/fish>
- **Ghostty.** Maintainer on the Windows-support discussion, 2026-10-10: "Going
  to close and lock this discussion. We'll certainly support building/using
  `libghostty-vt` on Windows just as much as we do any other platform but further
  discussion of porting Ghostty to Windows is closed." A PR to build and test the
  core on Windows again was closed the same week, with the author told that
  wanting the GUI on Windows means forking. Official binaries are macOS only.
  <https://github.com/ghostty-org/ghostty/discussions/2563> ·
  <https://github.com/ghostty-org/ghostty/pull/14608> ·
  <https://ghostty.org/docs/install/binary>
- **zellij.** Changelog 0.44.0: "platform: native Windows support". The v0.45.1
  release ships `zellij-x86_64-pc-windows-msvc.zip` and an `.msi`.
  <https://github.com/zellij-org/zellij/blob/main/CHANGELOG.md> ·
  <https://github.com/zellij-org/zellij/releases/tag/v0.45.1> ·
  <https://zellij.dev/documentation/configuration.html>
- **btop.** README: "Windows support is not in the plans as of now"; the same
  author's `btop4win` is the port, and scoop's `btop` manifest points at it.
  <https://github.com/aristocratos/btop> ·
  <https://github.com/ScoopInstaller/Main/blob/master/bucket/btop.json>
- Config paths: <https://starship.rs/config/> ·
  <https://github.com/ajeetdsouza/zoxide#configuration> ·
  <https://github.com/sharkdp/fd#excluding-specific-files-or-directories> ·
  <https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file> ·
  <https://github.com/sharkdp/bat#configuration-file> ·
  <https://direnv.net/docs/hook.html> ·
  <https://github.com/fastfetch-cli/fastfetch#readme> ·
  <https://github.com/yorukot/superfile#supported-systems>

#### Replacing fish

| Option       | What the sources say                                                                                                                                                                                                                                                                                               | Cost for this repo                                                                                |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| PowerShell 7 | starship, zoxide, mise (`mise activate pwsh`) and direnv (`direnv hook pwsh`) all document a PowerShell init line. mise re-evaluates on directory change in PowerShell 7+, only at the next prompt in 5.x. chezmoi runs `.ps1` with `pwsh` by default. v7.6.6 (2026-09-08), `Microsoft.PowerShell` / scoop `pwsh`. | Rewrite `config.fish` and the functions as a profile. Best-supported native target.               |
| Nushell      | starship supports v0.96+, zoxide v0.106.0+, direnv documents a hook; mise's Nushell hook waits for the first prompt. Config in `%APPDATA%\nushell`. 0.116.1 (2026-10-04), `Nushell.Nushell` / scoop `nu`.                                                                                                          | Same rewrite, into a pre-1.0 language with version floors per tool.                               |
| fish in WSL2 | Everything under `home/dot_config/fish/` runs unchanged.                                                                                                                                                                                                                                                           | Zero rewrite; only possible if WSL2 is allowed, and Windows-side tools still need a native shell. |

Profile path: `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
(current user, current host). Microsoft warns against the `Documents` folder
being redirected or put in OneDrive — on a managed machine it often is, so read
`$PROFILE` instead of assuming. The default execution policy on Windows clients
is `Restricted`, and Group Policy can pin it.
<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles> ·
<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies> ·
<https://mise.jdx.dev/dev-tools/shims.html> ·
<https://www.nushell.sh/book/configuration.html>

#### Replacing Ghostty

| Terminal         | Status                                                                                                                                                | Config                                                                                                                                                                                      |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Windows Terminal | First-party; stable v1.25.2733.0 (2026-10-02). `Microsoft.WindowsTerminal` / scoop `windows-terminal`.                                                | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` (Store); `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json` (unpackaged). JSON — rewrite. |
| WezTerm          | Last tagged stable is `20240203-110809-5046fc22`; the release feed since then only carries crate tags and nightlies. `wez.wezterm` / scoop `wezterm`. | `%USERPROFILE%/.wezterm.lua` or `~/.config/wezterm/wezterm.lua` — one Lua file for both OSes.                                                                                               |
| Alacritty        | v0.17.0 (2026-04-06). `Alacritty.Alacritty` / scoop `alacritty`. Already in `pacman-explicit.txt`.                                                    | `%APPDATA%\alacritty\alacritty.toml` — same TOML as Linux.                                                                                                                                  |

Windows Terminal is the low-risk default (first-party, most likely already
installed and allowed). WezTerm is the only one whose config is a single
cross-OS file at an XDG-style path, at the price of running a two-year-old
stable or nightlies.
<https://learn.microsoft.com/en-us/windows/terminal/install> ·
<https://wezterm.org/config/files.html> ·
<https://github.com/wezterm/wezterm/releases> ·
<https://github.com/alacritty/alacritty/blob/master/extra/man/alacritty.5.scd>

### 1.2 Desktop

| Linux piece             | Windows replacement                                                 | Install                                                            | Notes                                                                                                          |
| ----------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| niri                    | komorebi v0.1.41 (2026-05-03)                                       | `LGUG2Z.komorebi` + `LGUG2Z.whkd`; scoop extras `komorebi`, `whkd` | Has a `scrolling` layout. **Not licensed for work use** — see below.                                           |
|                         | GlazeWM v3.10.1 (2026-03-21)                                        | `glzr-io.glazewm`; scoop extras `glazewm`                          | GPL-3.0. i3-style tiling; no scrolling layout in its README. Config `%userprofile%\.glzr\glazewm\config.yaml`. |
| Noctalia                | YASB v2.0.7 (2026-09-11)                                            | `AmN.yasb`; scoop extras `yasb`                                    | Python status bar; ships komorebi and GlazeWM widgets.                                                         |
|                         | Zebar v3.3.1 (2026-03-16)                                           | `glzr-io.zebar`; scoop extras `zebar`                              | From the GlazeWM authors; widget packs under `~/.glzr/zebar`.                                                  |
| fuzzel                  | PowerToys Command Palette                                           | `Microsoft.PowerToys`; scoop extras `powertoys`                    | Microsoft calls it "PowerToys Run's evolution". PowerToys stable v0.101.2362.0 (2026-08-25).                   |
|                         | Flow Launcher v2.1.4 (2026-09-20)                                   | `Flow-Launcher.Flow-Launcher`; scoop extras `flow-launcher`        |                                                                                                                |
| darkman                 | PowerToys Light Switch                                              | part of PowerToys                                                  | First-party sunrise/sunset or fixed schedule.                                                                  |
|                         | Windows Auto Dark Mode                                              | scoop extras `auto-dark-mode` (11.1.1.1); winget id **unverified** | Release date not captured.                                                                                     |
| satty + screenshot      | Snipping Tool, ShareX v21.0.0 (2026-07-03)                          | `ShareX.ShareX`; scoop extras `sharex`                             |                                                                                                                |
| gpu-screen-recorder     | OBS Studio 32.2.2 (2026-08-14)                                      | `OBSProject.OBSStudio`; scoop extras `obs-studio`                  |                                                                                                                |
| cliphist                | Win+V clipboard history                                             | built in                                                           | Limited to 25 entries.                                                                                         |
| zathura                 | SumatraPDF 3.6.1 (2026-04-06)                                       | `SumatraPDF.SumatraPDF`; scoop extras `sumatrapdf`                 |                                                                                                                |
| Thunar                  | File Explorer                                                       | built in                                                           |                                                                                                                |
| fcitx5-bamboo           | Built-in Vietnamese Telex IME                                       | Settings → Language                                                | First-party; Telex is the default when Vietnamese is added.                                                    |
|                         | UniKey 4.6 RC2 (build 230919)                                       | `UniKey.UniKey`; portable zip                                      | Last release 2023-09-19.                                                                                       |
|                         | OpenKey 2.0.5                                                       | none found                                                         | Last GitHub release 2022-07-02; README describes it as a macOS input app. Treat as unmaintained on Windows.    |
|                         | EVKey                                                               | `lamquangminh.EVKey`                                               | Last GitHub release entry 2019-07-27; current version on its site **unverified**.                              |
| fcitx5-hangul           | Built-in Korean IME                                                 | Settings → Language                                                | First-party.                                                                                                   |
| Banana / Bibata cursors | same themes, Windows builds                                         | manual                                                             | Banana's README documents Windows cursor builds; Bibata Windows packaging **unverified**.                      |
| Maple Mono              | scoop `nerd-fonts` bucket: `Maple-Mono`, `Maple-Mono-NF`            | `scoop bucket add nerd-fonts`                                      | No winget id found. Stable v7.9 (2025-12-05).                                                                  |
| JetBrainsMono Nerd Font | `DEVCOM.JetBrainsMonoNerdFont`; scoop nerd-fonts `JetBrainsMono-NF` |                                                                    | Nerd Fonts v3.5.1 (2026-08-21).                                                                                |

**Is there a scrollable-tiling WM for Windows?** Yes, one: komorebi's
`change-layout` accepts `scrolling` alongside `bsp`, `columns`, `grid` and the
rest, and `komorebic scrolling-layout-columns <COUNT>` sets the visible column
count. GlazeWM documents no equivalent.
<https://lgug2z.github.io/komorebi/cli/change-layout.html> ·
<https://github.com/LGUG2Z/komorebi/blob/master/docs/cli/scrolling-layout-columns.md> ·
<https://github.com/glzr-io/glazewm#readme>

**komorebi's licence, read carefully.** It is the "Komorebi License 2.0.0", a
fork of PolyForm Strict, not an open-source licence. The only permitted purpose
it names is:

> Personal use for research, experiment, and testing for the benefit of public
> knowledge, personal study, private entertainment, hobby projects, amateur
> pursuits, or religious observance, without any anticipated commercial
> application, is use for a permitted purpose.

The README removes any doubt: the licence "does not permit any kind of
commercial use (i.e. using `komorebi` at work)". A paid "Individual Commercial
Use License" adds commercial use "for the licensed individual only, for the
duration of a valid paid license". So on a work machine komorebi is either a
personal purchase or off the table; GlazeWM is the licence-clean choice, at the
cost of the scrolling layout.
<https://github.com/LGUG2Z/komorebi/blob/master/LICENSE.md> ·
<https://github.com/LGUG2Z/komorebi#licensing-for-commercial-use>

Other sources: <https://github.com/amnweb/yasb#readme> ·
<https://github.com/glzr-io/zebar#readme> ·
<https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview> ·
<https://learn.microsoft.com/en-us/windows/powertoys/run> ·
<https://learn.microsoft.com/en-us/windows/powertoys/light-switch> ·
<https://support.microsoft.com/en-us/windows/clipboard-in-windows-c436501e-985d-1c8d-97ea-fe46ddf338c6> ·
<https://learn.microsoft.com/en-us/globalization/input/vietnamese-ime> ·
<https://learn.microsoft.com/en-us/globalization/input/korean-ime> ·
<https://www.unikey.org/en/download.html> ·
<https://github.com/tuyenvm/OpenKey> ·
<https://github.com/ful1e5/banana-cursor#readme> ·
<https://github.com/matthewjberger/scoop-nerd-fonts>

### 1.3 Dev tools

| Tool            | Native Windows | winget                                   | scoop                             | Notes                                                                               | Latest seen             |
| --------------- | -------------- | ---------------------------------------- | --------------------------------- | ----------------------------------------------------------------------------------- | ----------------------- |
| mise            | yes            | `jdx.mise`                               | `mise`                            | See below.                                                                          | v2026.10.8 (2026-10-11) |
| chezmoi         | yes            | `twpayne.chezmoi`                        | `chezmoi`                         | Section 2.                                                                          | v2.73.1 (2026-10-11)    |
| ghq             | yes            | `x-motemen.ghq`                          | `ghq`                             | `ghq.root` comes from git config.                                                   | v1.11.2 (2026-09-29)    |
| just            | yes            | `Casey.Just`                             | `just`                            | This repo's recipes call bash tools — needs Git Bash.                               | 1.58.0 (2026-08-03)     |
| lefthook        | yes            | `evilmartians.lefthook`                  | `lefthook`                        |                                                                                     | v2.2.1 (2026-10-08)     |
| gitleaks        | yes            | `Gitleaks.Gitleaks`                      | `gitleaks`                        |                                                                                     | v8.30.1 (2026-03-21)    |
| dprint          | yes            | `dprint.dprint`                          | `dprint`                          |                                                                                     | 0.63.0 (2026-10-11)     |
| rumdl           | yes            | `rvben.rumdl`                            | `rumdl`                           |                                                                                     | v0.2.79 (2026-10-09)    |
| shellcheck      | yes            | `koalaman.shellcheck`                    | `shellcheck`                      |                                                                                     | v0.11.0                 |
| shfmt           | yes            | `mvdan.shfmt`                            | `shfmt`                           |                                                                                     | v3.14.1 (2026-09-06)    |
| gh              | yes            | `GitHub.cli`                             | `gh`                              | Config in `%AppData%\GitHub CLI` unless `GH_CONFIG_DIR` / `XDG_CONFIG_HOME` is set. | v2.102.0 (2026-09-30)   |
| go              | yes            | `GoLang.Go`                              | `go`                              |                                                                                     | go1.27.2 (2026-10-08)   |
| uv              | yes            | `astral-sh.uv`                           | `uv`                              |                                                                                     | 0.13.0 (2026-10-09)     |
| turbo           | yes (npm)      | none found                               | none found                        | Install through the JS package manager.                                             | v2.11.7 (2026-10-02)    |
| Docker Desktop  | yes            | `Docker.DockerDesktop`                   | —                                 | Paid for larger companies — see below.                                              | not captured            |
| Podman Desktop  | yes            | `RedHat.Podman-Desktop`, `RedHat.Podman` | `podman`, extras `podman-desktop` | Apache-2.0. Needs WSL2 or Hyper-V.                                                  | v1.30.4 (2026-10-05)    |
| Rancher Desktop | yes            | `SUSE.RancherDesktop`                    | extras `rancher-desktop`          | Apache-2.0. Installs WSL distributions.                                             | v1.24.0 (2026-07-29)    |
| PostgreSQL      | yes            | `PostgreSQL.PostgreSQL.17`               | `postgresql`                      | Other major-version ids not checked.                                                | not captured            |
| pgAdmin         | yes            | `PostgreSQL.pgAdmin`                     | none found                        |                                                                                     | not captured            |
| Bruno           | yes            | `Bruno.Bruno`                            | extras `bruno`                    |                                                                                     | v4.2.1 (2026-09-30)     |
| flyctl          | yes            | `Fly-io.flyctl`                          | `flyctl`                          |                                                                                     | v0.4.115 (2026-10-08)   |
| neovim          | yes            | `Neovim.Neovim`                          | `neovim`                          | Config in `~/AppData/Local/nvim`.                                                   | v0.12.6 (2026-10-09)    |
| Zed             | yes (GA)       | `ZedIndustries.Zed`                      | extras `zed`                      | `%APPDATA%\Zed\settings.json`. See below.                                           | v1.23.2 (2026-10-07)    |
| VS Code         | yes            | `Microsoft.VisualStudioCode`             | extras `vscode`                   | `code-flags.conf` is Linux-only; `packages/vscode-extensions.txt` is reusable.      | not captured            |
| git-cliff       | yes            | `orhun.git-cliff`                        | `git-cliff`                       |                                                                                     | v2.14.2 (2026-09-18)    |
| git-filter-repo | yes (Python)   | none found                               | `git-filter-repo`                 | Upstream has "Notes for Windows Users" (python vs python3).                         | v2.47.0 (2024-12-04)    |
| meld            | yes            | `Meld.Meld`                              | extras `meld`                     |                                                                                     | not captured            |
| lazydocker      | yes            | `JesseDuffield.Lazydocker`               | `lazydocker`                      |                                                                                     | v0.25.2 (2026-04-19)    |

**mise on Windows.** The FAQ answers "Does mise work on Windows?" with "Yes.
mise runs natively on Windows, with PowerShell activation, shims" and so on, and
winget is the recommended install. What to know:

- Activation is `(&mise activate pwsh) | Out-String | Invoke-Expression` in
  `$PROFILE`. `cmd.exe` cannot be activated; put `%LOCALAPPDATA%\mise\shims` on
  the user `Path` instead.
- Editors and other GUI programs do not read `$PROFILE`, so they need the shims
  directory on `Path` too. "Shims do not set `[env]` variables in the shell
  itself."
- The scoop package puts only `mise` on `Path`, not the shims directory.
- "Tools from asdf plugins do not run on native Windows"; aqua, ubi, cargo, npm
  and vfox backends work when the tool itself supports Windows. This repo's
  `mise.toml` uses core/aqua tools only, so it should be unaffected —
  `mise registry <tool>` confirms per tool.
- Documented Windows problems: `PATH` longer than 8191 characters is ignored by
  `cmd.exe`; `.cmd` shims break Node-based editor extensions (keep
  `windows_shim_mode = "exe"`); tasks with `shell = "bash -c"` can pick up the
  WSL launcher instead of Git Bash (set `MISE_BASH_PATH`).
- Where the global config lives on Windows is **unverified** — the docs write
  `~/.config/mise` without a Windows-specific path.

<https://mise.jdx.dev/faq.html> · <https://mise.jdx.dev/installing-mise.html> ·
<https://mise.jdx.dev/shell-setup.html> · <https://mise.jdx.dev/dev-tools/shims.html> ·
<https://mise.jdx.dev/troubleshooting.html>

**Containers.** Docker Desktop is free only for "Small businesses (fewer than
250 employees AND less than $10 million in annual revenue)", personal use,
education and non-commercial open source; larger organisations and government
need a paid subscription. Podman Desktop and Rancher Desktop are Apache-2.0.
None of them escapes virtualisation: Podman "uses WSLv2 or Hyper-V", Hyper-V
needs a Pro/Enterprise/Education edition and its machine commands need
administrator rights or membership of Hyper-V Administrators; Docker Desktop's
per-user install uses the WSL 2 backend, with Hyper-V only in the all-users
install; Rancher Desktop registers `rancher-desktop` WSL distributions.
<https://docs.docker.com/subscription/desktop-license/> ·
<https://docs.docker.com/desktop/setup/install/windows-install/> ·
<https://github.com/containers/podman/blob/main/docs/tutorials/podman-for-windows.md> ·
<https://github.com/podman-desktop/podman-desktop/blob/main/LICENSE> ·
<https://docs.rancherdesktop.io/getting-started/installation/>

**Zed.** Generally available on Windows since 2025-10-15, on the same weekly
cadence as macOS and Linux. Needs a DirectX 11 GPU. Opens folders inside WSL
distributions and over SSH. Settings at `%APPDATA%\Zed\settings.json`, so
`home/dot_config/zed/` needs a second target path on Windows.
<https://zed.dev/blog/zed-for-windows-is-here> · <https://zed.dev/docs/windows> ·
<https://zed.dev/docs/configuring-zed>

### 1.4 Secrets and access

- **gopass + GnuPG.** gopass ships `windows-amd64` and `windows-arm64` builds
  (v1.17.4, 2026-10-10; scoop `gopass`, no winget id found) and its setup guide
  lists two Windows prerequisites: Gpg4win and Git for Windows. Config lives at
  `%APPDATA%\gopass\config`. Gpg4win is `GnuPG.Gpg4win` / scoop extras `gpg4win`
  (5.1.1); bare GnuPG is `GnuPG.GnuPG` / scoop `gnupg` (2.5.24). Gpg4win brings
  its own graphical pinentry, so `private_dot_gnupg/private_gpg-agent.conf`
  (which names a Linux pinentry) must not be applied on Windows. Two things are
  **unverified** from primary sources and need a check on the box: GnuPG's
  default home directory on Windows (the manual only documents the
  `HKCU\Software\GNU\GnuPG:HomeDir` override), and which `gpg.exe` wins on
  `Path` — Git for Windows bundles its own. Run `where gpg` and
  `gpg --version` (it prints the home dir), and point `gpg.program` at the
  Gpg4win binary if git picks the wrong one. gopass also has
  `core.casefold` for case-insensitive filesystems, off by default — relevant if
  any two secrets differ only in case.
  <https://github.com/gopasspw/gopass/blob/master/docs/setup.md> ·
  <https://github.com/gopasspw/gopass/blob/master/docs/config.md> ·
  <https://www.gpg4win.org/> ·
  <https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html>
- **gnome-keyring / Secret Service → Windows Credential Manager.** Git
  Credential Manager ships with Git for Windows and "the default credential
  stores on macOS and Windows are the macOS Keychain and the Windows Credential
  Manager". GCM v3.0.1 (2026-10-07). It only covers HTTP(S) remotes; SSH remotes
  are unaffected. None of `docs/secret-service.md` carries over.
  <https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/credstores.md> ·
  <https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-git>
- **OpenSSH.** A Windows feature on demand since Windows 10 1809; Microsoft's
  install table lists the client as "Not installed, install and enable using
  optional features" for Windows 10 and has no Windows 11 row, so check with
  `Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'`. Keys and
  config live in `%USERPROFILE%\.ssh\` (`ssh-keygen` defaults to
  `C:\Users\username/.ssh/`). "By default, the ssh-agent service is disabled";
  enabling it (`Set-Service -StartupType Automatic`) needs an **elevated**
  prompt. Instead of mode `0600`, Windows OpenSSH checks ACLs: "private keys
  need to be owned by the user and no other user should have access", otherwise
  it prints `UNPROTECTED PRIVATE KEY FILE` and refuses the key; the wiki gives
  the `icacls` fixes. chezmoi's `private_` prefix does not set this (section 2).
  The existing `private_dot_ssh/config.tmpl` uses only `~/.ssh/...` paths and
  portable options, so it should apply as-is.
  <https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse> ·
  <https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement> ·
  <https://github.com/PowerShell/Win32-OpenSSH/wiki/Security-protection-of-various-files-in-Win32-OpenSSH>
- **SSH commit signing.** `gpg.format = ssh` and `gpg.ssh.allowedSignersFile`
  are plain git config and work the same; `gpg.ssh.program` defaults to
  `ssh-keygen`. The catch is section 6: git must call the `ssh-keygen` that
  belongs to the same OpenSSH as the agent holding the key.
  <https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat>
- **GlobalProtect.** The official Windows app is not publicly downloadable; it
  comes from the organisation's own portal (`https://<portal>`), installs to
  `C:\Program Files\Palo Alto Networks\GlobalProtect`, and needs administrator
  rights for the first install only. On a managed machine IT normally deploys
  it. `vpn-connect.fish` and `docs/vpn.md` do not carry over.
  <https://docs.paloaltonetworks.com/globalprotect/user-guide/6-0/globalprotect-app-for-windows/download-and-install-the-globalprotect-app-for-windows> ·
  <https://docs.paloaltonetworks.com/ngfw/help/10-1/globalprotect/device-globalprotect-client/managing-the-globalprotect-agent-software>

### 1.5 AI tooling

- **Claude Code (v2.1.296, 2026-10-09).** Native Windows 10 1809+ is supported.
  Install with `irm https://claude.ai/install.ps1 | iex` (auto-updates, "You do
  not need to run as Administrator") or `winget install Anthropic.ClaudeCode`
  (no auto-update by default); scoop has `claude-code` too.
  - Git for Windows is **optional**, not required: "If Git for Windows is not
    installed, Claude Code uses PowerShell as the shell tool instead." With it,
    the Bash tool runs in Git Bash; `CLAUDE_CODE_GIT_BASH_PATH` points at
    `bash.exe` when it is not on `Path`.
  - Hooks: a shell-form command is passed to "`sh -c` on macOS and Linux, Git
    Bash on Windows, or PowerShell when Git Bash isn't installed"; the `shell`
    field (`"bash"` or `"powershell"`) chooses explicitly. So
    `hooks/executable_search-guard.sh` and `statusline-command.sh` keep working
    **only with Git for Windows installed, and with `jq` on `Path`** — both
    scripts call it. Status-line commands follow the same routing; write paths
    with forward slashes because Git Bash eats unquoted backslashes.
  - `~/.claude` is `%USERPROFILE%\.claude`; `~/.claude.json` sits beside it.
    `CLAUDE_CONFIG_DIR` overrides the directory and is documented as "Useful for
    running multiple accounts side by side", so the `claude` / `claude-work`
    split in `home/dot_config/fish/functions/` ports to two PowerShell functions.
    In a settings file the value must be an absolute path.
  - No sandboxing on native Windows (WSL2 only).
  - `home/dot_claude.work/symlink_skills` is a symlink target and needs symlink
    permission on Windows (section 2).

  <https://code.claude.com/docs/en/setup> · <https://code.claude.com/docs/en/hooks> ·
  <https://code.claude.com/docs/en/env-vars> · <https://code.claude.com/docs/en/settings> ·
  <https://code.claude.com/docs/en/statusline>
- **rtk (v0.51.0, 2026-10-02).** "RTK works fully on native Windows. Since
  v0.37.2 the auto-rewrite hook runs as a native binary command
  (`rtk hook claude`) — no Unix shell, bash, or jq required". `winget install
  rtk-ai.rtk` or scoop `rtk`; it expects `rg` on `Path`. The release ships only
  an `x86_64-pc-windows-msvc` build.
  <https://github.com/rtk-ai/rtk#windows>
- **Gemini CLI (v0.63.0, 2026-10-06).** Distributed through npm
  (`npm install -g @google/gemini-cli`), so it needs Node on Windows; no winget
  or scoop package found. Explicit Windows support statement **unverified**.
  <https://github.com/google-gemini/gemini-cli#readme>

## 2. chezmoi on Windows

This repo's source root is `home/` (via `.chezmoiroot`), which works the same on
Windows: it "is read before all other files in the source directory".

**Defaults barely differ.** Destination is `%USERPROFILE%`, source is
`%USERPROFILE%/.local/share/chezmoi`, config is
`%USERPROFILE%/.config/chezmoi/chezmoi.toml` — the Unix paths with
`%USERPROFILE%` for `$HOME`. The `~/.local/share/chezmoi` → repo symlink this
machine uses would need symlink permission on Windows; pointing `sourceDir` at
the checkout in `chezmoi.toml` avoids it.

**One repo, two OSes.**

- Branch inside templates on `.chezmoi.os` (`"linux"` / `"windows"`). WSL
  reports `linux`; tell it apart with
  `.chezmoi.kernel.osrelease | lower | contains "microsoft"`.
- `.chezmoiignore` "is interpreted as a template, whether or not it has a
  `.tmpl` extension", and its patterns match **target** paths. The docs' own
  example ignores `Documents/*` except the PowerShell profile on Windows. For
  this repo the Windows block would ignore the Linux-only targets:
  `.config/niri`, `.config/noctalia`, `.config/fuzzel`, `.config/darkman`,
  `.config/environment.d`, `.config/fcitx5`, `.config/ghostty`, `.config/fish`,
  `.config/satty`, `.config/zathura`, `.config/Thunar`, `.config/nwg-look`,
  `.config/qt5ct`, `.config/qt6ct`, `.config/xdg-desktop-portal`,
  `.config/user-dirs.*`, `.config/code-flags.conf`, `.local/bin`, `.gnupg`.
- Windows-only targets are ordinary source paths with no `dot_` prefix, for
  example `home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`,
  `home/AppData/Roaming/Zed/settings.json`,
  `home/AppData/Roaming/alacritty/alacritty.toml`,
  `home/AppData/Local/nvim/…` — each ignored on Linux by the mirror-image block.
  A config that both OSes share but at different paths (Zed, fd, gh) needs one
  shared template plus two thin target files that include it, or a `Path`-style
  environment variable that makes the tool read `~/.config` (starship, ripgrep
  and bat have one).

**Attributes.** The design FAQ says chezmoi "provides first-class support for
Windows, where the `executable_` and `private_` attributes have no direct
equivalents and symbolic links are not always permitted". In practice:

- `private_` — no NTFS ACL is set. `private_dot_ssh/` gets no protection from
  chezmoi; fix the key ACL by hand or in a `.ps1` script.
- `executable_` — no effect; Windows decides by extension.
- `symlink_` — needs Developer Mode or `SeCreateSymbolicLinkPrivilege`.
  "Enabling Developer mode requires administrator access. If your device is
  owned by an organization, this option may be disabled." This repo has exactly
  one: `dot_claude.work/symlink_skills`.

**Scripts.** "Windows will natively execute scripts with a `.bat`, `.cmd`,
`.com`, and `.exe` extensions. Other extensions require an interpreter". Defaults
exist for `.nu`, `.pl`, `.py`, `.ps1` (`pwsh -NoLogo -File`, falling back to
Windows PowerShell) and `.rb` — **not `.sh`**. All five scripts in
`home/.chezmoiscripts/` are `.sh.tmpl`. Options, in order of preference:

1. Wrap each body in `{{ if eq .chezmoi.os "linux" }}`: "If the template
   resolves to only whitespace or an empty string, the script will not be
   executed".
2. Ignore them by target path in `.chezmoiignore`.
3. Add `[interpreters.sh]` pointing at Git Bash — only worth it for
   `setup-git-signers`, which is the one script whose job exists on Windows.

Windows-side scripts are `.ps1` with the same `run_once_` / `run_onchange_` /
`before_` / `after_` prefixes. Elevation is manual: the docs give a
self-elevating snippet and warn that chezmoi moves on as soon as the
non-elevated script returns, so use `Start-Process -Wait`. What chezmoi does
when it meets a `.sh` script with no interpreter is **unverified** — do not rely
on it failing gracefully.

**Line endings.** chezmoi has no global line-ending setting. The only control
is the per-template directive `chezmoi:template:line-endings=crlf|lf|native`.
Everything else is whatever git checked out, which makes section 6's
`.gitattributes` the real control.

<https://www.chezmoi.io/user-guide/machines/windows/> ·
<https://www.chezmoi.io/reference/special-files/chezmoiignore/> ·
<https://www.chezmoi.io/reference/special-files/chezmoiroot/> ·
<https://www.chezmoi.io/reference/configuration-file/interpreters/> ·
<https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/> ·
<https://www.chezmoi.io/reference/source-state-attributes/> ·
<https://www.chezmoi.io/user-guide/frequently-asked-questions/design/> ·
<https://www.chezmoi.io/reference/configuration-file/variables/> ·
<https://www.chezmoi.io/reference/configuration-file/> ·
<https://www.chezmoi.io/reference/templates/directives/> ·
<https://learn.microsoft.com/en-us/windows/advanced-settings/developer-mode>

## 3. WSL2 as host for the CLI layer

**Official Arch image: verified.** Arch Linux publishes its own WSL image
(`archlinux/archlinux-wsl` on the Arch GitLab), built monthly, signed with
Sigstore, reproducible, "including `systemd` support". Install with
`wsl --install archlinux`; it is listed in Microsoft's own distribution manifest
next to Ubuntu, Debian and Fedora. "Note that WSL 1 is **not** supported."
<https://gitlab.archlinux.org/archlinux/archlinux-wsl> ·
<https://github.com/microsoft/WSL/blob/master/distributions/DistributionInfo.json>

**Runs unchanged inside the distro.** fish, zellij, starship and the CLI tools,
mise, ghq, gopass + GnuPG, direnv, and `chezmoi apply` of the existing Linux
targets — it is the same Arch userland and the same package lists. chezmoi sees
`.chezmoi.os == "linux"`, so nothing has to be templated for the CLI layer; only
the desktop targets want a WSL guard. Claude Code is installed inside the distro
with the Linux installer, and WSL2 is the only Windows setup where its sandbox
works. rtk "behaves exactly like Linux" there.

**What breaks or needs care.**

- systemd is opt-in per distro (`[boot] systemd=true` in `/etc/wsl.conf`, WSL
  0.67.6+), on by default in the Arch image. But "systemd services will NOT keep
  your WSL instance alive", so user units are not a place for long-lived daemons.
  The darkman unit, greetd, zram, firewalld have nothing to act on.
- The Wayland desktop does not exist. WSLg runs individual X11/Wayland apps but
  "does not provide a full desktop experience"; niri, Noctalia, fuzzel,
  layer-shell tools and portals are out.
- gopass needs a pinentry that works in a terminal (`pinentry-curses` /
  `pinentry-tty`); the graphical one in the current `gpg-agent.conf` has no
  display to rely on.
- WSL appends the Windows `Path` by default (`appendWindowsPath`), so Windows
  `mise`, `git` or `node` can shadow the Linux ones. mise's own advice is to
  install Linux mise in WSL and set `appendWindowsPath = false`.
- A GUI terminal still has to come from Windows (Windows Terminal).

**Where to keep repos.** Microsoft: "store your files in the WSL file system if
you are working in a Linux command line", for example `/home/<user>/Project`,
"Not the Windows file system root directory". Cross-OS file access is the one
area where WSL 2 is slower than WSL 1. Files under `/mnt/c` also get synthetic
permissions unless the drive is mounted with `metadata` (off by default), and
NTFS is case-insensitive per directory. So `ghqRoot` stays inside the distro;
Windows editors reach it through VS Code Remote-WSL, Zed's WSL support, or
`\\wsl$\<distro>\…`.
<https://learn.microsoft.com/en-us/windows/wsl/filesystems> ·
<https://learn.microsoft.com/en-us/windows/wsl/compare-versions> ·
<https://learn.microsoft.com/en-us/windows/wsl/file-permissions> ·
<https://learn.microsoft.com/en-us/windows/wsl/case-sensitivity> ·
<https://learn.microsoft.com/en-us/windows/wsl/wsl-config> ·
<https://learn.microsoft.com/en-us/windows/wsl/systemd> ·
<https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps>

**Enterprise controls — what to ask IT.** WSL is manageable through Intune's
settings catalog ("Windows Subsystem for Linux") and an ADMX file. The settings
that matter here:

| Setting                                                                                                                      | Effect when disabled                                                              |
| ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Allow the Windows Subsystem For Linux                                                                                        | "disables access to the Windows Subsystem For Linux for all users on the machine" |
| Allow the Inbox version of the Windows Subsystem For Linux                                                                   | Only the Store version of WSL can be used                                         |
| Allow WSL1                                                                                                                   | Only WSL2 distributions can be used                                               |
| Allow passthrough disk mount                                                                                                 | Disables `wsl.exe --mount`                                                        |
| Allow the debug shell                                                                                                        | Disables `wsl.exe --debug-shell`                                                  |
| Allow custom kernel / kernel command line / system distro / networking / firewall / nested virtualization / kernel debugging | Locks the matching `.wslconfig` keys to their defaults                            |

Microsoft's enterprise guide also covers a Defender for Endpoint plug-in that
monitors inside distributions, Windows firewall rules applying to WSL (Windows
11 22H2 + WSL 2.0.9), and `networkingMode=mirrored`, `dnsTunneling=true`,
`autoProxy=true` for VPN and proxy environments — the settings to try first if
GlobalProtect breaks networking inside WSL. It lists "Controlling which
distributions users in your Enterprise can access" and "Controlling root access
for users" as currently unsupported, so a WSL policy tends to be all-or-nothing.
`wsl --install` itself needs an administrator PowerShell and a reboot. WSL 3.0.3
(2026-10-09) is the latest release.
<https://learn.microsoft.com/en-us/windows/wsl/intune> ·
<https://learn.microsoft.com/en-us/windows/wsl/enterprise> ·
<https://learn.microsoft.com/en-us/windows/wsl/install>

## 4. Package management: winget vs scoop

|                        | winget (v1.29.380, 2026-09-21)                                                                                                                                                                                                                                                                                                                          | scoop (v0.6.0, 2026-09-30)                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Availability           | Part of App Installer, delivered by the Microsoft Store on Windows 10 1809+ / 11. Not available until the first user sign-in has registered it.                                                                                                                                                                                                         | One PowerShell line from `get.scoop.sh`; needs PowerShell 5.1+ and `RemoteSigned` for the current user.                                                                                    |
| Admin rights           | Depends on each package's installer: "some applications may require elevation to install… If you choose not to elevate, the application will fail to install." `--scope user` exists but is per-package.                                                                                                                                                | "Run this command from a **non-admin** PowerShell". Installs under `~\scoop`, "Eliminates UAC prompt notifications". Only `--global` installs and the `nonportable` bucket want elevation. |
| Org controls           | Group Policy templates (`DesktopAppInstallerPolicies.zip`) can restrict sources, local manifests and the CLI; `winget configure` has its own kill-switch policy.                                                                                                                                                                                        | None of its own; blocked only by execution policy, AppLocker/WDAC or network rules (**unverified** which apply).                                                                           |
| Export format          | `winget export -o file.json [--include-versions]` — JSON with `Sources` → `Packages` → `PackageIdentifier` / optional `Version`. Tries to export every installed app; unmatched apps only produce a warning.                                                                                                                                            | `scoop export > scoopfile.json` — JSON with `buckets` and `apps`; `-c` adds config.                                                                                                        |
| Import                 | `winget import -i file.json [--ignore-unavailable] [--ignore-versions]`, installs serially.                                                                                                                                                                                                                                                             | `scoop import <path-or-url>` — adds buckets, then apps.                                                                                                                                    |
| Declarative            | `winget configure -f x.winget` — YAML + PowerShell DSC, `configurationVersion: 0.2.0`, resources such as `Microsoft.WinGet.DSC/WinGetPackage`. Needs winget v1.6.2631+. `winget configure export --all` generates one. "The most common reason for a WinGet Configuration to fail is due to a PowerShell DSC resource requiring administrative access". | —                                                                                                                                                                                          |
| Coverage of this setup | GUI apps and most CLIs. Not found: gopass, ouch, curlie, turbo, Maple Mono, Gemini CLI.                                                                                                                                                                                                                                                                 | Every CLI checked except turbo; GUI apps via `extras`; fonts via `nerd-fonts`. Not found: pgAdmin, UniKey.                                                                                 |

**For a tracked list in `packages/`.** Both exports are JSON, and both dump the
whole machine, so neither is a drop-in for the hand-curated
`pacman-explicit.txt`. A hand-maintained `packages/winget.json` (ids only, no
versions) plus `packages/scoopfile.json` matches the existing two-file
pacman/AUR split and both import with one command. `winget configure` is the
more expressive format but the least likely to survive a managed machine. Which
one to lean on is decided by the admin-rights answer: with no elevation at all,
scoop is the only one that installs everything it lists.
<https://learn.microsoft.com/en-us/windows/package-manager/winget/> ·
<https://learn.microsoft.com/en-us/windows/package-manager/winget/export> ·
<https://learn.microsoft.com/en-us/windows/package-manager/winget/import> ·
<https://learn.microsoft.com/en-us/windows/package-manager/winget/configure> ·
<https://learn.microsoft.com/en-us/windows/package-manager/configuration/> ·
<https://learn.microsoft.com/en-us/windows/package-manager/configuration/create> ·
<https://learn.microsoft.com/en-us/windows/package-manager/> ·
<https://github.com/ScoopInstaller/Scoop#readme> ·
<https://github.com/ScoopInstaller/Install#readme> ·
<https://github.com/ScoopInstaller/Scoop/blob/master/libexec/scoop-export.ps1> ·
<https://github.com/ScoopInstaller/Scoop/blob/master/libexec/scoop-import.ps1>

## 5. Dual-boot data hand-off

### Linux → the Windows NTFS partition

**Three drivers exist now.** `ntfs-3g` (FUSE, installed here as
`ntfs-3g 2026.9.28`), the in-kernel `ntfs3`, and a newer in-kernel `ntfs`
driver ("full read and write support… modern kernel infrastructure (iomap,
folio)"). This machine's kernel config has both `CONFIG_NTFS3_FS=m` and
`CONFIG_NTFS_FS=m`. For a one-off copy, ntfs-3g has the most explicit safety
behaviour and is the one `mount -t ntfs` resolves to here (`/usr/bin/mount.ntfs`
belongs to the ntfs-3g package).

**The Fast Startup hazard.** A Windows "fast startup simply loads the
hibernation file (Hiberfil.sys) into memory" — a normal Shut Down is a partial
hibernate, and the NTFS volume is left in a state Windows will resume from.
ntfs-3g's man page: "Windows has to be fully shut down before booting into
Linux, otherwise the NTFS file systems on internal disks may be left in an
inconsistent state and changes made by Linux may be ignored by Windows." How
each driver reacts is the detection:

- ntfs-3g: "If either Windows is hibernated or its fast restart is enabled,
  partitions on internal disks are forced to be mounted in read-only mode." A
  read-only mount where read-write was asked for **is** the signal. Do not use
  `remove_hiberfile`.
- ntfs3: refuses a volume marked dirty unless given `force`, which "Forces the
  driver to mount partitions even if volume is marked dirty. Not recommended for
  use." Never pass `force`.
- The fix is on the Windows side: `powercfg /h off` as Administrator ("disables
  both hibernation and fast restarting"), or reach Linux through Restart rather
  than Shut Down. Whether a restricted account may run `powercfg` is an open
  question below.

**BitLocker.** libblkid has a BitLocker probe, so `lsblk -f` shows `BitLocker`
as the filesystem type for an encrypted volume instead of `ntfs`. Checked on
this machine on 2026-10-12: the internal NTFS partitions report `ntfs`, so the
Windows volume is **not** BitLocker-encrypted as seen from Linux today. That can
change the moment IT enrols the machine — re-check before every mount. If it
does become encrypted, `cryptsetup open --type bitlk <device> <name>` opens it
(cryptsetup 2.8.8 is installed) and `dislocker` is the FUSE alternative (not
installed); both need the recovery key or password, which a managed machine may
not hand out, and a TPM-only protector cannot be used from Linux at all
(**unverified** — check the cryptsetup man page against the actual protector).
Writing to a corporate BitLocker volume from another OS is also the kind of
thing a security policy forbids outright; ask first.

**What NTFS loses.**

- Ownership and modes. ntfs-3g by default gives "everybody… full read, write,
  execution and directory browsing permissions"; real POSIX ownership needs the
  `permissions` option or a user-mapping file. Private keys copied this way
  arrive world-readable, and every file arrives executable.
- Names. Linux accepts names Windows cannot open (`:`, `?`, trailing dot, `CON`,
  `NUL`…). Mount with `windows_names` so such files fail loudly at copy time
  instead of silently existing.
- Case. Windows treats the tree case-insensitively; two files differing only in
  case collide on the Windows side.
- Symlinks. What ntfs-3g and ntfs3 write is not guaranteed to be what Windows
  or Git for Windows reads back (the new `ntfs` driver even has a
  `symlink=wsl|native` option for exactly this). **Unverified** per driver —
  assume symlinks do not survive.

**So do not copy git working trees.** A copied repo carries an index full of
Linux stat data, modes of `100755` on everything (or `core.fileMode` confusion —
git's own docs name "visiting a Cygwin created repository with Git for Windows"
as the case that needs `core.fileMode=false`), LF files that `core.autocrlf` may
rewrite, broken symlinks, and a different owner, which trips git's
`safe.directory` ownership check. Two safe routes:

1. **Push, then re-clone on Windows.** Before leaving Linux:
   `ghq list -p | xargs -I{} git -C {} status -sb` and `git stash list` /
   `git branch -vv` to find unpushed work. Anything not on a remote goes into a
   `git bundle create repo.bundle --all`.
2. **One tar per tree** for things that are not on a remote. A tarball is a
   single opaque file on NTFS, so modes, symlinks and case survive until it is
   extracted — inside WSL if that is allowed, or with Git Bash's `tar` otherwise.

### Windows → the ext4 partition

There is no first-party path on this machine. `wsl --mount` is Microsoft's only
ext4 reader, and its documented limitations rule it out: "only entire disks can
be attached to WSL 2… it's not possible to use `wsl --mount` to read a partition
on the boot device, because that device can't be detached from Windows", and
"You can't mount the Windows installation disk." Linux and Windows share one
NVMe here. It also needs administrator access and can be disabled by the "Allow
passthrough disk mount" policy. Third-party ext4 drivers for Windows exist but
were not evaluated and would be unsigned kernel drivers on a managed machine.

Consequence: **everything must be pushed out from Linux before Linux access is
lost** — to git remotes, to the NTFS partition, or to the second internal disk
(`sda`, already NTFS). Budget for this; there is no "I'll grab it later from
Windows".
<https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk>

### Carrying keys and the password store

- **SSH keys.** Simplest and safest: do not move them. Generate new keys on
  Windows with `ssh-keygen`, add the new public keys to GitHub and the work git
  host (both as authentication and as signing keys), update
  `~/.ssh/allowed_signers`. Old commits stay verifiable as long as the old
  public key stays in `allowed_signers`. This also fits Microsoft's advice to
  keep the private key in the agent's Windows security context.
- **GPG key + gopass store.** These have to move, since the store is encrypted
  to the key. Export with `gpg --export-secret-keys --armor <id>` and
  `gpg --export-ownertrust`, and take the store as a git clone or a tarball.
  Put them in an **encrypted** container before they touch NTFS — a
  `gpg --symmetric` (or `age -p`) tarball with a passphrase that exists only in
  your head — because the NTFS copy is world-readable (above) and an
  unencrypted Windows volume is readable by anything that boots the machine.
  On Windows: decrypt, `gpg --import`, `gpg --import-ownertrust`,
  `gopass clone` or point gopass at the store, then delete the container and
  empty the Recycle Bin. If the store's git remote is reachable from Windows,
  only the key needs the container.
- Whatever route: verify on Windows (`gopass ls`, decrypt one secret, sign one
  commit) **before** the Linux partition is wiped.

<https://github.com/tuxera/ntfs-3g/blob/edge/src/ntfs-3g.8.in> ·
<https://docs.kernel.org/filesystems/ntfs3.html> ·
<https://docs.kernel.org/filesystems/ntfs.html> ·
<https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/distinguishing-fast-startup-from-wake-from-hibernation> ·
<https://github.com/util-linux/util-linux/blob/master/libblkid/src/superblocks/bitlocker.c> ·
<https://gitlab.com/cryptsetup/cryptsetup/-/blob/main/man/cryptsetup-open.8.adoc> ·
<https://github.com/Aorimn/dislocker#readme> ·
<https://git-scm.com/docs/git-config#Documentation/git-config.txt-corefileMode>

## 6. Git on Windows, for a config shared with Linux

- **Line endings: use `.gitattributes`, not `core.autocrlf`.** `core.autocrlf =
  true` "is the same as setting the `text` attribute to 'auto' on all files and
  core.eol to 'crlf'" — a per-machine setting that the Git for Windows installer
  offers to turn on. Without attributes, the checkout default is "`eol=crlf` on
  Windows and `eol=lf` on all other platforms". **This repo has no
  `.gitattributes`**, so a Windows checkout can produce CRLF shell, fish and KDL
  files, which chezmoi would then apply verbatim. A root `.gitattributes` with
  `* text=auto eol=lf` (and `*.ps1 text eol=crlf` if PowerShell scripts are
  added) pins it for every clone regardless of local config.
- **`core.ignorecase = false` in `home/dot_config/git/config.tmpl` must not
  reach Windows.** Git calls it an "Internal variable" for case-insensitive
  filesystems such as NTFS, set automatically at clone/init time. Forcing it
  false globally on NTFS is the hazard; template it out for
  `.chezmoi.os == "windows"`.
- **`core.longpaths`.** A Git for Windows-only setting: "Enable long path
  (> 260) support for builtin commands in Git for Windows. This is disabled by
  default, as long paths are not supported by Windows Explorer, cmd.exe and the
  Git for Windows tool chain". Turn it on for deep `node_modules` trees; expect
  other tools to still choke.
- **`core.symlinks` + Developer Mode.** Git for Windows release notes: "when
  Developer Mode is turned off, special permissions are required when cloning
  repositories with symbolic links, therefore support for symbolic links is
  disabled by default." With it false, "symbolic links are checked out as small
  plain files that contain the link text". Enable Developer Mode first (admin,
  may be policy-blocked), then clone with `-c core.symlinks=true`. Note the
  2026 advisory CVE-2026-32631 about symlinks pointing at network drives.
- **Executable bit.** NTFS has none; git probes at clone time and sets
  `core.fileMode = false`. Mode changes made on Windows are therefore not
  recorded — set them with `git update-index --chmod=+x <file>` or from Linux.
  chezmoi's `executable_` prefix is unaffected, because it lives in the file
  name.
- **`includeIf "gitdir:"`.** The pattern is a glob; `~/` expands to `HOME`, a
  trailing `/` means `/**`, and a pattern that starts with none of `~/`, `./`,
  `/` gets `**/` prepended. `gitdir/i` matches case-insensitively and is the
  right form on Windows. This repo's
  `[includeIf "gitdir:{{ .ghqCompanyRoot }}/"]` keeps working if the chezmoi
  answer is written as `~/workspace/company`. How an absolute drive-letter path
  must be spelled (`C:/…` with forward slashes) is **unverified** in git's own
  docs — prefer the `~/` form and confirm with
  `git config --show-origin --get user.email` inside a work repo.
- **`core.sshCommand` and the two OpenSSH installs.** Git for Windows bundles
  its own OpenSSH (10.6p1 in v2.56.0.windows.2, 2026-10-05) and its installer
  has a "Use external OpenSSH" option; a 2026 installer bug silently flipped
  that choice back to bundled for some users. The bundled `ssh` does not talk
  to the Windows `ssh-agent` service, so a key added with Windows `ssh-add` is
  invisible to it. Pick one stack and make all three agree:
  `core.sshCommand = C:/Windows/System32/OpenSSH/ssh.exe`,
  `gpg.ssh.program = C:/Windows/System32/OpenSSH/ssh-keygen.exe`, and the
  Windows `ssh-agent` service — or stay entirely inside Git Bash's own agent.
  The exact System32 path is the conventional location and is **unverified**
  here; `where.exe ssh` settles it. Both keys belong in a Windows-only branch of
  the git config template.

<https://git-scm.com/docs/gitattributes> · <https://git-scm.com/docs/git-config> ·
<https://github.com/git-for-windows/git/blob/main/Documentation/config/core.adoc> ·
<https://github.com/git-for-windows/build-extra/blob/main/ReleaseNotes.md> ·
<https://gitforwindows.org/symbolic-links>

## Open questions — must be checked on the Windows side

None of these can be answered from Linux.

- [ ] **Admin rights.** Is the account a local administrator, a standard user
      with on-demand elevation, or neither? Decides winget vs scoop, Developer
      Mode, the `ssh-agent` service, `powercfg /h off`, `wsl --install`.
- [ ] **WSL policy.** `wsl --status` and `wsl --version`. Is "Allow the Windows
      Subsystem For Linux" disabled? Is `wsl --install archlinux` permitted, or
      only an approved image? Is the Defender for Endpoint WSL plug-in present?
- [ ] **Virtualisation.** If WSL2 is blocked, is Hyper-V available (edition,
      policy, Hyper-V Administrators membership) for containers?
- [ ] **BitLocker.** `manage-bde -status C:`. Is the volume encrypted, will
      enrolment encrypt it, and does policy forbid mounting it from another OS?
      Re-run `lsblk -f` on Linux before each mount.
- [ ] **Fast Startup.** `powercfg /a` — is hibernation available, and may it be
      turned off?
- [ ] **Deadline.** When does Linux have to go? Everything on ext4 must be
      pushed out before then; there is no way back in from Windows.
- [ ] **winget.** Does `winget --version` work, are the default sources
      reachable through the proxy / SSL inspection, is the Microsoft Store
      blocked?
- [ ] **scoop.** Is `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
      allowed (`Get-ExecutionPolicy -List`)? Are `get.scoop.sh` and GitHub
      release downloads reachable? Does AppLocker / WDAC block unsigned
      executables in the user profile?
- [ ] **Developer Mode.** Can it be enabled? Needed for `core.symlinks` and
      chezmoi's one `symlink_` target.
- [ ] **OpenSSH.** `Get-WindowsCapability -Online | Where-Object Name -like
      'OpenSSH*'`, `Get-Service ssh-agent`, `where.exe ssh`.
- [ ] **PowerShell.** Is PowerShell 7 installable? What does `$PROFILE` resolve
      to — is `Documents` redirected to OneDrive?
- [ ] **Git for Windows.** Installed or installable? Claude Code hooks, `just`
      recipes and direnv all want its bash. Which options did the installer set
      (`git config --system --list`: `core.autocrlf`, `core.symlinks`,
      `core.sshCommand`, credential helper)?
- [ ] **GnuPG.** `where gpg`, `gpg --version` (home directory line), and whether
      Gpg4win may be installed.
- [ ] **Tiling WM.** Is a third-party window manager allowed at all? If
      komorebi is wanted for the scrolling layout, who pays for the Individual
      Commercial Use License?
- [ ] **Approved software.** Is there an allow-list? Claude Code, rtk and Gemini
      CLI on a managed machine are a policy question before they are a technical
      one; Claude Code also supports organisation-managed settings that may
      already be deployed.
- [ ] **VPN.** Does IT deploy GlobalProtect, and does WSL networking need
      `networkingMode=mirrored` / `dnsTunneling` behind it?
- [ ] **Docker Desktop.** Does the company hold a subscription, or is Podman /
      Rancher Desktop the expected route?
- [ ] **Unverified in this note**, to confirm on first install: default config
      directories on Windows for zellij, bat, eza, superfile, btop4win, fastfetch
      and mise; how chezmoi treats a `.sh` script with no interpreter; the winget
      id for Windows Auto Dark Mode; the drive-letter form for `includeIf`.

### Sources

Cited inline next to each claim. Release versions and dates come from each
project's GitHub release feed (`https://github.com/<owner>/<repo>/releases`),
read on 2026-10-12; package ids from
<https://github.com/microsoft/winget-pkgs/tree/master/manifests>,
<https://github.com/ScoopInstaller/Main/tree/master/bucket>,
<https://github.com/ScoopInstaller/Extras/tree/master/bucket> and
<https://github.com/matthewjberger/scoop-nerd-fonts/tree/master/bucket>.
