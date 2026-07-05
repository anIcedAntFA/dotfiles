# Terminal password manager: gopass over a cloud vault

**Status:** accepted

Passwords live in [gopass](https://www.gopass.pw/) — a `pass`-compatible,
GPG-encrypted, git-versioned store driven from the terminal — instead of a cloud
password manager. The encrypted store is its **own private git repo**, never this
public dotfiles repo; only the workflow guide ([gopass.md](../gopass.md)) and the
`gopass`/`gnupg` packages are tracked here. This keeps every secret self-custodied
and offline-capable while fitting the repo's existing "files + git" model.

## Considered options

- **gopass (GPG backend)** — chosen. Single Go binary on the AUR, a store layout
  compatible with `pass` (so no lock-in — the store is just GPG-encrypted files in
  a git repo), built-in git sync, TOTP, and a fzf-friendly TUI. GPG (not age) is
  the backend so the store stays interoperable with the wider `pass` ecosystem
  (browser extensions, mobile apps) and YubiKey.
- **`pass` (passwordstore.org)** — the same model, more minimal. Rejected only for
  ergonomics: gopass ships batteries (recipients management, TOTP, fuzzy TUI)
  without extra scripting, and its store stays `pass`-readable if we ever switch.
- **rbw / Bitwarden CLI** — a good terminal client, but the vault is cloud-hosted
  and not self-custodied. Rejected: we want the secrets under our own keys and git
  history, not a third party's server.
- **KeePassXC** — a single encrypted DB with GUI + CLI. Rejected: heavier and less
  terminal-native than a plain-files-in-git store, and it doesn't reuse the git
  sync we already rely on everywhere else.

## Consequences

- A **GPG key** is now part of the setup (previously there was none). It encrypts
  the gopass store. Git commit _signing_ deliberately does **not** reuse it — that
  uses SSH signing with the existing keys (see [git.md](../git.md)), keeping the
  GPG key single-purpose.
- The store's private remote must be created and backed up by hand; losing the GPG
  private key means losing the store, so key backup is a documented step.
- This does **not** change the repo's secrets policy: the store is external, and
  in-repo private data still uses templates + prompted values, not encryption (see
  [0002](./0002-private-data-via-templates.md)).
