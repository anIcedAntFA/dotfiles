# Adopt chezmoi as the dotfile manager

**Status:** accepted

We manage these dotfiles with [chezmoi](https://www.chezmoi.io/) instead of the
previous plain git-mirror + `install.sh` symlink approach (or a `git --bare`
repo). The repo is public — it doubles as a blog/showcase — yet it must carry
machine- and identity-specific data (git email/name, work GitLab host, `ghq`
company root, `/etc/hosts` dev entries). chezmoi solves that public-vs-private
tension directly: files are templated and the private values are supplied per
machine, so the source stays public and safe to share.

## Considered options

- **Plain git-mirror + symlink `install.sh`** (previous state) — simplest to read
  and copy by hand, but private data must be scrubbed or excluded manually, with
  no per-machine templating. Rejected: doesn't scale to a public repo with real
  identity data.
- **`git --bare` + alias** — no symlinks, files live in place. Rejected: still no
  templating for private data, and more confusing to a blog audience than either
  alternative.
- **chezmoi** — chosen.

## Consequences

- Source files are renamed to chezmoi's convention (`dot_config/`, `.tmpl`), so
  the repo is no longer a byte-for-byte mirror you can `cp` directly. Applying it
  requires `chezmoi apply`.
- Private/identity values are handled with **templates + prompted data only, no
  encryption** (see [0002](./0002-private-data-via-templates.md)) — the repo has
  no committed secrets today, so `age`/password-manager integration is deferred
  until a real secret needs to live in the repo.
