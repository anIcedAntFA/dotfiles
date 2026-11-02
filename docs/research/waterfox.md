# Waterfox on EndeavourOS + niri: what it is and how to run it

Research note — investigated 2026-10-28. Question: is Waterfox (current stable,
**6.7.7**) a good replacement for Zen Browser on EndeavourOS (Arch) + niri +
Noctalia + fish, and how do we configure it declaratively in this dotfiles repo?

How this was researched, because it shapes how much to trust each fact:

- **Primary-source "ground truth" for 6.7.7.** The upstream repo
  (<https://github.com/BrowserWorks/waterfox>, `current` branch, HEAD
  `4772b33` = the exact SourceStamp of the 6.7.7 build) was cloned
  (blobless, `--depth 1`) and the official Linux tarball
  (<https://cdn.waterfox.com/waterfox/releases/6.7.7/Linux_x86_64/waterfox-6.7.7.tar.bz2>)
  was downloaded and unpacked in a scratch dir. Facts tagged "source" or
  "tarball" below were read from those, not from blog summaries.
- **Not run.** This machine is a WSL2 guest without the GTK/X11 shared libs, so
  the browser was never launched. Anything that needs a running Waterfox on
  niri (actual `app_id` reported, `-P` behaviour, VA-API on your GPU) is
  marked **UNVERIFIED (runtime)** and has a one-line check.
- `support.mozilla.org` and `aur.archlinux.org` HTML pages block bots (JS/Anubis
  challenge). AUR data came from the official AUR RPC/cgit endpoints, Arch Wiki
  from its raw-wikitext endpoint. SUMO-only facts are marked accordingly.
- Marker legend: **VERIFIED** (source URL or file named), **UNVERIFIED**
  (could not confirm; also collected in the list at the end).

## TL;DR

| Decision point                   | Finding                                                                                                                                                                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Version / base                   | Waterfox **6.7.7** (2026-10-27), Gecko **153.6.0** ("ESR 153"), MPL-2.0, BrowserWorks Ltd (Alex Kontos).                                                                                                                 |
| Arch package                     | **`waterfox-bin`** (AUR, 62 votes, tracks the official tarball, installs to `/opt/waterfox`). Flatpak `net.waterfox.waterfox` also exists.                                                                               |
| Wayland `app_id`                 | **`waterfox`** (official `.desktop` has `StartupWMClass=waterfox`; tarball/source `RemotingName=waterfox`). The AUR `waterfox-bin` `.desktop` says `waterfox-default` and `Exec=waterfox-g` — stale; do not match on it. |
| Native Wayland                   | On by default when `WAYLAND_DISPLAY` is set and GTK >= 3.24.30; `MOZ_ENABLE_WAYLAND=1` makes it explicit (source).                                                                                                       |
| Native vertical tabs             | **Yes**, plus native **tree tabs** (6.7.0+), tab groups, split view. Off by default for existing profiles; first-run setup offers it.                                                                                    |
| `policies.json`                  | **Honoured.** Read from `/etc/waterfox/policies/policies.json` first, else `<install-dir>/distribution/policies.json` (source). First file found wins, no merge.                                                         |
| userChrome.css                   | Works out of the box: `toolkit.legacyUserProfileCustomizations.stylesheets` is `true` **and locked** (source).                                                                                                           |
| Profile dir (Linux)              | **`~/.waterfox/`** (not `~/.mozilla`, not XDG `~/.config`) (source).                                                                                                                                                     |
| Zen profile reuse                | **Do not reuse.** Zen 1.23.4b is on Firefox **158.0.1**; Waterfox is Gecko **153.6**. Waterfox builds with downgrade blocking **off** (no refusal, but no safety net). Import data selectively or via Sync.              |
| Telemetry / Mozilla services     | Telemetry, Normandy, Nimbus, Safe Browsing, sponsored content, Pocket-style recs all off/locked in the shipped prefs; Firefox Sync still available (Mozilla token server).                                               |
| Chrome Web Store extensions      | **Removed in 6.7.0.** Firefox WebExtensions + legacy XUL add-ons are supported.                                                                                                                                          |
| Hard performance numbers vs. Zen | **None found** from a primary source. Measurement recipe provided instead.                                                                                                                                               |

## 1. What Waterfox is today

- **Current stable:** 6.7.7, released 2026-10-27.
  <https://www.waterfox.com/releases/> (index of 51 desktop releases) and
  <https://www.waterfox.com/releases/6.7.7/>.
- **Engine base:** "Waterfox 6.7 upgrades from Gecko ESR 140 to Gecko ESR 153";
  6.7.0 stable was 2026-08-19, codename "Supernova".
  <https://www.waterfox.com/releases/6.7.0/>. The tarball confirms
  `Version=153.6.0`, `Milestone=153.6.0`, `BuildID=20261027085606`
  (`application.ini`, `platform.ini` in the tarball). Point releases carry
  Mozilla security advisories (6.7.7 notes cite MFSA 2026-120). The site says it
  "follows the Firefox ESR model".
  <https://www.waterfox.com/>
- **Maintainer:** BrowserWorks Ltd, "a holding company wholly owned by Alex"
  (Alex Kontos, who founded Waterfox in 2011 and returned it to independent
  ownership in 2023). <https://www.waterfox.com/> and <https://browser.works>.
  Source: <https://github.com/BrowserWorks/waterfox> (collaborator-only PRs).
- **License:** MPL-2.0 (site; AUR `license=('MPL-2.0')`; Flathub entry
  `MPL-2.0`).
- **History / naming:** "Classic" (2019-2022, legacy-extension fork, AUR
  `waterfox-classic-bin`, last version 2022.11) was succeeded by the "Current" /
  G-series on a modern Gecko base; the AUR still lists `waterfox-bin` with
  keywords `waterfox-g6`. The release index shows continuous 6.5.x -> 6.6.x ->
  6.7.x desktop releases (Sep 2024 -> Oct 2026).
  <https://www.waterfox.com/releases/>. The Classic/G history narrative itself
  comes from general knowledge and the AUR names, not from a fetched Waterfox
  history page (**UNVERIFIED** as prose).
- **Privacy stance (shipped defaults, from `waterfox/browser/app/profile/*.js`
  in the repo and the tarball's `browser/omni.ja` `defaults/preferences/`):**
  - Site claim: "no telemetry and no data collection"; funded by search
    partnerships, optional Waterfox Private Search subscriptions, donations.
    <https://www.waterfox.com/>
  - Telemetry prefs (`toolkit.telemetry.*`, `datareporting.*`) set **locked
    false**; crash reporter build-disabled (`AppConstants.MOZ_CRASHREPORTER:
    false`, `MOZ_DATA_REPORTING: false` in the tarball).
  - **Normandy removed from the build** (`MOZ_NORMANDY: false`;
    `imply_option("MOZ_NORMANDY", False)` in `browser/moz.configure`), studies
    prefs locked off, **Nimbus rollouts/labs disabled**
    (`02-privacy.js`; also the 6.7.0 notes).
  - **Safe Browsing fully disabled** (no Google endpoints), no Mozilla/Google
    geolocation service URL, captive-portal and connectivity checks off.
  - Sponsored/promo surfaces off and locked: top stories, sponsored tiles,
    quick suggest, VPN/Relay/Monitor promos, "More from Mozilla"
    (`01-services.js`, `03-features.js`).
  - **Pocket:** story/highlights-from-Pocket prefs locked off
    (`section.highlights.includePocket`, `topstories`); Mozilla's own policy
    list marks `DisablePocket` as deprecated.
  - **AI:** `browser.ml.*` chat/menu/sidebar/shortcuts/link-preview all off;
    smart tab grouping off until opt-in (`03-features.js`; 6.7.0 notes: "AI
    features from the Firefox 153 platform ... are disabled by default"). AI
    answers in supported search engines hidden by default (6.7.4 notes).
  - **DNS:** "Ultra Protection" = DNS over Oblivious HTTP via a Waterfox relay
    (`dooh.waterfox.com`) to Cloudflare, `network.trr.mode = 2`, on by default
    for new profiles (`04-dns.js`, 6.7.0 notes).
  - **Built-in ad/tracker blocker** (adblock-rust 0.13.2, uBO-style lists
    bundled): `waterfox.blocker.enabled = true`. It warns when an ad-blocker
    extension is installed unless `waterfox.blocker.coexist = true`
    (`02-privacy.js`, `blocker/` component).
  - Global Privacy Control on, referrer trimming, 0-RTT off, OCSP off
    (`02-privacy.js`).
  - **DRM off by default**; opt-in prompt downloads Widevine (6.7.1.1 notes,
    `media.eme.enabled=false` in `02-privacy.js`).
- **Search defaults:** engine list 1.org (removed in 6.7.4), Bing, DuckDuckGo,
  Ecosia, Google, Mojeek, Qwant, Waterfox Private Search. Default is **Qwant in
  supported regions, DuckDuckGo elsewhere** (Qwant fallback if region unknown);
  user-chosen engines are left alone. <https://www.waterfox.com/releases/6.7.0/>
  (as of 6.7.0; 6.6.16 first made Qwant default:
  <https://www.waterfox.com/releases/6.6.16/>). Search-suggestion requests are
  proxied by default (`waterfox.search.suggestions.useProxy`, toggle added in
  6.7.4).

## 2. Architecture and structure

- **Engine:** Gecko (Firefox ESR 153 platform) with a Waterfox layer under
  `waterfox/` in a Mozilla-central-shaped tree: README says it contains
  "Mozilla platform code, Waterfox product code, branding, features, packaging,
  and release files" and builds with `./mach`.
  <https://github.com/BrowserWorks/waterfox>. The 6.7.0 notes say the
  Waterfox layer was rebuilt to run natively on the new Gecko base rather than
  patched on top (<https://www.waterfox.com/releases/6.7.0/>).
- **What the Waterfox layer adds (source tree `waterfox/browser/components/`):**
  `blocker` (ad blocker), `tabbrowser` (tree tabs), `statusbar`, `feeds`
  (RSS/Live Bookmarks restored, `about:feeds`), `privatetab`, `search`,
  `settings`, `theme`/`uicustomizations` (Nova/Proton/Photon styles, ~121
  appearance options), `aboutcfg`, `aboutpasswords`, `migration`, `onboarding`.
- **Build flags that matter (`waterfox/moz.configure`, `browser/moz.configure`,
  `waterfox/build/mozconfig-x86_64-pc-linux-gnu`):**
  `MOZ_APP_PROFILE=Waterfox`, `--with-distribution-id=net.waterfox`,
  `MOZ_DEDICATED_PROFILES=True`, **`MOZ_BLOCK_PROFILE_DOWNGRADE=False`**,
  `MOZ_NORMANDY=False`, `MOZ_SERVICES_SYNC=True`, `MOZ_SERVICES_HEALTHREPORT=False`,
  system policies enabled (default), x86-64-v2 baseline, PGO, `-O3`, Clang 23,
  `--without-onnx-runtime`. Update channel: `release` (tarball
  `AppConstants.MOZ_UPDATE_CHANNEL: "release"`, `channel-prefs.js`).
- **Profile layout (Linux): `~/.waterfox/`** with `profiles.ini` beside the
  profile dirs (source: `nsXREDirProvider.cpp` — when `gAppData->profile` is set
  the legacy dotted, lower-cased, `$HOME`-relative path is used and XDG is
  skipped; `Profile=Waterfox` in the tarball's `application.ini`).
  Legacy `~/.mozilla` is only considered via the `MOZ_LEGACY_HOME` logic.
  - 6.7.1.1 shipped a bug creating an **empty `~/Waterfox`** dir; fixed in
    **6.7.6**. <https://www.waterfox.com/releases/6.7.1.1/>,
    <https://www.waterfox.com/releases/6.7.6/>. Safe to delete if still present.
  - Native-messaging manifests: reads `~/.waterfox/native-messaging-hosts`,
    `/usr/lib/waterfox/...` **and** Firefox's `~/.mozilla/native-messaging-hosts`
    / `/usr/lib/mozilla/...` (xpcshell test
    `test_native_manifest_compat_dirs.js`; 6.7.0 notes "companion manifests are
    installed for Firefox on macOS and Linux, so password manager connectors work
    without reinstalling"). Tridactyl's native messenger and Bitwarden/gopass
    connectors should therefore be found without re-install (**UNVERIFIED
    (runtime)**).
- **Distribution formats:**
  - **Official tarball** (`bz2`, 128.8 MiB x64, 123.0 MiB aarch64; ~490 MB
    unpacked as measured: `libxul.so` 177 MB, `omni.ja` 140 MB,
    `browser/omni.ja` 149 MB). Requires glibc >= 2.17 and SSE4.2. Has the
    built-in updater (`aus.waterfox.com`). <https://www.waterfox.com/download/>
  - **Official DEB/RPM repos** on OBS (`isv:BrowserWorks`) for
    Debian/Ubuntu/Fedora/Mageia, x86_64 + ARM64 (not Arch). Packaged builds
    disable the in-app updater (`package-prefs.js`).
  - **Flatpak:** `net.waterfox.waterfox` on Flathub, developer "BrowserWorks",
    verified via website, ~12.5k installs last month, MPL-2.0 (Flathub API
    `flathub.org/api/v2/search`). Not mentioned on the waterfox.com download
    page. Flatpak means sandboxed `/app/etc` policy path and no host native
    messaging without extra permissions — a poor fit for gopass/Tridactyl.
  - **AUR** (data from `aur.archlinux.org/rpc/v5`, 2026-10-28):

| Package                          | Maintainer                    | Votes | Version   | What it is                                                                                                                                          |
| -------------------------------- | ----------------------------- | ----- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `waterfox-bin`                   | Exorcism (+AutoUpdateBot)     | 62    | 1:6.7.7-1 | Repacks the official tarball into `/opt/waterfox`; `provides=waterfox`, `conflicts=waterfox`; `/usr/bin/waterfox` and compat `waterfox-g` symlinks. |
| `waterfox`                       | xiota (Chaotic-AUR flavoured) | 24    | 6.7.7-1   | Builds from the GitHub tag: PGO, clang, system NSS/ffmpeg libs, installs to `/usr/lib/waterfox`; `-O2`, no VMP signing.                             |
| `waterfox-beta-bin`              | zoeyrae                       | 0     | 6.7.7-1   | Beta tarball repack.                                                                                                                                |
| `waterfox-classic-bin`           | vcekron                       | 92    | 2022.11   | Obsolete Classic fork. Do not use.                                                                                                                  |
| `waterfox-g-arkenfox-autoconfig` | SpacingBat3                   | 0     | 140.1-1   | arkenfox as autoconfig for the ESR 140 era; stale for Gecko 153.                                                                                    |

- **Best for Arch: `waterfox-bin`.** Reasons: official signed binaries
  (the OBS README states the tarball is "VMP-signed" and "any change to the
  binaries would break the Widevine signature"
  <https://github.com/BrowserWorks/waterfox> `waterfox/browser/installer/linux/obs/README.md`),
  tiny install step, tracks releases within hours (AUR `LastModified`
  2026-10-27 20:43 +07 vs release same day). The source `waterfox` package is
  a multi-hour PGO build, and whether Widevine works without VMP signing is
  **UNVERIFIED (inference only)**.
- **`waterfox-bin` packaging quirks (read from its PKGBUILD,
  `aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=waterfox-bin`):**
  - Installs `/opt/waterfox/distribution/policies.json` with
    `{"AppAutoUpdate": false, "ManualAppUpdateOnly": true}` and a
    `vendor.js` (`browser.shell.checkDefaultBrowser=false`,
    `app.update.auto=false`, `spellchecker.dictionary_path=/usr/share/hunspell`).
    Updates therefore come from pacman/AUR, not the app.
  - Its `waterfox.desktop` has **`Exec=waterfox-g %u`** and
    **`StartupWMClass=waterfox-default`**. The official OBS desktop file
    (`waterfox/browser/installer/linux/obs/waterfox.desktop`) and the source
    `waterfox` AUR package both use `Exec=waterfox` /
    `StartupWMClass=waterfox`. The string `waterfox-default` does not occur in
    the 6.7.7 `waterfox-bin` executable (checked with `strings`), so the AUR
    value looks stale. Override with your own `.desktop` (section 6).
  - `depends`: `gtk3 libxt startup-notification mime-types dbus-glib ffmpeg
    ttf-font hicolor-icon-theme`; optdepends include `libnotify`,
    `networkmanager`, `pulseaudio`/`alsa-lib`, `hunspell-en_US`.
    Not listed: `xdg-desktop-portal` (the source package lists it:
    "Screensharing with Wayland") — install it yourself.
- **Update mechanism on Linux:** tarball = built-in updater (checks
  `aus.waterfox.com`; 6.7.0 offers three modes: auto-download+install after
  restart / check and prompt / never check). Distro/AUR/OBS packages = package
  manager, with the in-app updater disabled.

## 3. Linux / Wayland specifics

- **Native Wayland (source, `toolkit/xre/nsAppRunner.cpp` `IsWaylandEnabled()`):**
  1. no `WAYLAND_DISPLAY` -> X11;
  2. `WAYLAND_DISPLAY` set and no `DISPLAY` -> Wayland;
  3. both set -> `MOZ_ENABLE_WAYLAND=1` forces Wayland, `=0` forces Xwayland;
  4. neither set and `GDK_BACKEND=wayland...` -> Wayland (with a warning);
  5. otherwise **Wayland iff GTK >= 3.24.30**.
     niri typically exports both `WAYLAND_DISPLAY` and `DISPLAY` (via
     xwayland-satellite), so case 5 applies and you get Wayland by default. Arch
     Wiki agrees for Firefox >= 121 and says to check `about:support` ->
     "Window Protocol" (`wayland` vs `xwayland`).
     <https://wiki.archlinux.org/title/Firefox> (section "Xwayland"). Widgets are
     **GTK3** (the check is `gtk_check_version(3, 24, 30)`).
- **App-id / WM_CLASS (critical for niri `window-rule`):**
  - `RemotingName=waterfox` (tarball `application.ini`; `strings waterfox-bin`
    shows `waterfox` embedded, no `-default`/`-release` suffix). Source:
    `MOZ_APP_REMOTINGNAME` defaults to `MOZ_APP_NAME` on the `release` channel
    (`toolkit/moz.configure`); `nsAppShell.cpp` calls
    `gdk_set_program_class(remotingName)` and `nsAppRunner.cpp` calls
    `g_set_prgname(remotingName)`.
  - X11: `WM_CLASS` res_class = `waterfox` (res_name derives from the window type,
    `Navigator`). Wayland: GTK3 uses program class/prgname -> **`app_id =
    waterfox`**. The Arch Wiki notes that on Wayland the `--name` option (not
    `--class`) controls the grouping attribute, and `--class` sets WM_CLASS on
    X11.
    <https://wiki.archlinux.org/title/Firefox> (section "Window manager rules").
  - **UNVERIFIED (runtime):** the literal `app_id` as seen by niri. Check with
    `niri msg windows | rg -i -A3 waterfox` (or `niri msg --json windows`). niri
    rule to use: `match app-id=r#"^waterfox$"#`.
  - `--class` / `--name` are GDK-handled flags; Waterfox's own `--help` text
    (source `nsAppRunner.cpp`) does not list them, but the code comment in
    `nsAppShell.cpp` references "override classname by --class command line
    option". Use `--name <x>` to give a second profile its own Wayland `app_id`.
- **Desktop file name:** official OBS package ships `waterfox.desktop`
  (`StartupWMClass=waterfox`, actions `new-window`, `new-private-window`,
  `open-profile-manager`; MimeTypes include `x-scheme-handler/http(s)` and
  `mailto`). AUR `waterfox-bin` ships `waterfox.desktop` with the stale values
  above.
- **Single instance / multiple profiles (source `nsAppRunner.cpp`):**
  - `-P <profile>`, `--profile <path>`, `--ProfileManager`, `--new-instance`,
    `--safe-mode`, `--migration`, `--headless`, `--allow-downgrade` is **not**
    listed (downgrade blocking compiled out).
  - `--no-remote` is **stripped and ignored** ("now unsupported");
    use `--new-instance` or `MOZ_NEW_INSTANCE=1`. Remote messaging service name
    `org.mozilla.waterfox` (D-Bus; string found in `libxul.so`).
  - `MOZ_DEDICATED_PROFILES=True` -> each install gets its own default profile
    entry (`installs.ini`). Launching `-P other` while an instance of the same
    install runs: behaviour **UNVERIFIED (runtime)**; Arch Wiki recipe is
    `firefox --new-instance -P <name>`.
    <https://wiki.archlinux.org/title/Firefox> (section "Profiles").
- **Hardware video decoding:** Gecko 153 prefs (source `StaticPrefList.yaml`):
  `media.hardware-video-decoding.enabled=true`, `...force-enabled=false`,
  `media.hardware-video-decoding-vulkan.enabled=false` (experimental),
  `widget.dmabuf.enabled=true`, `widget.wayland.opaque-region.enabled=true`,
  `widget.wayland.fractional-scale.enabled=true`. The tarball ships
  `vaapitest`, `glxtest`, `vulkantest` probe binaries. Arch Wiki: VA-API
  default-on for Intel (>=115) and AMD (>=136); for others set
  `media.hardware-video-decoding.force-enabled=true`; NVIDIA needs
  `libva-nvidia-driver`; fullscreen flicker -> `widget.wayland.opaque-region.enabled=false`;
  verify with `MOZ_LOG="FFmpegVideo:5"`.
  <https://wiki.archlinux.org/title/Firefox> (section "Hardware video
  acceleration"). `ffmpeg` is a hard dependency of `waterfox-bin`. Your GPU is
  not known here: **UNVERIFIED (runtime)**.
- **xdg-desktop-portal prefs (source comments in `StaticPrefList.yaml`):**
  - `widget.use-xdg-desktop-portal.settings = 2` (auto) -> reads
    `org.freedesktop.appearance` (the string is present in `libxul.so`), so
    dark/light follows the Settings portal (same mechanism this repo already
    verified for Discord: `docs/research/discord-wayland-theme-follow.md`).
  - `...file-picker = 2` and `...open-uri = 2` = auto = **false unless
    Flatpak or `GTK_USE_PORTAL=1`**; `...mime-handler = 2` auto (Flatpak
    only); `...native-messaging = 0`; `...location = 2`.
    To use the portal file picker on niri set `file-picker` to `1` (Arch Wiki
    says the same for Firefox).
  - **Screen sharing:** via PipeWire/xdg-desktop-portal (source AUR package lists
    `xdg-desktop-portal` as optdepends "Screensharing with Wayland" and depends on
    `libpipewire-0.3`). On niri the portal backend is
    `xdg-desktop-portal-gnome` (niri docs; **UNVERIFIED** here).
- **Passwords / Secret Service:** Waterfox inherits Firefox's own store:
  `logins.json` encrypted with NSS `key4.db` in the profile (inherited
  Firefox design; Waterfox adds an `about:passwords` page,
  `waterfox/browser/components/aboutpasswords`). `libsecret` appears in
  `libxul.so` (2 string hits), consistent with upstream's OSKeyStore used for
  autofill encryption, not for logins. A Secret Service/gopass backend therefore
  only enters through an extension + native messenger. **UNVERIFIED (runtime)**.

## 4. Features

| Feature                | Status in 6.7.7                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Vertical tabs          | **Native** (Firefox sidebar revamp: `sidebar.revamp=true`, `sidebar.verticalTabs`). Waterfox adds auto-hide (6.7.3, `sidebar.autoHide`), compact density fixes (6.7.6). `browser.tabs.toolbarposition=topabove` default for horizontal.                                                                                                                                                 |
| Tree tabs              | **Native since 6.7.0**, requires vertical tabs (`browser.tabs.verticalTabs.tree.enabled`, default false in prefs; set via first-run/Settings). Dropped vs old TST fork: large keyboard command set, custom CSS editor, API for extensions.                                                                                                                                              |
| Tab groups             | Native Firefox tab groups (`browser.tabs.groups.enabled=true`); Waterfox's auto-group-new-tabs off by default (was on in 6.6); smart (ML) grouping off.                                                                                                                                                                                                                                 |
| Split view             | `browser.tabs.splitView.enabled=true` in the shipped `firefox.js`.                                                                                                                                                                                                                                                                                                                      |
| Containers             | Native containers on (`privacy.userContext.enabled/ui.enabled=true`); marker style is a tab option (6.7.1.1). "Multi-Account Containers" the add-on is not bundled (AUR has a debranded `waterfox-multi-account-containers-lite`).                                                                                                                                                      |
| PWA / web apps         | **No Linux PWA support found.** `browser.taskbarTabs.enabled=false` in shipped prefs (platform guard not checked). UNVERIFIED.                                                                                                                                                                                                                                                          |
| userChrome/userContent | **Supported by default** (pref locked true). Waterfox also has its own switch "Load interface customisations" (`browser.theme.waterfox.chromeSheet`: 0 on, 2 off).                                                                                                                                                                                                                      |
| Extensions             | Firefox WebExtensions from AMO (AMO removed from `restrictedDomains`, so extensions work on addons.mozilla.org); **legacy XUL/bootstrap/overlay add-ons supported** again; unsigned install allowed (`xpinstall.signatures.required=false` locked). **Chrome Web Store / Opera install removed in 6.7.0.** MV2 and MV3 both loadable (Gecko supports both; Waterfox does not drop MV2). |
| Tracking protection    | Waterfox built-in blocker (own pane, filter lists, exceptions) **plus** Firefox ETP/fingerprinting prefs. Cookie-banner reject (`cookiebanners.service.mode=1`).                                                                                                                                                                                                                        |
| Sync                   | Mozilla Accounts / Firefox Sync **present** (`MOZ_SERVICES_SYNC`, `identity.fxaccounts.enabled=true`, token server `token.services.mozilla.com`; 6.7.0 notes show an "Account and Sync" pane). Not a Waterfox-run server.                                                                                                                                                               |
| Reader mode            | Standard Firefox; feed articles open in reader by default (6.7.5).                                                                                                                                                                                                                                                                                                                      |
| Translation            | Firefox on-device translation on (`browser.translations.enable=true`); 6.7.0: "Translation models download on demand".                                                                                                                                                                                                                                                                  |
| AI                     | Off by default (see section 1).                                                                                                                                                                                                                                                                                                                                                         |
| DRM / Widevine         | **Off by default**; opt-in in Settings or via first-EME-site prompt, then downloads Widevine. Needs the signed binary (use `waterfox-bin`).                                                                                                                                                                                                                                             |
| Waterfox-exclusive     | Native tree tabs, status bar (link target without overlay), private tabs beside normal tabs, Nova/Proton/Photon chrome styles + 12 palettes, RSS/Live Bookmarks, built-in blocker, Ultra Protection DNS, legacy add-on support.                                                                                                                                                         |

Sources: <https://www.waterfox.com/>, <https://www.waterfox.com/releases/6.7.0/>,
<https://www.waterfox.com/releases/6.7.1.1/>, repo `waterfox/browser/app/profile/*.js`,
tarball `browser/omni.ja` `defaults/preferences/firefox.js`. Mozilla docs for the
upstream features: vertical tabs
<https://support.mozilla.org/en-US/kb/use-sidebar-access-tools-and-vertical-tabs>,
tab groups <https://support.mozilla.org/en-US/kb/tab-groups> (groups are local
only and do not sync).

### Keyboard workflow

- **Native vim-like navigation: no.** Only upstream's caret browsing (F7) and
  quick find (`/`, `'`) — general Firefox behaviour, **UNVERIFIED** (SUMO blocked
  to bots; not re-checked).
- **Customising shortcuts:** Firefox has no built-in UI to remap its core
  shortcuts (**UNVERIFIED**: stated from general knowledge). Extensions can
  declare `commands` shortcuts and users remap those in `about:addons` ->
  gear -> "Manage Extension Shortcuts" (the feature exists in the tree:
  `browser_ext_commands_openShortcutSettings.js`). Modal/vim bindings therefore
  come from extensions: Vimium-C, Tridactyl (needs native messenger for `:source`
  / rc file), Surfingkeys. Waterfox allows them on AMO pages (AMO removed from
  `restrictedDomains`), and still cannot touch `about:` pages. Compatibility of
  each with Gecko 153 and MV3 status: **UNVERIFIED**.
- **Shortcuts that matter (documented):** Vertical-tab collapse/expand and sidebar
  toggle is **Ctrl+Alt+Z**
  (<https://support.mozilla.org/en-US/kb/use-sidebar-access-tools-and-vertical-tabs>).
  Waterfox tree-specific: with focus in the tab strip, **ArrowLeft collapses**
  and ArrowRight expands a tree parent (source test
  `browser_tree_tabs_keyboard.js`); the autoGroup cancel/bypass shortcuts are
  `Ctrl+\` and``Alt+Shift+T`(`browser.tabs.autoGroupNewTabs.*Shortcut`,`03-features.js`). Standard Firefox ones (Ctrl+L, Ctrl+T/W, Ctrl+Shift+T,
  Ctrl+Tab, Ctrl+K, Alt+1..9) are general knowledge, **UNVERIFIED** here.`browser.ctrlTab.sortByRecentlyUsed=false` is the shipped default.
- niri owns the compositor-level keys, so most conflicts are with `Super`
  binds, not with browser bindings.

## 5. Performance and weight

No primary-source benchmark of Waterfox 6.7 vs Zen / Firefox / Chrome exists that
I could find. A web search only returned low-trust material (labelled): a Medium
post "Brave vs. Floorp, Zen, LibreWolf & Waterfox" (qualitative, no numbers, says
Waterfox uses more memory because of legacy support), a ~9-year-old Dedoimedo test
(Waterfox ~420 MB, ~20% above Firefox; irrelevant to 6.x), and a Firefox/Chrome/Edge
M4 Mac test (Firefox 727 MB idle, 8,844 MB at 50 tabs; does not include Waterfox
or Zen). **Treat all of these as unreliable for this decision.**

What is verifiable:

- **Install size (measured on the 6.7.7 tarball):** 128.8 MiB download,
  **~490 MB unpacked** (`libxul.so` 177 MB, `omni.ja` 140 MB, `browser/omni.ja`
  149 MB; the extra `browser/omni.ja` carries the Waterfox UI layer). Zen and
  Firefox install sizes were not measured: **UNVERIFIED**.
- **Process model (`StaticPrefList.yaml`, `greprefs.js`):** e10s + Fission on
  (`fission.autostart=true`); `dom.ipc.processCount=8` (indented, likely
  conditional) plus `.webIsolated=4`, `.file=1`, `.extension=1`,
  `.privilegedabout=1`, `.inference=1`. Same family of defaults as upstream
  Firefox. Arch Wiki's tuning: set `dom.ipc.processCount` to 1-8 and
  `browser.preferences.defaultPerformanceSettings.enabled=false`.
  <https://wiki.archlinux.org/title/Firefox/Tweaks>.
- **Tab unloading:** `browser.tabs.unloadOnLowMemory` defaults to **`false` on
  Linux** (`true` only on macOS/Windows) and
  `browser.tabs.min_inactive_duration_before_unload=600000` (10 min)
  (source `browser/app/profile/firefox.js`). Arch Wiki's "unload tabs inactive
  for 1 hour" recipe: `unloadOnLowMemory=true`,
  `browser.low_commit_space_threshold_percent=100`,
  `min_inactive_duration_before_unload=3600000`.
  <https://wiki.archlinux.org/title/Firefox/Tweaks>.
- **Build quality:** release builds use Clang 23, `-O3`, x86-64-v2 baseline and
  PGO (`waterfox/build/mozconfig-*`). Built-in ad blocker runs in-process
  (adblock-rust) which usually costs less than a uBO extension, but **no
  measurement** supports that: **UNVERIFIED**.
- **Zen reference point:** latest Zen 1.23.4b (2026-10-20) is based on Firefox
  158.0.1 (<https://github.com/zen-browser/desktop/releases>). So Waterfox is
  5 Gecko major versions behind Zen (ESR cadence vs. rapid), a security patch
  cadence difference worth knowing.

Reproducible measurement recipe (mine, not a benchmark; run the same 10-20 tabs
and the same extensions in each browser, 2 minutes after load):

```bash
# resident memory summed over all processes of a browser (PSS if smem is installed)
ps -eo pid,rss,comm,args | rg -i '/opt/waterfox/|waterfox-bin' \
  | awk '{s+=$2} END {printf "%.0f MiB RSS (double counts shared pages)\n", s/1024}'
# startup: time to first window
hyperfine --warmup 1 'waterfox --new-instance --profile /tmp/wf-bench --headless about:blank'
```

### Pros/cons

vs. **Zen Browser** (a Firefox-rapid fork with its own UI layer):

| Aspect              | Waterfox 6.7.7                                     | Zen 1.23.x                                           |
| ------------------- | -------------------------------------------------- | ---------------------------------------------------- |
| Gecko base          | 153.6 (ESR)                                        | 158.0.1 (rapid) per its GitHub releases              |
| Vertical tabs       | Native + tree tabs, no spaces/workspaces           | Vertical tabs + spaces + "Library" UI (Zen-specific) |
| Telemetry/studies   | Off/locked in shipped prefs, Normandy compiled out | UNVERIFIED here                                      |
| userChrome.css      | On by default                                      | UNVERIFIED here                                      |
| Policies.json       | Honoured, `/etc/waterfox/policies`                 | UNVERIFIED here                                      |
| Chrome-store addons | Removed in 6.7                                     | UNVERIFIED here                                      |
| Arch packaging      | `waterfox-bin` (official tarball) + Flatpak        | not researched                                       |
| Data portability    | Zen spaces/pins/sessions do not carry over         | -                                                    |

vs. **upstream Firefox** (Arch `firefox` package):

| Aspect               | Waterfox                                                                                 | Firefox                                  |
| -------------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------- |
| Update path          | AUR `waterfox-bin` (a few hours behind the tarball) or in-app                            | `pacman` (official repo, signed by Arch) |
| Privacy defaults     | Much stricter out of the box (see section 1)                                             | Needs policies/user.js to match          |
| Built-in blocker     | Yes                                                                                      | ETP only; uBO extension                  |
| Native tree tabs     | Yes                                                                                      | No (extension only)                      |
| DRM                  | Opt-in                                                                                   | Opt-in prompt as well                    |
| Security patch speed | Follows Mozilla ESR advisories (6.7.7 cites MFSA 2026-120); lag vs. Mozilla not measured | Mozilla's own cadence                    |
| Single maintainer    | Smaller team/bus factor (BrowserWorks Ltd, one owner)                                    | Mozilla                                  |

The table cells marked UNVERIFIED are deliberately not filled from memory.

## 6. Configuration for a dotfiles repo (chezmoi)

Layout fit with `CLAUDE.md`: `/etc/*` and `/opt/*` are **not** chezmoi-managed
(copy by hand with `sudo`), anything under `$HOME` is. So:

| Layer             | Live path                                                                 | Repo location (proposed)                                 |
| ----------------- | ------------------------------------------------------------------------- | -------------------------------------------------------- |
| Policies          | `/etc/waterfox/policies/policies.json`                                    | `etc/waterfox/policies/policies.json` (manual `sudo cp`) |
| Autoconfig        | `/opt/waterfox/defaults/pref/autoconfig.js`, `/opt/waterfox/waterfox.cfg` | `etc/`-style folder or a docs snippet (manual)           |
| Profile prefs/CSS | `~/.waterfox/<profile>/user.js`, `chrome/userChrome.css`                  | `home/dot_waterfox/<profile>/…` via chezmoi              |
| Desktop file      | `~/.local/share/applications/waterfox.desktop`                            | `home/dot_local/share/applications/waterfox.desktop`     |
| Env               | niri `environment {}` / fish                                              | existing niri/fish config                                |

### 6.1 Enterprise policies — VERIFIED (source)

Lookup order (source `EnterprisePoliciesParent.sys.mjs`,
`_getLocalConfigurationFile`): on Linux with `MOZ_SYSTEM_POLICIES` (true in the
tarball) the **system file `/etc/<appname-lowercase>/policies/policies.json`**
= `/etc/waterfox/policies/policies.json` is used if it exists; otherwise
`<install dir>/distribution/policies.json` (`XREAppDist`). The path logic is in
`xpcom/io/SpecialSystemDirectory.cpp` (`GetUnixSystemConfigDir`, `/etc` +
lower-cased app name; `/app/etc` under Flatpak). Mozilla's docs describe
the same two Firefox locations (`/etc/firefox/policies`,
`firefox/distribution`):
<https://mozilla.github.io/policy-templates/>,
<https://firefox-admin-docs.mozilla.org/guides/getting-started/>.

**Gotcha:** there is no merge. The `waterfox-bin` package ships its own
`/opt/waterfox/distribution/policies.json`
(`AppAutoUpdate:false, ManualAppUpdateOnly:true`). Your `/etc` file shadows it,
so repeat those two keys in yours. The Waterfox tarball itself ships **no**
`distribution/` directory.

Snippet (**VERIFIED** keys per Mozilla docs; extension IDs **UNVERIFIED**,
confirm each in `about:debugging#/runtime/this-firefox` or on the AMO page):

```json
{
  "policies": {
    "AppAutoUpdate": false,
    "ManualAppUpdateOnly": true,
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "NoDefaultBookmarks": true,
    "OverrideFirstRunPage": "",
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "installation_mode": "force_installed",
        "default_area": "navbar",
        "private_browsing": true
      },
      "vimium-c@gdh1995.cn": {
        "installation_mode": "normal_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi"
      },
      "tridactyl.vim@cmcaine.co.uk": {
        "installation_mode": "normal_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi"
      }
    }
  }
}
```

Notes from <https://firefox-admin-docs.mozilla.org/reference/policies/extensionsettings/>:
`installation_mode` is `allowed | blocked | force_installed | normal_installed`;
`install_url` is optional for AMO extensions as of Firefox 153;
`default_area` is `navbar | menupanel`; `private_browsing` since Firefox 136.
The uBlock0 example is Mozilla's own. With Waterfox's built-in blocker, installing
uBO triggers the blocker's extension-detection warning unless
`waterfox.blocker.coexist=true` (repo `02-privacy.js`,
`WaterfoxBlockerExtensionDetector.sys.mjs`). Sidebery is **not needed** (native
vertical tabs). Bitwarden / gopass-bridge: add the IDs the same way, **UNVERIFIED**.

The `Preferences` policy only accepts an **allow-list of pref prefixes**
(`accessibility.alerts.*`, `app.update.*`, `privacy.fingerprintingProtection.*`,
a few `security.*`, ...) and has `Status` `default | locked | user | clear`
(<https://firefox-admin-docs.mozilla.org/reference/policies/preferences/>).
Whether Waterfox's custom prefs (`waterfox.*`, `browser.tabs.verticalTabs.tree.*`)
or `sidebar.*`/`media.*` are in the allow-list was **not checked**
(**UNVERIFIED**); use autoconfig or `user.js` for those. Verify what applied at
`about:policies` (inherited Mozilla page, present in the tree:
`browser/components/enterprisepolicies/content/aboutPolicies.html`).

### 6.2 Autoconfig — design VERIFIED (source), file placement UNVERIFIED (runtime)

`nsReadConfig.cpp` reads `general.config.filename`,
`general.config.obscure_value` and `general.config.sandbox_enabled` from default
prefs; `defaults/autoconfig/prefcalls.js` is present in the tarball's `omni.ja`.
The tarball root has `defaults/pref/channel-prefs.js`, which is the supported
location for GRE default prefs.

```js
// /opt/waterfox/defaults/pref/autoconfig.js  (UNVERIFIED runtime)
pref("general.config.filename", "waterfox.cfg");
pref("general.config.obscure_value", 0);
```

```js
// /opt/waterfox/waterfox.cfg  -- first line must be exactly "//"
//
lockPref("browser.tabs.verticalTabs.tree.enabled", true);
defaultPref("sidebar.verticalTabs", true);
```

The Arch Wiki Firefox page documents the same two-file recipe for
`/usr/lib/firefox`:
<https://wiki.archlinux.org/title/Firefox#Settings_storage>. Caveat: `/opt/waterfox`
is owned by `waterfox-bin`; these two files are unowned and survive upgrades,
but a package reinstall to a clean root loses them. Prefer `user.js` unless you
need locked prefs. The AUR `waterfox-g-arkenfox-autoconfig` package targets the
old 140 base; do not use it.

### 6.3 Pinning a profile in dotfiles

Profile directory names are random (`xxxxxxxx.default-release`). To make paths
stable, launch with an explicit path (`--profile <path>` is in the binary's
`--help`, VERIFIED source):

```bash
waterfox --profile "$HOME/.waterfox/main"      # stable dir chezmoi can manage
waterfox --new-instance --profile "$HOME/.waterfox/work" --name waterfox-work
```

chezmoi then owns `~/.waterfox/main/user.js` and
`~/.waterfox/main/chrome/userChrome.css`. Whether `--profile` joins an already
running instance of another profile: **UNVERIFIED (runtime)**; use
`--new-instance`. Alternatively manage `~/.waterfox/profiles.ini` +
`installs.ini` (more brittle; `MOZ_DEDICATED_PROFILES` rewrites them).

### 6.4 `user.js`: what is already set vs. what to add

Waterfox already sets (so do **not** copy them from Betterfox/arkenfox):
telemetry/studies/Normandy/Safe Browsing off, referrer trimming, 0-RTT off,
OCSP off, `network.dns.disablePrefetch=true`, `pdfjs.enableScripting=false`,
GPC on, WebRTC address leak prefs, smooth-scroll MSD physics
(`general.smoothScroll.msdPhysics.enabled=true`), session restore
(`browser.startup.page=3`) (all VERIFIED in `00/02-*.js`).

Candidate additions (each VERIFIED as an existing pref with the quoted default
from the shipped `StaticPrefList.yaml`/`firefox.js`; whether you need it is
**UNVERIFIED (runtime)**):

```js
// ~/.waterfox/main/user.js
// --- Wayland/GPU: only if about:support shows video decoding blocked
// (Arch Wiki). Intel>=115 and AMD>=136 are default-on.
user_pref("media.hardware-video-decoding.force-enabled", true);
// only if fullscreen video flickers (Arch Wiki)
// user_pref("widget.wayland.opaque-region.enabled", false);

// --- portals: use the portal file picker (default 2 = auto = off outside Flatpak)
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
user_pref("widget.use-xdg-desktop-portal.settings", 2);   // already default
// content follows the system scheme (default is already 2; 3 = browser theme)
user_pref("layout.css.prefers-color-scheme.content-override", 2);
// force dark chrome regardless of portal (Arch Wiki; use only to override)
// user_pref("ui.systemUsesDarkTheme", 1);

// --- memory: unload idle tabs (default false on Linux)
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("browser.tabs.min_inactive_duration_before_unload", 3600000);
// process count (default 8; Arch Wiki: also disable the auto perf setting)
// user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);
// user_pref("dom.ipc.processCount", 4);

// --- vertical + tree tabs
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.revamp", true);
user_pref("browser.tabs.verticalTabs.tree.enabled", true);
user_pref("sidebar.autoHide", false);  // true = hide until mouse at edge (6.7.3)
```

Dark-mode note: the full chain is Noctalia/darkman -> portal
`org.freedesktop.appearance color-scheme` -> Gecko
(`widget.use-xdg-desktop-portal.settings=2`). The portal side is already proven
on this machine for Discord; Waterfox reading it is **UNVERIFIED (runtime)**.
Remember the portal legend `1` = dark, `2` = light, `0` = no preference
(<https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html>).

**Risky/overlapping prefs from community lists** (<https://github.com/yokoffing/Betterfox>,
community project, treat as low-trust; its `user.js` header says "version 154" while
Waterfox is on Gecko 153 — verify per pref before copying): `browser.cache.disk.enable=false`
(RAM-only cache, hurts restarts), `dom.security.https_only_mode=true` (breaks HTTP
LAN/dev hosts), `network.http.max-connections=1800` and the `network.buffer.*`
bumps (little evidence of benefit), `browser.contentblocking.category="strict"`
(site breakage), `permissions.default.geo/desktop-notification=2`,
`geo.provider.network.url` -> a third-party service. Waterfox's own
`network.trr.mode=2` + OHTTP relay (`04-dns.js`) can interact badly with
split-horizon/VPN DNS: set `network.trr.mode` to `5` (off) to opt out.
arkenfox (<https://github.com/arkenfox/user.js>) for Gecko 153 was **not
verified**; it also breaks sites by design (RFP). Prefer a short hand-written
`user.js`.

### 6.5 userChrome.css

`toolkit.legacyUserProfileCustomizations.stylesheets` is `true` and **locked** in
the shipped prefs (`00-general.js`), so a `chrome/` folder just works (the Arch
Wiki lists this pref as the usual fix:
<https://wiki.archlinux.org/title/Firefox#Changes_to_userChrome.css_and_userContent.css_are_ignored>).
Waterfox also has its own switch ("Load interface customisations",
`browser.theme.waterfox.chromeSheet`: 0 on / 2 off) and a UI-density pref
(`browser.uidensity=1`, compact). With native vertical tabs the horizontal strip
is already hidden by the browser, so no "hide tabs bar" CSS is needed. For the
horizontal layout:

```css
/* ~/.waterfox/main/chrome/userChrome.css -- selectors UNVERIFIED for 153 */
#TabsToolbar { visibility: collapse !important; }
```

Waterfox's own chrome CSS lives in `browser/omni.ja` under
`chrome/browser/skin/classic/browser/waterfox/chrome/` (`tree-tabs.css` etc.), which
you can read to find stable selectors.

### 6.6 Desktop file (fixes the stale `waterfox-default`)

```ini
# ~/.local/share/applications/waterfox.desktop  (shadows the package one)
[Desktop Entry]
Version=1.0
Type=Application
Name=Waterfox
GenericName=Web Browser
Exec=waterfox %u
Icon=waterfox
Terminal=false
StartupNotify=true
StartupWMClass=waterfox
Categories=Network;WebBrowser;
MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=waterfox --new-window %u

[Desktop Action new-private-window]
Name=New Private Window
Exec=waterfox --private-window %u
```

Modelled on the official `waterfox/browser/installer/linux/obs/waterfox.desktop`
(**VERIFIED** content). Environment: set `MOZ_ENABLE_WAYLAND=1` for explicitness
(niri `environment { MOZ_ENABLE_WAYLAND "1" }` or fish `set -gx`); verify
`about:support` -> Window Protocol = `wayland`.

niri rule (**UNVERIFIED (runtime)**, check the id first with `niri msg windows`):

```kdl
window-rule {
    match app-id=r#"^waterfox$"#
    // open-on-workspace "web"
}
```

## 7. Migration from Zen

- **Version gap (VERIFIED):** Zen 1.23.4b = Firefox 158.0.1
  (<https://github.com/zen-browser/desktop/releases>, 2026-10-20); Waterfox
  6.7.7 = Gecko 153.6.0. Zen's profile is therefore from a newer Gecko.
- **Downgrade protection:** Waterfox's build sets
  `imply_option("MOZ_BLOCK_PROFILE_DOWNGRADE", False)` (`browser/moz.configure`)
  and `--allow-downgrade` is absent from `--help`, so Waterfox will **not refuse**
  a newer profile the way stock Firefox does ("You've launched an older version
  of Firefox"). That removes the safety net, not the risk: SQLite schema
  versions (`places.sqlite`), session-store and addon DB formats can be newer
  than Gecko 153 expects, and results are **UNVERIFIED**. Mozilla's own
  guidance (community-answers on SUMO, older posts ~2019-2021) says a profile
  last used by a newer version can corrupt bookmarks/history, to use a new
  profile and copy only the data files you need, and that deleting
  `compatibility.ini` only suppresses the warning:
  <https://support.mozilla.org/en-US/questions/1259820>,
  <https://support.mozilla.org/ms/questions/1319261>.
  **Recommendation: make a fresh Waterfox profile and import data; do not point
  Waterfox at `~/.zen`.**
- **Where Zen keeps data:** Linux `~/.zen/` (Flatpak
  `~/.var/app/app.zen_browser.zen/zen/`); newer Zen builds may use the XDG
  `~/.config/zen` (GitHub discussion; **UNVERIFIED**). Find the live path at
  `about:support` -> Profile Directory (<https://docs.zen-browser.app/faq>).
- **Migration paths, in order of safety:**
  1. **Firefox Sync** (Waterfox ships Mozilla Sync; Zen has it too, **UNVERIFIED**
     for Zen 1.23). Syncs bookmarks, history, passwords, add-on list; tab groups
     are not synced (<https://support.mozilla.org/en-US/kb/tab-groups>).
  2. **Waterfox's own import wizard** (first-run step "data import", and
     `--migration`): imports bookmarks, history, form data, cookies, passwords
     (<https://www.waterfox.com/releases/6.7.0/>). It has a
     `FirefoxImportMigrator`; whether it **auto-detects Zen** is **UNVERIFIED**
     (list of branded migrators in the tree covers Chrome-family browsers; the
     Firefox-profile one lets you pick a profile folder).
  3. **Manual exports** from Zen: bookmarks via Library -> "Import and Backup"
     -> HTML/JSON; passwords via `about:logins` -> Export CSV (then import into
     Waterfox's `about:passwords`/`about:logins`, or into gopass/Bitwarden);
     containers: copy `containers.json` (labels/colours only, not data).
  4. **Selective file copy** into a fresh, closed Waterfox profile (general
     Firefox profile knowledge, **UNVERIFIED** against Mozilla docs because SUMO
     blocks bots): `places.sqlite`, `favicons.sqlite`, `key4.db` **and**
     `logins.json` (both required), `cert9.db`, `formhistory.sqlite`,
     `cookies.sqlite`, `permissions.sqlite`, `containers.json`. Do **not** copy
     `prefs.js`, `compatibility.ini`, `extensions.json` or `sessionstore`.
- **Extensions:** reinstall (or force-install via policy, 6.1). Zen-only
  features (spaces/workspaces, essentials, glance, split-view layouts, Boosts,
  `--space`) do not exist in Waterfox and their data is not portable.
  Chrome-style extensions will not install (store removed in 6.7.0).
- **Containers:** native containers exist; container assignments for sites
  (Multi-Account Containers add-on data) live in extension storage, which does
  not travel with a plain file copy: **UNVERIFIED**.

## Sources

Primary (Waterfox):

- <https://www.waterfox.com/> (privacy stance, maintainer, license, features)
- <https://www.waterfox.com/download/> (Linux tarball URLs, OBS repos, sizes)
- <https://www.waterfox.com/releases/> and `/6.7.0/`, `/6.7.1.1/`, `/6.7.6/`,
  `/6.7.0-beta.3/`, `/6.6.16/` (release notes)
- <https://github.com/BrowserWorks/waterfox> (source; files cited inline:
  `waterfox/browser/app/profile/00-general.js` ... `05-treetabs.js`,
  `waterfox/moz.configure`, `browser/moz.configure`, `toolkit/moz.configure`,
  `waterfox/build/mozconfig.common`, `toolkit/xre/nsAppRunner.cpp`,
  `toolkit/xre/nsXREDirProvider.cpp`, `widget/gtk/nsAppShell.cpp`,
  `widget/gtk/nsWindow.cpp`, `xpcom/io/SpecialSystemDirectory.cpp`,
  `toolkit/components/enterprisepolicies/EnterprisePoliciesParent.sys.mjs`,
  `modules/libpref/init/StaticPrefList.yaml`, `browser/app/profile/firefox.js`,
  `waterfox/browser/installer/linux/obs/*`)
- Official tarball `waterfox-6.7.7.tar.bz2` (`application.ini`, `platform.ini`,
  `browser/omni.ja` prefs, `AppConstants.sys.mjs`, `strings` on binaries)
- Flathub API (<https://flathub.org/api/v2/search>) for `net.waterfox.waterfox`

AUR (official endpoints):

- <https://aur.archlinux.org/rpc/v5/search/waterfox?by=name>,
  <https://aur.archlinux.org/rpc/v5/info/waterfox-bin>,
  <https://aur.archlinux.org/rpc/v5/info/waterfox>
- `https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=waterfox-bin` (and
  `?h=waterfox`, `waterfox.desktop` for both). The `waterfox` cgit PKGBUILD read
  at fetch time still showed 6.7.6 while the RPC said 6.7.7-1 (cache lag).

Mozilla / Arch:

- <https://mozilla.github.io/policy-templates/> (states it is "NOT current",
  points to admin docs)
- <https://firefox-admin-docs.mozilla.org/> (guides/getting-started,
  reference/policies/preferences, reference/policies/extensionsettings)
- <https://support.mozilla.org/en-US/kb/use-sidebar-access-tools-and-vertical-tabs>,
  <https://support.mozilla.org/en-US/kb/tab-groups> (via search results; pages
  themselves block bots)
- <https://support.mozilla.org/en-US/questions/1259820>,
  <https://support.mozilla.org/ms/questions/1319261> (community answers on
  newer-profile warnings; older, low-medium trust)
- <https://wiki.archlinux.org/title/Firefox> and `/Tweaks` (raw wikitext)
- <https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html>

Zen:

- <https://github.com/zen-browser/desktop/releases> (version 1.23.4b, Firefox
  158.0.1), <https://docs.zen-browser.app/faq> (profile paths)

Low-trust (labelled where used): Betterfox `user.js`
(<https://github.com/yokoffing/Betterfox>); Medium/Dedoimedo/tabgroupvault
benchmark posts; GitHub discussions on Zen profile migration.

## UNVERIFIED items

1. Literal Wayland `app_id` reported by Waterfox 6.7.7 under niri (expected
   `waterfox`; check `niri msg windows`).
2. Behaviour of `-P`/`--profile` with an already running instance, and
   `MOZ_DEDICATED_PROFILES` interaction; second-profile `--name` effect.
3. VA-API / hardware decoding on your GPU; NVIDIA path; Vulkan decoding.
4. Whether the portal screencast works on niri with `xdg-desktop-portal-gnome`.
5. Whether Waterfox honours the settings portal at runtime for live dark/light
   switching (the code and `org.freedesktop.appearance` string are present).
6. Whether Widevine works in the source-built AUR `waterfox` (no VMP signing).
7. Any hard RAM/CPU/startup/per-tab numbers for Waterfox vs Zen vs Firefox vs
   Chrome; Zen and Firefox install sizes.
8. Which prefs the `Preferences` policy allow-list admits (`waterfox.*`,
   `sidebar.*`, `browser.tabs.verticalTabs.*`).
9. Autoconfig placement (`/opt/waterfox/defaults/pref/`, `waterfox.cfg` beside the
   executable) works on Waterfox 6.7.7 (design verified from source only).
10. Extension IDs for Vimium-C, Tridactyl, Bitwarden, gopass-bridge, Sidebery in
    the policy snippet; their compatibility with Gecko 153.
11. Native-messaging discovery of existing `~/.mozilla/native-messaging-hosts`
    manifests (Tridactyl native, gopass) at runtime.
12. Default and customisable keyboard shortcuts beyond Ctrl+Alt+Z and the tree
    arrow keys; absence of a native shortcut remapping UI.
13. PWA/taskbar tabs on Linux (`browser.taskbarTabs.enabled=false` platform
    guard not checked).
14. The "Classic -> Current/G-series" history as prose (only AUR package names
    and the release index were verified).
15. Whether the import wizard auto-detects Zen, and the exact file set safe to
    copy from a Zen profile; effect of opening a Gecko 158 profile in 153.
16. Zen-side facts in the Pros/cons table (telemetry, policies, userChrome,
    extension store, Sync support).
17. Mozilla SUMO pages (autoconfig, profile files, keyboard shortcuts) were
    unreachable to automation; related statements come from general Firefox
    knowledge or the Arch Wiki.
