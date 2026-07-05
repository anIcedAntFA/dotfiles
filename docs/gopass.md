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

## Security notes

- The store is **private** and **external** to this repo — keep it that way.
- Guard the GPG key like the master password it effectively is: back it up, and
  consider a YubiKey for the private key long-term.
- `gopass audit` flags weak/duplicated/old passwords.

## References

- [gopass — documentation](https://github.com/gopasspw/gopass/tree/master/docs)
- [gopass — getting started](https://www.gopass.pw/)
- [ADR 0004 — why gopass](adr/0004-terminal-password-manager-gopass.md)
