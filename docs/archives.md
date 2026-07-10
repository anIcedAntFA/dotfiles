# Archives — 7-Zip · ouch · PeaZip

## Why more than `tar`/`unzip`

`tar`, `unzip`, and `unrar` cover the basics, but three things are missing: one
CLI that speaks **every** format, an ergonomic wrapper for **scripts**, and a
**GUI** to browse an archive before extracting it (the WinRAR reflex). So the set
here is layered — reach for the lightest tool that does the job:

| Tool          | Kind | Reach for it when…                                            |
| ------------- | ---- | ------------------------------------------------------------- |
| `7zz`         | CLI  | any format, max ratio, encryption, listing/testing, `.rar` in |
| `ouch`        | CLI  | quick one-liners & bash scripts (auto-detects the format)     |
| `tar` (+zstd) | CLI  | Linux backups that must keep perms/owner/symlinks             |
| `unzip`/`zip` | CLI  | plain `.zip` interop with Windows/others                      |
| **PeaZip**    | GUI  | browse/preview before extracting, drag-drop, split, encrypt   |

## Install

```sh
yay -S --needed 7zip ouch peazip
```

- **`7zip`** (official repo) → the **`7zz`** binary — the modern, maintained
  7-Zip by its original author. (Not `p7zip`, which is unmaintained since 2016.)
- **`ouch`** (official repo) — one-command compress/decompress.
- **`peazip`** (AUR, Qt6) — the GUI. It **depends on `7zip`**, `brotli`, and
  `zstd`, so those come with it; we still install `7zip` explicitly so `7zz`
  stands on its own if PeaZip is ever removed.

Your existing `tar`/`bsdtar`/`unzip`/`unrar`/`zstd`/`xz` stay as-is.

## CLI: 7zz

The Swiss-army knife. **`x` keeps folder structure, `e` flattens it** — the
classic footgun, so prefer `x`:

```sh
7zz l archive.7z              # list contents (a quick text "preview")
7zz x archive.7z             # extract WITH paths, into the current dir
7zz x archive.7z -o out/     # …into out/
7zz t archive.7z             # test integrity
7zz x movie.rar              # yes — 7zz extracts .rar too

7zz a out.7z file1 dir/      # create
7zz a -mx=9 out.7z dir/      # max compression
7zz a -p -mhe=on out.7z dir/ # encrypt (‑mhe=on also encrypts the file names)
```

> [!NOTE]
> `.7z` does **not** store Unix owners/permissions well. For a Linux backup you
> want to restore faithfully, archive with `tar` first (below), not bare `.7z`.

## CLI: ouch (scripts)

`ouch` picks the format from the file extension, so scripts stay readable — no
per-format flags to memorise:

```sh
ouch d archive.zip           # decompress anything (auto-detected)
ouch d logs.tar.zst -d out/  # …into out/
ouch c backup.tar.zst src/   # compress (format = the extension you name)
ouch c secrets.7z a b c      # multiple inputs
ouch list archive.7z         # peek inside
```

## CLI: tar for Linux backups

`tar` preserves permissions, ownership, and symlinks; `-a`/`--zstd` pick the
compressor. This is the right tool for "back up this directory":

```sh
tar --zstd -cf backup.tar.zst dir/   # fast, great ratio (zstd)
tar -caf backup.tar.xz dir/          # smaller, slower (xz); -a = infer from ext
tar -xf backup.tar.zst               # extract (compressor auto-detected)
tar -tf backup.tar.zst               # list
```

## GUI: PeaZip

Launch it from the app launcher (`Mod+D`). PeaZip is the visual side: **browse an
archive's contents before extracting**, drag-and-drop in/out, built-in text / hex
/ image viewers, **split/join** (`.001`, `.002`…), **spanned** archives, and
password encryption — across 200+ formats, all on the same `7zz`/`zstd`/`brotli`
backends the CLI uses.

### Make double-click open PeaZip

PeaZip is standalone (not wired into a file manager), so associate the archive
MIME types with it once. After install:

```sh
for m in application/zip application/x-7z-compressed application/vnd.rar \
         application/x-tar application/gzip application/x-bzip2 \
         application/x-xz application/zstd \
         application/x-compressed-tar application/x-xz-compressed-tar \
         application/x-zstd-compressed-tar; do
    xdg-mime default org.peazip.PeaZip.desktop "$m"
done

xdg-mime query default application/x-7z-compressed   # verify
```

> [!NOTE]
> Confirm the desktop-entry name the package ships with
> `ls /usr/share/applications | grep -i peazip` — use that exact `.desktop` file
> in the loop above (it may be `peazip.desktop`). This writes to
> `~/.config/mimeapps.list`, which is intentionally **not** tracked in this repo
> (it holds machine-local default-app choices).

## Terminal file manager: Yazi

With `7zz` installed, [Yazi](https://yazi-rs.github.io/) can list and extract
archives from the keyboard. For inline **content preview** add an archive
previewer plugin (e.g. `ouch.yazi` / a `7z` previewer via `ya pkg`); the backends
it needs — `7zz`, `ouch` — are already here.

## Which format?

- **Share with Windows / mixed OS** → `.zip` (universal) or `.7z` (better ratio).
- **Linux backup, restore-faithful** → `.tar.zst` (fast) or `.tar.xz` (smallest).
- **Maximum compression** → `.7z -mx=9` or `.tar.xz`.
- **Speed over ratio** → `zstd` / `.tar.zst`.
- **Receiving `.rar`** → `unrar x` or `7zz x` (creating `.rar` needs proprietary
  `rar`; prefer `.7z`/`.zip` instead).

## References

- [7-Zip on ArchWiki](https://wiki.archlinux.org/title/7-Zip) ·
  [why 7zz, not p7zip](https://dev.to/lucifer1004/stop-using-p7zip-why-you-should-switch-to-7zz-on-linux-518j)
- [ouch](https://github.com/ouch-org/ouch)
- [PeaZip](https://github.com/peazip/PeaZip)
- [Arch: Archiving and compression tools](https://wiki.archlinux.org/title/Archiving_and_compression)
