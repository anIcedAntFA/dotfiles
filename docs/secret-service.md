# Secret Service — the desktop keychain on niri

Deep dive into how app credentials (Zed's GitHub sign-in, Chrome's password-store
key, AI provider API keys) get **stored and unlocked** on a niri + greetd session —
and why a minimal Wayland setup needs plumbing that GNOME/KDE hand you for free.

This is the **understand** doc. The **do** steps live in [greetd.md](greetd.md),
the **why we chose gnome-keyring** in
[ADR 0014](adr/0014-gnome-keyring-secret-service-via-greetd-pam.md), and the exact
terms in [CONTEXT.md](../CONTEXT.md).

## The symptom

Open Zed, sign in with GitHub, close it, open it again — signed out. Same with
Chrome and any saved login. The credential is fetched fine; it just has **nowhere
to be saved**, so every launch starts from zero.

That is not a Zed bug. It is a **missing piece of desktop infrastructure**: no
running **Secret Service**.

## Three things people call "the keychain" — keep them apart

These get conflated constantly. They are three different layers.

| Term               | What it is                                                                 | Who talks to it        | Where bytes land                    |
| ------------------ | -------------------------------------------------------------------------- | ---------------------- | ----------------------------------- |
| **Secret Service** | A D-Bus **API**, `org.freedesktop.secrets`. An _interface_, not a program. | apps, via `libsecret`  | — (it's just the contract)          |
| **Keyring**        | gnome-keyring's **implementation** of that API — an encrypted file store.  | the Secret Service API | `~/.local/share/keyrings/*.keyring` |
| **Store**          | Your **gopass** repo — a separate, CLI-driven, git-synced GPG store.       | _you_, by hand         | `~/.local/share/gopass/stores/root` |

The crucial split:

- **Secret Service + keyring** is the _automatic desktop keychain_ apps reach on
  their own. Machine-local. This is what's missing on niri.
- **Store** ([gopass](gopass.md)) is the _manual_ secrets vault you drive from the
  terminal and sync across machines. It is **not** wired to `org.freedesktop.secrets`
  unless you deliberately bridge it (see [the gopass alternative](#alternative-one-store-via-pass-secret-service--pam_gnupg)).

An app never says "use gnome-keyring". It says "hey `org.freedesktop.secrets`, save
this". Whoever owns that D-Bus name answers — gnome-keyring, KWallet, or
pass-secret-service. Swappable by design.

## Why GNOME/KDE "just work" and niri doesn't

A full desktop environment starts a Secret Service provider **and unlocks it** as
part of logging you in — you never notice because it's bundled. niri is a bare
compositor: it starts _nothing_ of the sort. greetd authenticates you and launches
the compositor; the gap between "logged in" and "keychain running + unlocked" is
yours to fill.

So the fix has two halves, and both matter:

1. **Run a provider** — install gnome-keyring so `org.freedesktop.secrets` exists.
2. **Unlock it at login** — so apps can actually read/write without a prompt.

Half 1 alone gives you a _locked_ keychain that pops a dialog on first use (see the
Home column below). Half 2 is what makes it seamless.

## Which apps actually need this?

Only _some_ apps broke when there was no Secret Service (Zed did; VS Code, Slack, Waterfox
didn't). That's not random — apps fall into three credential-storage strategies, and
only one of them hard-depends on the keyring:

| Strategy                                       | Apps here                                                                                 | Where the secret lives                                                  | Needs gnome-keyring?                     |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------- |
| **A. App-private store**                       | Waterfox (Firefox engine)                                                                 | its own NSS `key4.db` + `logins.json` in the profile                    | ❌ never — self-contained                |
| **B. Chromium/Electron `safeStorage`, tiered** | Chrome, VS Code, Slack, teams-for-linux                                                   | picks a backend at runtime: `gnome-libsecret` → `kwallet` → **`basic`** | ❌ works without — falls back to `basic` |
| **C. Secret-Service-only, no fallback**        | **Zed** (Rust; speaks `org.freedesktop.secrets` over D-Bus directly, no `libsecret` link) | the keyring, or nothing                                                 | ✅ **hard requirement**                  |

- **A** apps keep their own encrypted vault and never touch `org.freedesktop.secrets`,
  so a missing keyring is invisible to them.
- **B** apps (Chromium and everything Electron) select a `--password-store` backend
  when they start. With no keyring they silently drop to **`basic`** — a plaintext
  store obfuscated with a hard-coded key. They _persist_, but **unencrypted at rest**.
  That's why VS Code/Slack/Chrome "kept" your logins before the fix — insecurely.
  Chrome specifically reaches the keyring through the freedesktop **Secret portal**
  (xdg-desktop-portal), not a direct `gnome-libsecret` link — you can see it in
  `~/.config/google-chrome/Local State` as `os_crypt.portal.prev_init_success: true`.
  Same destination (`org.freedesktop.secrets`), different route.
- **C** is Zed alone: a native Secret Service client with no fallback tier, so it
  simply fails to store when no provider answers. This is exactly why the fix is
  **Zed-specific** — the ADR's "not a Zed bug, missing infrastructure" point.

> [!NOTE]
> Now that gnome-keyring is installed, **B** apps may re-prompt _once_ as they migrate
> from `basic` to the keyring backend — a one-time cost, not a regression.

Two same-tier apps can still behave differently for reasons that have nothing to do
with storage. **Slack stays logged in but Teams re-prompts** even though both are
Electron: Slack's tokens are long-lived, while Microsoft **AAD conditional access** on
a work tenant forces short token lifetimes and periodic re-auth. That's the _auth
server's_ policy, not a local-keyring gap — no amount of keyring work changes it.

## The full chain, boot to app

```text
power on
   │
   ▼
greetd            ← minimal login daemon on a VT (seat0, via systemd-logind)
   │  runs the greeter as the unprivileged `greeter` user
   ▼
tuigreet          ← the TUI: you type your username + password
   │
   ▼
PAM  (/etc/pam.d/greetd)          ← the authentication stack
   ├── pam_unix / system-local-login  → verify the password
   ├── pam_gnome_keyring (auth)        → stash that same password for the session
   └── pam_gnome_keyring (session,     → daemon is already socket-activated, so this
        auto_start)                       only UNLOCKS the `login` keyring with the
                                          stashed password — it does NOT launch the
                                          daemon on this box
   │
   ▼
niri-session      ← wrapper: systemctl --user import-environment,
   │                seed D-Bus activation env, then `exec niri --session`
   ▼
niri              ← the Wayland compositor; graphical-session.target is up
   │
   ├── systemd --user owns gnome-keyring-daemon.socket (shipped enabled); the first
   │   D-Bus access socket-activates the daemon (--components=pkcs11,secrets)
   │      └── gnome-keyring-daemon owns  org.freedesktop.secrets
   │          (the `login` keyring was already UNLOCKED by PAM above)
   │
   ▼
apps (Zed, Chrome, …)
   │  via libsecret / the Secret portal → org.freedesktop.secrets
   ▼
read/write encrypted secrets in ~/.local/share/keyrings/login.keyring
```

### The three PAM lines, decoded

The only additions over Arch's default `/etc/pam.d/greetd` are three
`pam_gnome_keyring.so` lines, each on a different PAM phase
([source](../etc/pam.d/greetd)):

```text
auth      optional  pam_gnome_keyring.so            # 1. remember the password
password  optional  pam_gnome_keyring.so            # 2. keep keyring pw == login pw
session   optional  pam_gnome_keyring.so auto_start # 3. unlock `login` (see below)
```

1. **auth** — grabs the password a _prior_ module (`pam_unix`) already collected and
   stashes it. It never prompts on its own; if there's no password, it does nothing.
2. **password** — when you _change_ your login password, it re-keys the keyring to
   match, so the two never drift apart.
3. **session `auto_start`** — the keyword _asks_ PAM to spawn the daemon, but on this
   box the daemon is **already socket-activated** (see the note below), so PAM finds no
   control file to own (`gkr-pam: unable to locate daemon control file`), stashes the
   password "to try later", and its real effect is to **unlock the keyring literally
   named `login`** with that password (`gkr-pam: unlocked login keyring`). Launching
   the daemon is the socket unit's job, not this line's.

> [!IMPORTANT]
> **The daemon is systemd socket-activated, not PAM-launched.**
> `gnome-keyring-daemon.socket` is a `--user` unit shipped **enabled** by the package;
> the first D-Bus access to `org.freedesktop.secrets` socket-activates
> `gnome-keyring-daemon` (running `--foreground --components=pkcs11,secrets`). So the
> `auto_start` keyword above is a harmless fallback that never actually starts anything
> here — PAM's whole contribution is _stash password → unlock `login`_. Don't expect a
> classic `--daemonize --login` process; that PAM-launched form doesn't happen on this
> setup.

All three are **`optional`**: if the module is missing or errors, login still
succeeds — you just lose auto-unlock. That's deliberate; PAM sits on the login path
and you never want a keyring hiccup to lock you out of your own machine.

### Why the keyring must be named `login`

Auto-unlock only touches the keyring named **`login`**. A keyring named anything else
— e.g. **`Default Keyring`** — is invisible to `pam_gnome_keyring`, so the first app
to use it triggers a system "unlock keyring" dialog instead. That single naming fact
explains the whole Home-vs-company difference:

|                                      | **Home**                                         | **this box, today**          | **this box, after the fix** |
| ------------------------------------ | ------------------------------------------------ | ---------------------------- | --------------------------- |
| `gnome-keyring` installed            | yes                                              | **no**                       | yes                         |
| `org.freedesktop.secrets` on the bus | yes                                              | **nothing**                  | yes                         |
| The keyring                          | `Default Keyring`, locked, **not** auto-unlocked | none (files inert)           | `login`, **PAM-unlocked**   |
| First app launch                     | "unlock keyring" dialog                          | no dialog                    | no dialog                   |
| Sign-in persists?                    | ✅ after you unlock                              | ❌ **re-login every launch** | ✅ seamless                 |

The counter-intuitive result: the fix makes this box **better than Home**. Home has a
`Default Keyring` with its own password that PAM never auto-unlocks, so it prompts
once per session (that's the "Authentication required — keyring Default Keyring is
locked" dialog). Give Home a `login` keyring + the same PAM lines and its dialog
disappears too.

### Still prompting after the fix? Check the default alias

Installing gnome-keyring and the PAM lines is necessary but **not always
sufficient** — a legacy keyring plus a mis-pointed alias defeats both. This is the
trap this box actually hit, and it looks like a broken PAM stack but isn't.

`~/.local/share/keyrings/default` is a one-line file — the **default alias** — naming
the collection apps get when they don't ask for one by name. PAM faithfully unlocks
`login` every boot, but if an earlier setup left a legacy `Default.keyring` (its _own_
password, ≠ login) **and the alias still points at it**, apps land on that locked
keyring and fire the "unlock keyring" dialog — while the PAM-unlocked `login` keyring
sits empty and unused. Diagnose, then retire the legacy keyring and repoint the alias:

```sh
# Where does the default alias point?
busctl --user call org.freedesktop.secrets /org/freedesktop/secrets \
  org.freedesktop.Secret.Service ReadAlias s default   # want: …/collection/login

# If it points at a legacy `Default` collection, retire it and repoint:
rm ~/.local/share/keyrings/Default.keyring
printf 'login' > ~/.local/share/keyrings/default
```

Then log out and back in so a fresh daemon reads the alias. **One-time cost:** the
secrets that lived in `Default` are gone, so re-sign into Zed (mints a fresh token into
`login`) and re-login to sites in Chrome (synced passwords repopulate; cookies don't).
Deleting loses whatever was in that keyring — only do it once you've confirmed nothing
else depends on it.

> [!NOTE]
> If there's no legacy keyring at all — a genuinely fresh box — gnome-keyring simply
> creates the `login` keyring on first PAM unlock and the alias points at it
> automatically. The trap above only appears when an _older_ install left artifacts
> behind.

## The security trade-off

PAM auto-unlock **couples the keyring password to your login password** — unlocking
one unlocks the other. That's the accepted cost of a no-second-prompt flow, and it's
exactly what GDM/SDDM do. The reasoning: anyone who has your login password already
has your session; the keyring adds no weaker link. Full rationale in
[ADR 0014](adr/0014-gnome-keyring-secret-service-via-greetd-pam.md#the-security-trade-off).

## Verifying it

```sh
# Is a provider on the bus?
busctl --user list | rg org.freedesktop.secrets      # a hit ⇒ provider is up

# End-to-end round-trip through the API (needs libsecret's secret-tool):
secret-tool store --label=test test key ; secret-tool lookup test key ; \
  secret-tool clear test key

# Is the daemon running with the components you expect?
# socket-activated ⇒ expect `--foreground --components=pkcs11,secrets`,
# NOT a `--daemonize --login` process.
pgrep -a gnome-keyring-daemon
systemctl --user is-enabled gnome-keyring-daemon.socket   # want: enabled
```

On current Arch, gnome-keyring's daemon ships with **SSH disabled** (that moved to
`gcr-ssh-agent`) and its GPG agent removed — so it will **not** hijack your
`SSH_AUTH_SOCK` or fight the `gpg-agent` behind [gopass](gopass.md). It provides
`secrets` (and `pkcs11`) only. One less thing to worry about on a non-GNOME box.

## Alternative: one store, via pass-secret-service + pam_gnupg

You already keep a GPG-encrypted [Store](gopass.md). The tempting idea: don't run a
_second_ secret store — bridge the Secret Service straight to gopass. That's
**pass-secret-service**: a daemon that claims `org.freedesktop.secrets` but persists
each secret as a GPG file in your pass/gopass store. Apps can't tell the difference.

The piece that makes it _seamless_ (and that ADR 0014 was written before weighing) is
**`pam_gnupg`** — the GPG analog of `pam_gnome_keyring`. It hands your login password
to `gpg-agent` at login, presetting your key's passphrase, so no pinentry ever fires
during the session:

```text
tuigreet password
   │
   ▼
PAM
   ├── pam_unix              → verify login
   └── pam_gnupg             → preset that password into gpg-agent (unlocks GPG key)
   │
   ▼
niri session
   │
   ▼
pass-secret-service  owns  org.freedesktop.secrets
   │   decrypts/encrypts via gpg-agent (already unlocked)
   ▼
gopass Store  (GPG files, git-versioned)
   ▲
apps (Zed, Chrome) ── libsecret ──┘
```

### Trade-offs vs gnome-keyring

|                      | gnome-keyring + `pam_gnome_keyring` | pass-secret-service + `pam_gnupg`                                                                                                                                      |
| -------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stores of secrets    | **two** (keyring + Store)           | **one** (Store only)                                                                                                                                                   |
| Unlock at login      | login pw → `login` keyring          | login pw → `gpg-agent`                                                                                                                                                 |
| Cross-machine sync   | no (machine-local)                  | yes (git)                                                                                                                                                              |
| Session prompts      | none                                | none, until gpg-agent cache TTL expires → then a **GUI** pinentry (add `pinentry-gnome3`/`-qt`; the `pinentry-curses` in [gopass.md](gopass.md) can't serve a GUI app) |
| Constraints          | keyring pw == login pw              | GPG passphrase == login pw; systemd user-service start races the unlock (needs a small startup delay); screen lockers must call `pam_setcred`                          |
| Maturity / footprint | battle-tested, tiny                 | works, less common                                                                                                                                                     |

### Why it's documented but deferred

`pass-secret-service` is genuinely viable — not "too fiddly" as first assumed. It's
deferred for two concrete reasons, not hand-waving:

1. **App tokens should stay machine-local.** OAuth/session tokens (Zed sign-in,
   Chrome's store key) syncing into the git-versioned Store — even encrypted — is
   undesirable: a leaked machine would expose every machine's live sessions, and
   these tokens are per-device by nature. gnome-keyring's per-machine keyring is a
   _feature_ here, not a limitation.
2. **Fewer moving parts.** gnome-keyring is one package + three PAM lines. The gopass
   bridge adds a daemon, `pam_gnupg`, a GUI pinentry, and a startup-delay workaround —
   more surface for a marginal philosophical gain.

Revisit if consolidating every secret onto the single GPG backend ever outweighs
those two points. The flow above is the blueprint when that day comes.

## References

- [ArchWiki — GNOME/Keyring](https://wiki.archlinux.org/title/GNOME/Keyring)
- [GNOME — GnomeKeyring PAM manual](https://wiki.gnome.org/Projects/GnomeKeyring/Pam/Manual)
- [freedesktop — Secret Service API](https://specifications.freedesktop.org/secret-service/latest/)
- [cruegge/pam-gnupg](https://github.com/cruegge/pam-gnupg) — unlock gpg-agent at login
- [grimsteel/pass-secret-service](https://github.com/grimsteel/pass-secret-service)
- [Chromium — Linux password storage](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux/password_storage.md)
- [greetd.md](greetd.md) · [gopass.md](gopass.md) · [ADR 0014](adr/0014-gnome-keyring-secret-service-via-greetd-pam.md)
