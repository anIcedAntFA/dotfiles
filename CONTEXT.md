# linux-setup — Context

Glossary for this dotfiles repo. Definitions only — the _how_ lives in `docs/`.
Terms here are the ones that are easy to conflate; pick the listed word, avoid the
rest.

## Secrets & access

**Store**:
The gopass password store — a GPG-encrypted, git-versioned repo of secrets that
lives **outside** this public repo. The one place private bytes (passwords, certs)
are kept.
_Avoid_: vault, password DB, keychain.

**Trust anchor** (or _anchor_):
A CA certificate file under `/etc/ca-certificates/trust-source/anchors/`. It is the
**source of truth**; the matching files in `/etc/ssl/certs/` are generated from it
by `update-ca-trust`. When we say "restore a cert", we mean the anchor.
_Avoid_: calling the generated `/etc/ssl/certs/*.pem` the cert.

**Auth key** vs **Signing key**:
The same per-host SSH key registered on GitHub/GitLab **twice**, under two separate
roles — one to authenticate (push/pull), one to verify commit/tag signatures. Not
two different keys, and unrelated to the GPG key.
_Avoid_: treating "signing key" as GPG (signing is SSH here; GPG is only for the Store).

**Portal**:
The GlobalProtect VPN gateway host. Stored as the chezmoi var `workVpnPortal`, never
hard-coded in the repo.
_Avoid_: server, endpoint, gateway (in config we say portal).

## Machines

**Machine profile** (or _profile_):
One of the three boxes this config targets — `work`, `laptop`, or `home` — selected
by the chezmoi var `machine` (prompted on init, stored in the gitignored
`chezmoi.toml`). Templated configs branch on it to pick outputs, DPI cosmetics,
startup apps, and input. The value is a generic form-factor label, never a hostname
or company name (the real hostname may carry a company tag, so it stays out of the repo).
_Avoid_: host, box, device (in config we say profile / the `machine` var).

## Identity

**Identity** (personal / work):
A git author+signing pair selected by directory via `includeIf`. "Personal" is the
default; "work" applies under the company ghq root.
_Avoid_: account, profile, user.
