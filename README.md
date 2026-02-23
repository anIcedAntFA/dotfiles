# Linux Setup

![desktop screenshot](./images/desktop-screenshot-01.png)

![desktop screenshot](./images/desktop-screenshot-02.png)

![desktop screenshot](./images/desktop-screenshot-03.png)

## Table of Contents

- [Linux Setup](#linux-setup)
	- [Table of Contents](#table-of-contents)
	- [Introduction](#introduction)
	- [Contents](#contents)
		- [Dependencies](#dependencies)
		- [i3 configs](#i3-configs)
		- [Shell configs](#shell-configs)
		- [Applications](#applications)
	- [User guide](#user-guide)
		- [Setup Docker](#setup-docker)
		- [Public Port](#public-port)
			- [1. Find Your Local IP Address](#1-find-your-local-ip-address)
			- [2. Configure firewalld to Allow Incoming Connections](#2-configure-firewalld-to-allow-incoming-connections)
	- [Credits](#credits)

## Introduction

✨ This is my Linux setup and _dotfiles_. **Feel free** to use it 🚀🚀🚀.

<br>

> [!WARNING]
>
> - This is the setting for my personal _laptop_. It may be different if used for a _PC_ or other devices.
> - **Be careful** when copy all settings unless you know what that entails, just read information **in detail** for each repository.

<br>

📝 Basically, I use:

<details>
  <summary>🪐 <a href="https://endeavouros.com/">EndeavourOS</a> - An Arch-based Linux distribution.</summary>

- Download [ISO file](https://github.com/endeavouros-team/EndeavourOS-ISO).
- Dual boots with [Ventoy](https://github.com/ventoy/Ventoy).
  ![Desktop screenshot](./images/ventoy-disk-screenshot.png)

</details>

<details>
  <summary>
  🛠️ <a href="https://github.com/Jguer/yay">yay</a> - Arch Linux AUR helper tool.
  </summary>

- With _yay_ you can easily install, update and manage your packages.
- Here is an example when using _yay_ to install VS Code.
  ![Desktop screenshot](./images/yay-install-screenshot.png)

</details>

<details>
  <summary>
    🤯 <a href="https://github.com/niri-wm/niri">Niri</a> - A scrollable-tiling Wayland compositor.
  </summary>
</details>

<details>
  <summary>
  🛠️ <a href="https://github.com/noctalia-dev/noctalia-shell">Noctalia Shell</a> - A sleek and minimal desktop shell thoughtfully crafted for Wayland.
  </summary>
</details>

<br />

🥳 Many thanks to my colleagues at **NDVN** for inspiring me and guiding me towards _Linux_. You guys are amazing and kind.

[`⬆ BACK TO TOP ⬆`](#table-of-contents)

## Contents

### Dependencies

```sh
yay -S [package-name]
```

Here is a list of packages:

`extra/wezterm` `tmux` `extra/neofetch` `extra/brightnessctl` `picom-git` `polybar` `fish` `extra/fisher` `git` `peco` `neovim` `eza` `starship` `htop` `redshift` `ttf-jetbrains-mono-nerd` `extra/noto-fonts-emoji` `nitrogen` `betterlockscreen` `flameshot` `visual-studio-code-bin` `jetbrains-toolbox` `docker` `docker-compose` `go` `i3lock-color` `arttime-git` `rofi-bluetooth-git` `extra/blueman` `network-dmenu-git` `appimagelauncher` `postman-bin` `firefox-developer-edition` `google-chrome` `microsoft-edge-dev-bin` `teams` `slack-desktop` `aur/prospect-mail` `extra/discord` `extra/telegram-desktop` `obsidian` `extra/calc` `aur/networkmanager-dmenu-git`

`rate-mirrors-bin` `ghostty` `ghq` `waterfox-bin` `wlsunset` `cliphist` `fish` `fisher` `peco`

[`⬆ BACK TO TOP ⬆`](#table-of-contents)

- niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk alacritty
  - dms-shell-bin matugen cava qt6-multimedia-ffmpeg
  - noctalia-shell
  - xdg-desktop-portal-wlr
- ghostty, ghostty-cursor-shaders, visual-studio-code-bin
- neovim, neovim
  - tumbler, ffmpegthumbnailer
  - nwg-look, papirus-icon-theme, bibata-cursor-theme-bin, banana-cursor-bin, papirus-folders-git
    - `papirus-folders -C cat-latte-peach --theme Papirus-Light`
    - `papirus-folders -C dracula-orange --theme Papirus-Dark`
- waterfox, google-chrome, teams-for-linux-bin, slack-desktop-wayland
  - `sudo ln -s /opt/teams-for-linux/teams-for-linux-bin /usr/local/bin/teams-for-linux`
- rate-mirrors
- ttf-jetbrains-mono-nerd, noto-fonts-emoji
- greetd, greetd-tuigreet
  - /etc/greetd/config.toml
  - /etc/default/grub
    - `sudo nano /etc/default/grub`
    - `GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 loglevel=3 nowatchdog nvme_load=YES"`
    - `sudo grub-mkconfig -o /boot/grub/grub.cfg`
- /etc/hosts
- /etc/ca-certificates/trust-source/anchors/cert_vn_ssl_cert.crt
- fastfetch, swaylock, wlsunset, cliphist, btop
- ghq
- ssh-keygen:
  - add github, gitlab
  - create config file for ssh
- .gitconfig, .gitconfig-company
- fcitx5, fcitx5-configtool, fcitx5-bamboo
- fish, fisher, z for fish, dracula/fish, catppuccin/fish
- eza, starship, peco
- discord, mpv
- docker, docker-compose, docker-buildx, lazydocker
- mise, node, yarn, pnpm, wrangler
  - turbo
  - direnv
- go, rust
- dos2unix, curlie, yazi, bat, tree
- satty
  - .local/bin/dot-screenshot
- gpu-screen-recorder
- zathura
- postman-bin
- globalprotect-openconnect-git
- jetbrains-toolbox
- jq

### i3 configs

- [weztem](https://wezfurlong.org/wezterm/index.html) - A cross-platform terminal emulator and multiplexer.
- [betterlockscreen](https://github.com/betterlockscreen/betterlockscreen) - 🍀 sweet looking lockscreen for linux system

[`⬆ BACK TO TOP ⬆`](#table-of-contents)

### Shell configs

- [fish](https://github.com/fish-shell/fish-shell) - The user-friendly command line shell.
- [fisher](https://github.com/jorgebucaran/fisher) - A plugin manager for Fish.
- [dracula-fish](https://github.com/dracula/fish) - Dark theme for fish.
- [z for fish](https://github.com/jethrokuan/z) - Pure-fish z directory jumping.
- [ghq](https://github.com/x-motemen/ghq) - Remote repository management made easy.
- [peco](https://github.com/peco/peco) - Simplistic interactive filtering tool.
- [volta](https://volta.sh/) - The Hassle-Free JavaScript Tool Manager.
- [eza](https://github.com/eza-community/eza) - A modern, maintained replacement for ls.
- [starship](https://starship.rs/) - The minimal, blazing-fast, and infinitely customizable prompt for any shell!
- [go](https://go.dev/)
- [rust](https://www.rust-lang.org/)

[`⬆ BACK TO TOP ⬆`](#table-of-contents)

### Applications

## User guide

### Setup Docker

```sh
sudo systemctl status docker

# Bật và khởi chạy docker service ngay lập tức
sudo systemctl enable --now docker.service

# Thêm user hiện tại ($USER) vào group docker
sudo usermod -aG docker $USER

# Cập nhật lại group cho session hiện tại (để không cần logout/login lại)
newgrp docker
```

```sh
sudo nvim /etc/docker/daemon.json

{
  "features": {
    "buildkit": true
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

```sh
sudo systemctl restart docker.service
```

### Public Port

#### 1. Find Your Local IP Address

Other devices on your network will need your computer's local IP address.
Open your terminal and use either `ip a` or `ifconfig` (if you have `net-tools` installed):

```sh
ip a
```

Example output:

```sh
2: enp0s31f6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
  link/ether aa:bb:cc:dd:ee:ff brd ff:ff:ff:ff:ff:ff
  inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic noprefixroute enp0s31f6
  valid_lft 86241sec preferred_lft 86241sec
```

In this example, your IP is `192.168.1.100`.

#### 2. Configure firewalld to Allow Incoming Connections

1. **Start and Enable `firewalld` service (if not already running):**
   First, confirm the `firewalld` service is running and enabled to start on boot:

   ```sh
   sudo systemctl status firewalld
   ```

   If it's not running or not enabled, use:

   ```sh
   sudo systemctl enable firewalld --now
   ```

2. **Determine your active zone:**
   `firewalld` uses zones to define trust levels. Common zones are `public`, `home`, `internal`.
   To see which zone your `enp4s0` interface is assigned to:

   ```sh
   sudo firewall-cmd --get-active-zones
   ```

   You will likely see `public` or home associated with your `enp4s0` interface. Let's assume it's `public` for the next steps.

3. **Add the port to your active zone:**
   You need to permanently add the port `5173` (TCP) to the zone your `enp4s0` interface is in. Replace `your-active-zone` with the actual zone name (e.g., `public`, `home`).

   ```sh
   sudo firewall-cmd --permanent --zone=your-active-zone --add-port=5173/tcp
   ```

   For example, if your active zone is `public`:

   ```sh
   sudo firewall-cmd --permanent --zone=public --add-port=5173/tcp
   ```

4. **Reload `firewalld` to apply changes:**

   ```sh
   sudo firewall-cmd --reload
   ```

5. **Verify the rule:**
   You can list the ports allowed in your zone to confirm the rule was added:

   ```sh
   sudo firewall-cmd --zone=your-active-zone --list-ports
   ```

   You should see `5173/tcp` in the output.

## Credits

This config has heavy inspiration from:

- [devaslife](https://github.com/craftzdog/dotfiles-public) - Takuya Matsuyama
- [mantran1611](https://github.com/manhtran1611/dotfiles) - Manh Tran
- [lazarus2019](https://github.com/lazarus2019) - Thai Son

[`⬆ BACK TO TOP ⬆`](#table-of-contents)
