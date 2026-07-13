# gopass — terminal password manager

## Why

Passwords live in [gopass](https://www.gopass.pw/): GPG-encrypted files, versioned
in a **private git repo**, driven from the terminal. Self-custodied, offline-first,
and it reuses the "files + git" model everything else here already uses. For the
full rationale and rejected alternatives (Bitwarden, `pass`, KeePassXC) see
[ADR 0004](adr/0004-terminal-password-manager-gopass.md).

> [!IMPORTANT]
> The password **store is never part of this repo.** This public repo only tracks
> the `gopass`/`gnupg` packages and this guide. The encrypted store is its own
> private git repository under `~/.local/share/gopass/stores/root`.

## How it fits together

```text
gopass  ──uses──►  GPG key (encrypts every secret)
   │
   └──stores──►  ~/.local/share/gopass/stores/root  ──git push──►  private remote
```

Each secret is a single GPG-encrypted file. Because the store is a git repo, you
get history and multi-machine sync for free — the same way dotfiles sync.

## 1. Create a GPG key (once)

gopass encrypts to a GPG key, so you need one. The packages (`gnupg`, `pinentry`)
are in [packages.md](packages.md).

```sh
gpg --full-generate-key      # choose: (1) RSA and RSA or (9) ECC; a real name + email
gpg --list-secret-keys --keyid-format=long   # note your key id / email
```

> [!WARNING]
> **Back up the private key.** Lose it and the entire store is unrecoverable —
> there is no "forgot password" link. Export and store it somewhere safe/offline:
>
> ```sh
> gpg --export-secret-keys --armor you@example.com > ~/gpg-private-backup.asc
> ```

## 2. Initialise gopass

```sh
gopass setup                 # interactive: picks your GPG key, creates the store
# or explicitly:
gopass init you@example.com
```

## 3. Give the store a private git remote

```sh
gopass git init              # if not already a repo
# Create an EMPTY, PRIVATE repo on GitHub/GitLab first, then:
gopass git remote add origin git@github.com:you/password-store.git
gopass sync                  # pull + push
```

## Daily use

```sh
gopass insert github.com/you            # type a secret (hidden)
gopass generate github.com/you 24       # generate a 24-char password and store it
gopass show github.com/you              # print (careful: on screen)
gopass show -c github.com/you           # copy to clipboard instead (auto-clears)
gopass ls                               # tree of all entries
gopass grep pattern                     # search inside secrets
gopass edit github.com/you              # edit in $EDITOR
gopass otp github.com/you               # print a TOTP code
gopass sync                             # git pull + push across machines
gopass rm github.com/you                # delete an entry
```

Organise with folders (`work/`, `personal/`, `servers/`) — they're just paths:
`gopass insert work/gitlab/token`.

## What to put in it (starter layout)

Once the store is set up and pushed, seed it. A folder is just a path prefix, so a
tidy convention pays off later:

```text
personal/
  github.com          # or a PAT under github.com/token
  google              # email + recovery codes in the body
  ...bank, shopping, etc.
work/
  gitlab              # or work/gitlab/token
  aws/console         # AWS console login
  certs/vn-ca         # ← corporate CA cert bytes (see certs.md)
  certs/aws-signin
  certs/aws-apps
servers/
  vps-1               # ssh/root passwords, per host
```

A secret's **first line is the password**; everything after is free-form body
(usernames, URLs, recovery codes, notes). For TOTP, store the `otpauth://` URI and
use `gopass otp`. Non-password blobs (like the certs above) go in via `gopass cat`
— see [certs.md](certs.md).

> [!NOTE]
> `gopass show -c` needs a clipboard tool. On Wayland (niri) that's
> `wl-clipboard` (`wl-copy`); install it if copy does nothing.

## Multi-machine

On a second machine: install gopass, import the **same GPG private key**
(`gpg --import backup.asc`), then clone the store:

```sh
gopass clone git@github.com:you/password-store.git
```

From then on, `gopass sync` keeps them in step.

## Fish integration

gopass ships completions; enable them once:

```sh
gopass completion fish > ~/.config/fish/completions/gopass.fish
```

There's also a short alias `pw` (→ `gopass`) in
[`config.fish`](../home/dot_config/fish/config.fish), so `pw ls`, `pw show -c …`.

## gpg-agent (passphrase caching + pinentry)

Every `gopass show` decrypts with your GPG key, so `gpg-agent` sits behind the
whole workflow: it caches your passphrase and drives the prompt (pinentry). This
repo tracks one config for it,
[`home/private_dot_gnupg/private_gpg-agent.conf`](../home/private_dot_gnupg/private_gpg-agent.conf):

```text
pinentry-program /usr/bin/pinentry-curses
default-cache-ttl 3600
max-cache-ttl 7200
```

- **pinentry-curses** draws the passphrase prompt in the active terminal — no GUI
  or dbus needed, and it works over SSH. It needs `GPG_TTY`, which
  [`config.fish`](../home/dot_config/fish/config.fish) exports
  (`set -gx GPG_TTY (tty)`).
- The **cache TTLs** mean the passphrase is remembered for 1h idle / 2h max, so a
  gopass session isn't re-prompting on every entry. Reload the agent after editing:
  `gpg-connect-agent reloadagent /bye`.

> [!IMPORTANT]
> `gpg-agent.conf` is the **only** file tracked from `~/.gnupg`. The private keys
> (`private-keys-v3.d/`), `trustdb.gpg`, and random seed live in the same
> directory but are never committed — same rule as the store itself. chezmoi
> applies `~/.gnupg` as `0700` and this file as `0600`.

## Security notes

- The store is **private** and **external** to this repo — keep it that way.
- Guard the GPG key like the master password it effectively is: back it up, and
  consider a YubiKey for the private key long-term.
- `gopass audit` flags weak/duplicated/old passwords.

## References

- [gopass — documentation](https://github.com/gopasspw/gopass/tree/master/docs)
- [gopass — getting started](https://www.gopass.pw/)
- [certs.md](certs.md) — storing corporate CA certs in the store
- [ADR 0004 — why gopass](adr/0004-terminal-password-manager-gopass.md)
