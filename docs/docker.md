# Docker

## Why

[Docker](https://www.docker.com/) runs apps in isolated containers so a project's
runtime, dependencies, and services (databases, queues…) are reproducible and
don't pollute the host. This setup uses the native Arch `docker` engine (not
Docker Desktop) plus [`lazydocker`](https://github.com/jesseduffield/lazydocker)
for a terminal UI.

## Install

```sh
yay -S --needed docker docker-compose docker-buildx lazydocker
```

## Enable the daemon & run as non-root

```sh
# Start now and on every boot
sudo systemctl enable --now docker.service

# Let your user run docker without sudo (adds you to the `docker` group)
sudo usermod -aG docker "$USER"

# Refresh the group for the current shell (avoids a full logout/login)
newgrp docker

# Verify
docker run --rm hello-world
```

> [!WARNING]
> Adding your user to the `docker` group grants root-equivalent access to the
> host. That's the standard trade-off for daemon-based Docker — only do it on a
> machine you trust. Rootless Docker is the alternative if you'd rather not.

## Recommended daemon config

Create `/etc/docker/daemon.json` to enable BuildKit and cap log growth (this repo
ships a copy at [`etc/docker/daemon.json`](../etc/docker/daemon.json) —
`sudo cp etc/docker/daemon.json /etc/docker/`):

```json
{
  "features": { "buildkit": true },
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "3" },
  "storage-driver": "overlay2"
}
```

Then restart:

```sh
sudo systemctl restart docker.service
```

- **buildkit** — faster, cache-efficient builds.
- **log-opts** — without a cap, container JSON logs can silently fill the disk.
- **overlay2** — the recommended storage driver on modern kernels/filesystems.

## References

- [Docker on Arch Wiki](https://wiki.archlinux.org/title/Docker)
- [daemon.json reference](https://docs.docker.com/reference/cli/dockerd/)
- [Exposing a dev server to your LAN](firewalld.md)
