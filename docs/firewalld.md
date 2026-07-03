# firewalld — exposing a local dev server

## Why

By default your dev server (Vite, Next, etc.) is only reachable from the machine
itself. To open it to a phone or another computer on your LAN — for testing on
real devices — you must allow the port through the firewall.
[`firewalld`](https://firewalld.org/) is the zone-based firewall used here.

## Install & enable

```sh
yay -S --needed firewalld
sudo systemctl enable --now firewalld
```

## 1. Find your machine's LAN IP

```sh
ip a
```

Look for the `inet` line on your active interface (e.g. `enp0s31f6` or `wlan0`):

```text
inet 192.168.1.100/24 ... scope global ... enp0s31f6
```

Here the IP is `192.168.1.100`. Other devices reach your server at
`http://192.168.1.100:<port>`.

## 2. Open the port in your active zone

```sh
# Which zone is your interface in? (usually `public` or `home`)
sudo firewall-cmd --get-active-zones

# Permanently allow the port (example: Vite's 5173) in that zone
sudo firewall-cmd --permanent --zone=public --add-port=5173/tcp

# Apply
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --zone=public --list-ports   # -> 5173/tcp
```

> [!TIP]
> Bind your dev server to `0.0.0.0`, not `127.0.0.1`, or it still won't accept
> LAN connections. E.g. `vite --host`, `next dev -H 0.0.0.0`.

## Closing the port again

```sh
sudo firewall-cmd --permanent --zone=public --remove-port=5173/tcp
sudo firewall-cmd --reload
```

## References

- [firewalld zones explained](https://firewalld.org/documentation/zone/)
- [firewalld on Arch Wiki](https://wiki.archlinux.org/title/Firewalld)
