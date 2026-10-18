# greetd — login manager

## Why

[greetd](https://sr.ht/~kennylevinsen/greetd/) is a minimal, compositor-agnostic
login daemon. Paired with [tuigreet](https://github.com/apognu/tuigreet) it gives
a clean text-UI login that launches Wayland sessions (like niri) — no heavy
display manager required.

## Why launch niri as a _session_ (not bare `niri` on a tty)

You could autologin to a tty and run bare `niri` from your shell profile. We don't —
we launch it as a **session** through a desktop entry
(`/usr/share/wayland-sessions/niri.desktop`) whose `Exec=niri-session`. The
difference is `niri-session`, a wrapper that turns a compositor process into a
managed **login session**:

- `systemctl --user import-environment` — hands the login environment to the
  **systemd user manager**, so `systemctl --user` services see the right vars.
  This upstream call passes no variable list, so systemd prints
  `Calling import-environment without a list of variable names is deprecated` on the
  greeter VT at login (and again on shutdown). It's **cosmetic** — the import still
  works — and it comes from the package-owned `/usr/bin/niri-session`, so we don't
  patch it (an update would clobber the edit). Note: because this runs _before_ niri
  is up, `WAYLAND_DISPLAY` isn't exported here — see the `WAYLAND_DISPLAY` guard in
  [theme-sync.md](theme-sync.md).
- seeds the **D-Bus activation** environment, so D-Bus-activated services (like the
  Secret Service) start with the correct context.
- brings up `graphical-session.target`, the anchor other user units order against.
- then `exec niri --session`.

Why it matters here specifically: launching through greetd opens a proper **PAM
session** (`/etc/pam.d/greetd`), which is the _only_ place `pam_gnome_keyring`'s
`session auto_start` line can run to **unlock** the `login` keyring at login (the
daemon itself is systemd socket-activated — see [secret-service.md](secret-service.md)).
Bare `niri` from a tty has no login manager
running that PAM stack, so you'd hand-roll env import, D-Bus activation, and keyring
unlock yourself. The session route gets all three for free.

## greetd vs a display manager

|                          | **greetd + tuigreet**                                 | **GDM / SDDM**                     |
| ------------------------ | ----------------------------------------------------- | ---------------------------------- |
| Footprint                | tiny, no X, compositor-agnostic                       | pulls a GNOME/KDE + graphics stack |
| Attack surface           | minimal daemon on a VT                                | large                              |
| Greeter                  | TUI (or `regreet`/`gtkgreet` for GUI)                 | full graphical                     |
| Config                   | one `config.toml`, scriptable                         | GUI/desktop-file driven            |
| PAM login session        | yes → enables keyring auto-unlock                     | yes                                |
| Bundled desktop plumbing | **none** — you wire up keyring, polkit agent, portals | mostly bundled                     |

The last row is the whole point of this repo's keyring work: a display manager would
have handed you a Secret Service; greetd deliberately does not, so you add exactly
what you want and nothing else. The trade is **control and minimalism** for **some
assembly required** — see [secret-service.md](secret-service.md) for the piece we
assembled.

## Components at a glance

Who does what between power-on and a usable desktop:

| Component                                      | Role                                                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **greetd**                                     | login daemon; authenticates via PAM, launches the chosen session as you                           |
| **tuigreet**                                   | the greeter UI greetd runs (username/password, session picker)                                    |
| **PAM** (`/etc/pam.d/greetd`)                  | the auth stack; where `pam_gnome_keyring` hooks in                                                |
| **systemd-logind**                             | seat/session manager — grants `seat0` device access, tracks the login session (no `seatd` needed) |
| **niri-session**                               | wrapper that makes niri a managed systemd user session (see above)                                |
| **niri**                                       | the Wayland compositor itself                                                                     |
| **session D-Bus bus**                          | per-session IPC; carries `org.freedesktop.secrets` and portal calls                               |
| **gnome-keyring-daemon**                       | the Secret Service provider (added by us)                                                         |
| **gcr / gcr-prompter**                         | draws the "unlock keyring" dialog when a keyring isn't auto-unlocked                              |
| **libsecret**                                  | client library apps use to reach the Secret Service                                               |
| **xdg-desktop-portal** (+ `gnome`/`gtk`/`wlr`) | sandbox/portal APIs (file pickers, screenshare, color-scheme)                                     |

## Install

```sh
yay -S --needed greetd greetd-tuigreet
```

## Configure

The config is a **system** file at `/etc/greetd/config.toml` (tracked in this
repo at [`etc/greetd/config.toml`](../etc/greetd/config.toml)):

```toml
[terminal]
vt = 2

[default_session]
command = "tuigreet --time --greeting 'Arch • Niri • Noctalia' --asterisks --sessions /usr/share/wayland-sessions ..."
user = "greeter"
```

- `--sessions /usr/share/wayland-sessions` — where niri's `.desktop` session
  entry lives, so it shows up as a choice.
- `--asterisks` — mask the password with `*`.
- The `--theme` string colors the greeter.

Install and enable it:

```sh
sudo cp etc/greetd/config.toml /etc/greetd/config.toml
sudo systemctl enable greetd.service
```

## Quiet boot (optional)

For a clean handoff from GRUB to the greeter, reduce kernel log noise. Edit
`/etc/default/grub`:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog nvme_load=YES"
```

Then regenerate:

```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

On **systemd-boot** (the plain-Arch `laptop`, see
[arch-install.vi.md](arch-install.vi.md#74-systemd-boot)), add the same words to the
`options` line of each entry in `/boot/loader/entries/*.conf`; the change applies on
the next boot with no regenerate step. Use only `quiet loglevel=3`:
`nowatchdog nvme_load=YES` are EndeavourOS's own defaults, not something plain Arch
needs.

## Keyring / Secret Service (app credentials)

> The terse how-to is below; the full architecture, the Home-vs-this-box diagnosis,
> and the gopass alternative are in **[secret-service.md](secret-service.md)**.

Apps that store secrets in the **system keychain** — Zed's GitHub sign-in token
and AI provider API keys, for example — need a running **Secret Service**
(`org.freedesktop.secrets`) to persist them. A niri session started by greetd has
none by default: nothing installs or unlocks one. The symptom is an app that
**re-prompts for sign-in on every launch** (Zed: "sign in with GitHub" each time
you open it) — the token is fetched fine but has nowhere to be saved.

The fix is [gnome-keyring](https://wiki.archlinux.org/title/GNOME/Keyring) unlocked
by PAM at login (keyring password = your login password):

```sh
sudo pacman -S --needed gnome-keyring
sudo cp etc/pam.d/greetd /etc/pam.d/greetd   # adds 3 `pam_gnome_keyring.so` lines
```

Log out and back in. The daemon is **socket-activated** (`gnome-keyring-daemon.socket`,
shipped enabled — PAM does not launch it); the `auth` line stashes the password you
typed in tuigreet and the `session … auto_start` line uses it to unlock the **`login`**
keyring. Verify:

```sh
busctl --user list | rg freedesktop.secrets   # a hit ⇒ provider is up

# and the default alias must resolve to the `login` collection:
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets \
  org.freedesktop.Secret.Service ReadAlias s default   # want: …/collection/login
```

Then sign into Zed once — it now sticks across relaunches and reboots.

> [!NOTE]
> If sign-in still doesn't persist (or you still get an unlock prompt), the usual
> cause is a **legacy keyring + a mis-pointed default alias**, not a broken PAM
> stack — the `default` alias points at an old `Default` keyring instead of `login`.
> The diagnosis and one-command fix are in
> [secret-service.md](secret-service.md#still-prompting-after-the-fix-check-the-default-alias).

The three PAM lines are all `optional`, so a missing module can never lock you out
of login. Alternative providers (KWallet, or `pass-secret-service` backed by the
gopass [Store](../CONTEXT.md)) exist but gnome-keyring is the lightest drop-in for
a non-GNOME session. Full rationale and the security trade-off:
[ADR 0014](adr/0014-gnome-keyring-secret-service-via-greetd-pam.md).

## References

- [greetd wiki](https://man.sr.ht/~kennylevinsen/greetd/)
- [tuigreet](https://github.com/apognu/tuigreet)
