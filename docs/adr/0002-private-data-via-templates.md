# Handle private data with templates + prompts, no encryption

**Status:** accepted

Private data in this repo is machine- and identity-specific (git email/name,
work GitLab host, `ghq` company root, `/etc/hosts` dev entries) — not true
secrets. There are no keys, tokens, or passwords committed. So we template these
values with chezmoi and supply them via prompted data (`.chezmoi.toml.tmpl`
prompts stored in `~/.config/chezmoi/chezmoi.toml`, which is never committed). We
do **not** add `age`/GPG encryption or a password-manager integration yet.

The one genuinely sensitive committed file — a corporate SSL/MITM CA cert
(`etc/ca-certificates/.../cert_vn_ssl_cert.crt`) — is **removed** from the repo
rather than faked or encrypted: it is useless to anyone else and leaks the
employer. Company users add their own cert out of band.

## Consequences

- Adding a real secret to the repo later requires revisiting this decision and
  introducing `age` (chezmoi's recommended backend) — a superseding ADR.
- The public source contains only placeholder/prompted values; a fresh
  `chezmoi init` prompts for the real ones.
