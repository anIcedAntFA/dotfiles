# greetd — login manager

## Why

[greetd](https://sr.ht/~kennylevinsen/greetd/) is a minimal, compositor-agnostic
login daemon. Paired with [tuigreet](https://github.com/apognu/tuigreet) it gives
a clean text-UI login that launches Wayland sessions (like niri) — no heavy
display manager required.

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

## References

- [greetd wiki](https://man.sr.ht/~kennylevinsen/greetd/)
- [tuigreet](https://github.com/apognu/tuigreet)
