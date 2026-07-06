# System-level secrets (CA certs) live in gopass, not chezmoi

**Status:** accepted

Infrastructure secrets that must land in `/etc` — currently the corporate CA
certificates needed for external access, the VPN, and AWS sign-in (see
[certs.md](../certs.md)) — are stored as secrets in [gopass](../gopass.md) and
restored by hand into `/etc/ca-certificates/trust-source/anchors/` followed by
`update-ca-trust`. The public repo tracks only the procedure, never the cert bytes.

## Considered options

- **gopass** — chosen. The store is already the home for self-custodied secrets
  ([ADR 0004](./0004-terminal-password-manager-gopass.md)); `gopass cat` handles
  PEM files cleanly, and the bytes stay in the private store, out of this public
  repo. Restore is two commands on a fresh machine.
- **chezmoi with encryption (age/gpg)** — rejected. It would put encrypted blobs
  in the public repo, directly contradicting the "no encryption in-repo, private
  data via templates" stance of [ADR 0002](./0002-private-data-via-templates.md).
  It also fights the rule that `/etc/*` is **not** chezmoi-managed (applied by hand
  — see [CLAUDE.md](../../CLAUDE.md)); certs are a system file, not a `$HOME` dotfile.
- **Offline USB only** — rejected as the primary store. Not reproducible without
  the physical medium and easy to lose. (Keeping a USB copy as an extra backup is
  still fine — gopass is the source of truth.)

## Consequences

- This is a **deliberate scoping** of ADR 0002, not a reversal: in-repo private
  data still uses templates + prompts with no encryption. Encryption-at-rest via
  gopass applies only to secrets that never enter this repo at all.
- Restoring these certs is a documented manual step in the fresh-install runbook —
  it can't be `chezmoi apply`-ed, because the target is `/etc` and root-owned.
