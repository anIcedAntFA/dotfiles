# Cài Arch thuần lên laptop (dual-boot Windows)

> **Runbook**: các bước cài lại box `laptop` từ EndeavourOS sang **Arch thuần từ
> ISO**, giữ nguyên Windows. Mỗi bước có một dòng _vì sao_; phần giải thích đầy
> đủ nằm ở tài liệu lý thuyết.
>
> - Cần **hiểu vì sao** (UEFI, GPT, ESP/XBOOTLDR, LUKS, initramfs, DHCP/DNS/mDNS) →
>   [`boot-disk-network-concepts.vi.md`](boot-disk-network-concepts.vi.md).
> - Cần **dữ kiện phần cứng + nguồn** → [research note](research/arch-install-ideapad-5-pro-14.md).
> - Guide này **dừng ở**: TTY có mạng + user/sudo + `yay` + `chezmoi init`. Từ đó
>   đi tiếp theo [Quick start trong README](../README.md#quick-start), rồi
>   [greetd.md](greetd.md) và [niri.md](niri.md).

## Máy và quyết định

| Mục            | Giá trị                                                                  |
| -------------- | ------------------------------------------------------------------------ |
| Máy            | Lenovo IdeaPad 5 Pro **14ACN6**, Ryzen 7 5800U, 16 GB, NVMe 1 TB         |
| GPU            | iGPU AMD Radeon (Cezanne) + **NVIDIA MX450** (Turing, `01:00.0`)         |
| Wi-Fi          | **MediaTek MT7921** (`mt7921e`), không có cổng RJ45                      |
| Dual-boot      | Windows giữ nguyên; chỉ cài lại phần Linux                               |
| Bootloader     | **systemd-boot**                                                         |
| `/efi`         | `nvme0n1p1`: ESP 100 MB của Windows, **không format**                    |
| `/boot`        | `nvme0n1p4`: XBOOTLDR 1 GiB, format lại **FAT32**                        |
| `/`            | `nvme0n1p5`: **LUKS2** → ext4                                            |
| Không đụng tới | `nvme0n1p2` (MSR), `nvme0n1p3` (`C:`), `nvme0n1p6` (WinRE, nằm cuối đĩa) |
| initramfs      | mkinitcpio, hook systemd + `sd-encrypt`, mở khoá bằng passphrase         |
| Kernel         | `linux` + `linux-lts` (LTS là entry dự phòng)                            |
| Swap           | chỉ zram, không hibernate                                                |
| Mạng           | NetworkManager + systemd-resolved                                        |
| Secure Boot    | tắt (bật lại bằng `sbctl` là việc của sau này)                           |

Trong guide, `<hostname>` và `<username>` là chỗ bạn điền giá trị thật. Giá trị
thật **không bao giờ** vào repo.

> [!WARNING]
> Số phân vùng ở trên lấy từ snapshot ngày cài. **Luôn chạy lại `lsblk` và so
> khớp cỡ + loại** trước mọi lệnh format. Format nhầm `p3` là mất Windows.

---

## Bước 0 — Bên Windows

_Vì sao:_ Windows phải nhả ổ NTFS và firmware phải ở bản mới nhất trước khi
động vào BIOS ([lý thuyết §3.4](boot-disk-network-concepts.vi.md)).

1. Mở **PowerShell (Admin)**:

   ```powershell
   manage-bde -status C:   # đã kiểm tra: Protection Off, BitLocker không bật
   powercfg /h off         # tắt hibernate + Fast Startup
   ```

2. **Update BIOS** từ GECN26WW lên **GECN39WW** (bản mới nhất lúc viết): tải
   gói BIOS cho 14ACN6 từ trang hỗ trợ Lenovo, **cắm sạc**, chạy `.exe`, để máy
   tự khởi động lại. Không tắt máy giữa chừng. Lenovo không hỗ trợ update BIOS
   từ Linux (fwupd không có thiết bị này), nên đây là lúc duy nhất tiện làm.
3. Rời Windows bằng **Restart**, không dùng Shut down.

## Bước 1 — Backup trên EndeavourOS cũ

_Vì sao:_ `p5` sẽ bị format. chezmoi chỉ giữ config, không giữ dữ liệu.

### 1.1 Checklist

| Cần giữ                                         | Ở đâu                                                      |
| ----------------------------------------------- | ---------------------------------------------------------- |
| SSH key, GPG key                                | `~/.ssh/`, `~/.gnupg/` → **thêm một bản trên USB**         |
| Giá trị riêng của chezmoi                       | `~/.config/chezmoi/chezmoi.toml`                           |
| Repo có commit chưa push / thay đổi chưa commit | `~/workspace/**` (xem lệnh 1.2)                            |
| Tài liệu, ảnh, download                         | `~/Documents`, `~/Pictures`, `~/Downloads`…                |
| Profile trình duyệt                             | `~/.zen/`, `~/.mozilla/`, `~/.config/google-chrome/`       |
| Dữ liệu app                                     | `~/.local/share/` (lịch sử fish, zoxide, gopass store…)    |
| Mật khẩu Wi-Fi đã lưu (cần root, chứa mật khẩu) | `/etc/NetworkManager/system-connections/` → **chỉ ra USB** |
| Bất cứ thứ gì cài ngoài pacman                  | xem [packages.md](packages.md#installed-outside-pacman)    |

### 1.2 Repo chưa push

Login shell là fish, còn vòng lặp dưới viết cho bash, nên chạy qua `bash -c`:

```sh
# In ra repo nào có thay đổi chưa commit, hoặc có commit chưa push
bash -c 'for d in $(ghq list -p); do
  git -C "$d" status --porcelain --branch | grep -qE "^[^#]|ahead" && echo "$d"
done'
```

`--porcelain --branch` in một dòng `## nhánh...origin/nhánh [ahead N]`, rồi mỗi
file thay đổi một dòng. Dòng không bắt đầu bằng `#` nghĩa là có thay đổi, còn
`ahead` nghĩa là có commit chưa push.

### 1.3 Đẩy sang box `home`

Box `home` không bật `sshd` thường trực. Bật **tạm thời** (`start`, không
`enable`) trên box `home`:

```sh
sudo systemctl start sshd        # trên box home; xong việc thì: sudo systemctl stop sshd
```

Rồi từ laptop:

```sh
rsync -aHAX --info=progress2 \
  --exclude '.cache/' --exclude 'node_modules/' --exclude '.local/share/Trash/' \
  ~/ <username>@<home-hostname>.local:laptop-backup/
```

- `-a` giữ quyền, thời gian, symlink; `-H` giữ hard link; `-A -X` giữ ACL và
  xattr.
- Box `home` trả lời tên `.local` qua Avahi. Nếu không phân giải được tên, dùng
  IP (`ip -4 addr` trên box `home`).
- `~/.ssh`, `~/.gnupg` và thư mục `system-connections` chép **thêm** ra USB:
  bản trên box `home` là bản thứ hai, không phải bản duy nhất.

### 1.4 Backup ESP

ESP chung với Windows. Một bản sao giúp cứu được Windows Boot Manager nếu lỡ tay:

```sh
sudo cp -a /boot/efi /run/media/<username>/<USB>/esp-backup   # EndeavourOS mount ESP ở /boot/efi
```

## Bước 2 — USB Ventoy (làm trên box `home`)

_Vì sao:_ ISO Arch phải được kiểm chữ ký trước khi dùng nó để format đĩa.

1. Tải `archlinux-<YYYY.MM.DD>-x86_64.iso`, `b2sums.txt` và `.iso.sig` từ
   [archlinux.org/download](https://archlinux.org/download/).
2. Kiểm tra (lệnh đầy đủ, kể cả bản Sequoia, nằm trong
   [research §3](research/arch-install-ideapad-5-pro-14.md#3-ventoy)):

   ```sh
   b2sum -c b2sums.txt --ignore-missing
   gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
   gpg --verify archlinux-*.iso.sig archlinux-*.iso
   ```

3. Cài Ventoy lên USB (**xoá sạch USB**; kiểm `/dev/sdX` bằng `lsblk` trước):

   ```sh
   sudo sh Ventoy2Disk.sh -i -g /dev/sdX   # -g: GPT
   ```

4. Chép ISO vào phân vùng `Ventoy` của USB.

## Bước 3 — BIOS

_Vì sao:_ ISO Arch không được ký, nên Secure Boot phải tắt ([lý thuyết §3.3](boot-disk-network-concepts.vi.md#33-secure-boot)).

1. Bật máy, bấm liên tục **F2** (hoặc nút Novo → BIOS Setup).
2. **Security → Secure Boot → Disabled** (đường dẫn có thể khác; Lenovo có
   [BIOS Simulator](https://download.lenovo.com/bsco/index.html) để xem trước).
3. Ghi nhớ mục **Fast Boot / Quick Boot** nếu có: chưa cần đổi, nhưng nó là thủ
   phạm số một nếu sau này menu systemd-boot không thấy entry Arch
   (**Gỡ lỗi**).
4. **F10** lưu. Khởi động lại, bấm **F12**, chọn USB, chọn ISO Arch trong menu
   Ventoy (chế độ thường).

## Bước 4 — Môi trường live: mạng và SSH

### 4.1 Kiểm tra chế độ boot

```sh
cat /sys/firmware/efi/fw_platform_size   # phải là 64
setfont ter-132b                         # tuỳ chọn: chữ to hơn trên màn 2.2K/2.8K
```

### 4.2 Lên mạng

**Cách dễ nhất:** cắm dongle USB-C Ethernet, hoặc bật **USB tethering** trên
Android. ISO tự xin DHCP, không cần gõ gì.

**Wi-Fi bằng `iwctl`:**

```sh
rfkill unblock wlan                          # nếu card bị soft-block (F8 là phím RF-kill)
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect "<SSID>"         # hỏi passphrase
ping -c 3 ping.archlinux.org
timedatectl                                  # chờ "System clock synchronized: yes"
```

_Vì sao đồng hồ:_ pacman kiểm chữ ký package, và chữ ký có thời hạn. Đồng hồ sai
thì mọi package đều "hết hạn".

### 4.3 Điều khiển qua SSH từ box `home`

Từ đây trở đi, mọi lệnh được **dán** từ terminal của box `home`.

```sh
passwd                                       # trên laptop: đặt mật khẩu root tạm cho ISO
```

```sh
# trên box home
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@archiso.local
```

_Vì sao hai cờ `-o`:_ ISO sinh host key mới mỗi lần boot. Không lưu nó vào
`known_hosts` thì lần sau boot lại ISO không bị cảnh báo giả mạo
([lý thuyết §8.8](boot-disk-network-concepts.vi.md)).

## Bước 5 — Đĩa

### 5.1 Xác định phân vùng

```sh
lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME,LABEL
```

So khớp với bảng ở đầu guide: `p1` ~100M `EFI System`, `p4` ~1G `Linux extended
boot`, `p5` ~468G `Linux filesystem` nhãn `endeavouros`. Khớp rồi mới đặt biến:

```sh
ESP=/dev/nvme0n1p1
BOOT=/dev/nvme0n1p4
ROOT=/dev/nvme0n1p5
```

_Vì sao dùng biến:_ kiểm tra **một lần**, sau đó mọi lệnh dùng tên biến. Gõ tay
`nvme0n1p3` thay vì `p5` ở lệnh format là sai lầm không sửa được.

Không cần sửa bảng phân vùng: `p4` đã có đúng loại XBOOTLDR, `p5` đúng loại
Linux. Chỉ format lại nội dung.

### 5.2 Mã hoá root bằng LUKS2

```sh
wipefs -a "$ROOT"                                  # xoá chữ ký ext4 cũ
cryptsetup luksFormat "$ROOT"                      # gõ YES (chữ hoa), rồi passphrase 2 lần
cryptsetup --allow-discards --persistent open "$ROOT" root
mkfs.ext4 -L arch /dev/mapper/root
```

- `luksFormat` mặc định là **LUKS2 + argon2id**. Passphrase nên dài (một câu
  vài từ), vì đó là thứ duy nhất đứng giữa kẻ trộm và dữ liệu.
- **Bàn phím lúc boot là layout `us`.** Đừng dùng ký tự mà layout khác gõ ra
  khác.
- `--allow-discards --persistent`: bật TRIM và **ghi cờ vào header**, nên mọi
  lần mở sau đều có TRIM, không cần tham số kernel
  ([lý thuyết §5.4](boot-disk-network-concepts.vi.md)).

Tuỳ chọn, nên làm: thêm một **passphrase dự phòng** (dài, sinh ngẫu nhiên, cất
trong gopass) vào keyslot thứ hai, và backup header:

```sh
cryptsetup luksAddKey "$ROOT"
cryptsetup luksHeaderBackup "$ROOT" --header-backup-file /root/luks-header.img
```

Rồi từ box `home` kéo header về, và cất **ngoài repo**:

```sh
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@archiso.local:/root/luks-header.img .
```

### 5.3 Format `/boot` thành FAT32

```sh
wipefs -a "$BOOT"
mkfs.fat -F 32 -n BOOT "$BOOT"
```

_Vì sao:_ systemd-boot chỉ đọc được filesystem mà firmware đọc được, tức là FAT.
GRUB của EndeavourOS tự mang driver ext4, systemd-boot thì không
([lý thuyết §4.3](boot-disk-network-concepts.vi.md)).

**Không format `$ESP`.** Windows Boot Manager sống trong đó.

### 5.4 Mount

```sh
mount /dev/mapper/root /mnt
mount --mkdir -o fmask=0077,dmask=0077 "$ESP"  /mnt/efi
mount --mkdir -o fmask=0077,dmask=0077 "$BOOT" /mnt/boot
```

`fmask/dmask=0077`: FAT không có quyền Unix, nên quyền được đặt lúc mount. Chỉ
root đọc được, vì ESP sẽ chứa `random-seed` của systemd-boot.

### 5.5 Dọn ESP và NVRAM

```sh
ls /mnt/efi/EFI          # mong đợi: BOOT  Microsoft  archcraft  endeavouros  fedora
df -h /mnt/efi           # xem còn trống bao nhiêu
rm -r /mnt/efi/EFI/fedora /mnt/efi/EFI/archcraft
efibootmgr               # đọc lại số hiệu, đừng tin snapshot cũ
efibootmgr -b 0001 -B    # Fedora
efibootmgr -b 0002 -B    # Fedora
efibootmgr -b 0005 -B    # archcraft
```

- **Không xoá** `Microsoft` và `BOOT`.
- **Chưa xoá** `endeavouros`: dọn nó sau khi Arch và Windows đều boot được
  (**Bước 9**).
- Phải xoá cả thư mục lẫn entry: entry chỉ là con trỏ tới file
  ([lý thuyết §3.2](boot-disk-network-concepts.vi.md)).

## Bước 6 — Cài hệ thống gốc

```sh
pacstrap -K /mnt \
  base linux linux-lts linux-firmware amd-ucode sof-firmware \
  cryptsetup dosfstools e2fsprogs efibootmgr \
  networkmanager openssh \
  sudo fish nano man-db man-pages texinfo terminus-font \
  base-devel git zram-generator \
  mesa vulkan-radeon nvidia-open nvidia-open-lts nvidia-prime
```

| Nhóm                                               | Vì sao                                                             |
| -------------------------------------------------- | ------------------------------------------------------------------ |
| `linux` `linux-lts`                                | Hai kernel: LTS là đường lui khi bản mới hỏng                      |
| `linux-firmware` `amd-ucode` `sof-firmware`        | Firmware thiết bị (Wi-Fi MT7921, GPU), microcode CPU, âm thanh     |
| `cryptsetup` `dosfstools` `e2fsprogs` `efibootmgr` | Công cụ cho LUKS, FAT, ext4, NVRAM                                 |
| `networkmanager` `openssh`                         | Mạng sau khi cài (cấu hình mạng trên ISO **không** được chép sang) |
| `sudo` `fish` `nano` `man-*` `terminus-font`       | Dùng được TTY: quyền admin, login shell, editor, man, font to      |
| `base-devel` `git`                                 | Để build `yay` từ AUR                                              |
| `zram-generator`                                   | Swap trên RAM ([zram.md](zram.md))                                 |
| `mesa` `vulkan-radeon`                             | Driver đồ hoạ của iGPU AMD                                         |
| `nvidia-open` `nvidia-open-lts` `nvidia-prime`     | Driver MX450 cho **từng** kernel + `prime-run`                     |

`nvidia-open` chỉ có module cho `linux`; `linux-lts` cần `nvidia-open-lts`. Thiếu
nó thì boot vào LTS sẽ không có dGPU.

```sh
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab       # 3 dòng: / (ext4), /efi và /boot (vfat, fmask=0077,dmask=0077)
```

## Bước 7 — Cấu hình trong chroot

```sh
arch-chroot -S /mnt
```

`-S` chạy chroot dưới một service tạm của systemd (`systemd-run`); đó là cách
guide chính thức hiện dùng. Shell trong chroot là **bash** và **không** nhớ các
biến `$ESP/$BOOT/$ROOT` ở ngoài, nên đặt lại:

```sh
ROOT=/dev/nvme0n1p5
```

### 7.1 Giờ, ngôn ngữ, bàn phím

```sh
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc
sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' -e 's/^#vi_VN UTF-8/vi_VN UTF-8/' /etc/locale.gen
locale-gen
```

`/etc/locale.conf`: giống [`etc/locale.conf`](../etc/locale.conf) của repo
(`LANG=en_US.UTF-8`, các `LC_*` khác là `vi_VN`):

```sh
cat > /etc/locale.conf <<'EOF'
LANG=en_US.UTF-8
LC_ADDRESS=vi_VN
LC_IDENTIFICATION=vi_VN
LC_MEASUREMENT=vi_VN
LC_MONETARY=vi_VN
LC_NAME=vi_VN
LC_NUMERIC=vi_VN
LC_PAPER=vi_VN
LC_TELEPHONE=vi_VN
LC_TIME=vi_VN
EOF
printf 'KEYMAP=us\nFONT=ter-132b\n' > /etc/vconsole.conf
```

_Vì sao `LANG` tiếng Anh:_ thông báo lỗi tiếng Anh thì search ra kết quả. Ngày
giờ, số, tiền tệ theo kiểu Việt Nam qua `LC_*`. `FONT=` là tuỳ chọn, chỉ để chữ
console đọc được trên màn độ phân giải cao (bỏ dòng đó nếu thấy chữ quá to).

### 7.2 Hostname

```sh
echo '<hostname>' > /etc/hostname
```

Chỉ chữ thường, số và `-`. Đây cũng là tên `.local` của máy trong LAN.

### 7.3 initramfs: thêm `sd-encrypt`

```sh
nano /etc/mkinitcpio.conf
```

Sửa dòng `HOOKS=` cho giống hệt:

```sh
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

Thường bản mặc định chỉ thiếu **`sd-encrypt`** (giữa `block` và `filesystems`).
Ý nghĩa và thứ tự của từng hook:
[lý thuyết §6.3](boot-disk-network-concepts.vi.md).

```sh
mkinitcpio -P            # tạo lại image cho mọi kernel (linux, linux-lts)
ls -lh /boot             # vmlinuz-linux, initramfs-linux.img, bản -lts tương ứng
```

### 7.4 systemd-boot

```sh
bootctl --esp-path=/efi --boot-path=/boot install
```

Lệnh này chép `systemd-bootx64.efi` vào ESP và tạo NVRAM entry **Linux Boot
Manager**, xếp nó lên đầu `BootOrder`. Bản cập nhật của systemd-boot về sau tự cài
khi gói `systemd` lên version (ESP ở `/efi` được dò tự động).

Cấu hình menu, nằm **trên ESP**:

```sh
cat > /efi/loader/loader.conf <<'EOF'
default  arch.conf
timeout  4
console-mode max
editor   no
EOF
```

`editor no`: không cho sửa kernel cmdline từ menu. Nếu để `yes`, ai cầm máy cũng
gõ được `init=/bin/sh` và vào root mà không cần mật khẩu.

Entry, nằm **trên XBOOTLDR** (`/boot`, cùng chỗ với kernel):

```sh
UUID=$(blkid -s UUID -o value "$ROOT")
echo "$UUID"             # phải in ra một UUID; rỗng là sai $ROOT

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options rd.luks.name=$UUID=root root=/dev/mapper/root rw zswap.enabled=0
EOF

cat > /boot/loader/entries/arch-lts.conf <<EOF
title   Arch Linux (LTS)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options rd.luks.name=$UUID=root root=/dev/mapper/root rw zswap.enabled=0
EOF

bootctl list             # phải thấy arch.conf, arch-lts.conf và auto-windows
```

- `$UUID` là UUID của **phân vùng LUKS**, không phải của ext4 bên trong.
- Không cần dòng `initrd /amd-ucode.img`: hook `microcode` đã nhúng microcode vào
  initramfs.
- `zswap.enabled=0` có sẵn từ đầu, vì máy dùng zram
  ([zram.md](zram.md#disable-zswap-arch-enables-it-by-default)).
- Windows **không cần entry**: systemd-boot tự thấy `\EFI\Microsoft\Boot\bootmgfw.efi`
  trên cùng ESP.

### 7.5 MX450: cho dGPU ngủ khi rảnh (RTD3)

```sh
cat > /etc/modprobe.d/nvidia-pm.conf <<'EOF'
options nvidia "NVreg_DynamicPowerManagement=0x02"
EOF

cat > /etc/udev/rules.d/80-nvidia-pm.rules <<'EOF'
# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
EOF
```

Lấy nguyên văn từ [ArchWiki PRIME#NVIDIA](https://wiki.archlinux.org/title/PRIME).
Turing cần `0x02`; Ampere trở lên mới mặc định bật. MX450 là thiết bị `3D
controller` (class `0x0302`), nên dòng thứ hai của mỗi cặp là dòng có tác dụng.
Hai file này chỉ dành cho laptop, nên ghi thẳng trong guide thay vì đặt vào
`etc/` của repo.

Không thêm module NVIDIA vào initramfs: màn hình do iGPU AMD vẽ
([lý thuyết §7](boot-disk-network-concepts.vi.md#7-gpu-lai-igpu-amd--mx450)).
`nvidia-utils` đã blacklist `nouveau`.

### 7.6 Dịch vụ

```sh
systemctl enable NetworkManager systemd-resolved systemd-timesyncd fstrim.timer
```

| Unit                | Vì sao                                                      |
| ------------------- | ----------------------------------------------------------- |
| `NetworkManager`    | Kết nối Wi-Fi/dây, cấp IP                                   |
| `systemd-resolved`  | DNS + mDNS; NetworkManager sẽ log lỗi liên tục nếu thiếu nó |
| `systemd-timesyncd` | Đồng bộ giờ qua NTP                                         |
| `fstrim.timer`      | TRIM hàng tuần, đi qua LUKS nhờ cờ `allow-discards`         |

`sshd` để sau, khi đã có user và key (**Bước 11**).

### 7.7 Root, user, sudo

```sh
passwd                                              # mật khẩu root
useradd -m -G wheel -s /usr/bin/fish <username>
passwd <username>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -c                                           # kiểm cú pháp; sudoers lỗi = mất sudo
```

_Vì sao vẫn đặt mật khẩu root:_ khi boot hỏng và systemd rơi vào **emergency
shell**, nó đòi mật khẩu root. Root bị khoá thì không vào được shell cứu hộ.

### 7.8 Rời chroot, khởi động lại

```sh
exit                                                          # ra khỏi chroot
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
umount -R /mnt
cryptsetup close root
reboot                                                        # rút USB khi màn hình tắt
```

Symlink `resolv.conf` phải tạo **từ ngoài** chroot: bên trong, file đó đang bị ISO
chiếm chỗ ([lý thuyết §8.4](boot-disk-network-concepts.vi.md)).

## Bước 8 — Nếu không boot được

Boot lại USB, rồi vào lại hệ thống đã cài để sửa:

```sh
cryptsetup open /dev/nvme0n1p5 root
mount /dev/mapper/root /mnt
mount -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/efi
mount -o fmask=0077,dmask=0077 /dev/nvme0n1p4 /mnt/boot
arch-chroot -S /mnt
# sửa, rồi: mkinitcpio -P / bootctl list
```

Các lỗi thường gặp nằm ở **Gỡ lỗi**.

## Bước 9 — Lần boot đầu

1. Menu systemd-boot hiện **Arch Linux**, **Arch Linux (LTS)**, **Windows Boot
   Manager**. Chọn Arch.
2. Gõ passphrase LUKS. Đăng nhập bằng `<username>` ở TTY.
3. Lên mạng:

   ```sh
   nmtui                              # menu: Activate a connection → chọn Wi-Fi
   # hoặc: nmcli device wifi connect "<SSID>" --ask
   ```

4. Kiểm tra từng mắt xích:

   ```sh
   bootctl status | head -20          # đúng ESP /efi, XBOOTLDR /boot
   cat /proc/cmdline                  # có rd.luks.name=… và zswap.enabled=0
   findmnt /efi /boot                 # cả hai đều vfat
   sudo dmsetup table root | grep -o allow_discards
   systemctl --failed                 # không có unit nào lỗi
   resolvectl query archlinux.org     # DNS chạy qua systemd-resolved
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # suspended = MX450 đang ngủ
   ```

5. **Thử Windows**: `reboot`, chọn Windows Boot Manager, vào được thì Restart về
   Arch.
6. **Thử LTS** một lần: chọn Arch Linux (LTS), gõ passphrase, đăng nhập.
7. Khi cả ba đều boot được, dọn nốt EndeavourOS:

   ```sh
   sudo rm -r /efi/EFI/endeavouros
   sudo efibootmgr                    # tìm số hiệu entry "endeavouros"
   sudo efibootmgr -b 0004 -B         # thay 0004 bằng số thật
   ```

## Bước 10 — `yay`, chezmoi và package list

### 10.1 Bootstrap `yay`

`yay` chỉ có trên AUR, nên build tay lần đầu:

```sh
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
less PKGBUILD                      # đọc trước khi build: AUR không được kiểm duyệt
makepkg -si                        # -s cài dependency qua pacman, -i cài gói vừa build
```

### 10.2 chezmoi

```sh
sudo pacman -S --needed chezmoi
chezmoi init https://github.com/anIcedAntFA/dotfiles.git
```

Trả lời prompt: `machine` = **`laptop`**, `installPackages` = **no**.

_Vì sao `no`:_ script cài package của chezmoi đưa nguyên `packages/pacman-explicit.txt`
cho `yay`. List đó chụp trên EndeavourOS, có 13 package không tồn tại trên Arch
thuần, nên cả lệnh sẽ fail. Nếu bạn chép lại `chezmoi.toml` từ backup, mở nó ra
kiểm `installPackages = false`.

### 10.3 Lọc package list cho Arch thuần

Các lệnh dưới dùng `<(…)` (process substitution) của **bash**; fish viết khác
(`(… | psub)`), nên chạy trong bash:

```bash
bash
cd ~/.local/share/chezmoi          # bản clone repo do chezmoi init tạo

# Có trong repo chính thức của Arch → giữ. EOS-only và AUR tự rơi ra.
comm -12 <(sort -u packages/pacman-explicit.txt) <(pacman -Slq | sort -u) \
  | grep -vxE 'dracut|grub|os-prober|intel-ucode|intel-media-driver|libva-intel-driver|vulkan-intel' \
  > /tmp/arch-native.txt

# Những gì bị loại, để chắc không mất thứ cần
comm -23 <(sort -u packages/pacman-explicit.txt) <(pacman -Slq | sort -u)

grep -vx 'slack-desktop-wayland' packages/aur.txt > /tmp/arch-aur.txt
```

Đọc từng mảnh:

- `pacman -Slq` liệt kê tên mọi package trong các repo đang bật.
- `comm` so hai danh sách **đã sort**: `-12` giữ dòng có ở cả hai, `-23` giữ dòng
  chỉ có ở danh sách đầu.
- `grep -vxE '…'` bỏ package của **box khác hoặc bootloader khác**: snapshot chụp
  trên một box Intel dùng GRUB + dracut, còn laptop là AMD dùng systemd-boot +
  mkinitcpio. `-v` đảo, `-x` khớp nguyên dòng.
- `slack-desktop-wayland` không còn trên AUR (xem
  [research §6](research/arch-install-ideapad-5-pro-14.md#6-endeavouros--plain-arch-differences-that-bite)).

Xem lại rồi cài:

```bash
less /tmp/arch-native.txt
sudo pacman -S --needed - < /tmp/arch-native.txt
yay -S --needed - < /tmp/arch-aur.txt
yay -S --needed downgrade          # chỉ nằm trong list EOS, không có trong aur.txt
exit                               # về fish
```

`downgrade` là đường lui khi một bản cập nhật làm hỏng gì đó: nó cài lại bản cũ từ
cache của pacman.

**Không** chép [`etc/pacman.conf`](../etc/pacman.conf) của repo sang laptop: nó có
repo `[endeavouros]`. Muốn có màu thì sửa `/etc/pacman.conf` bản Arch, bỏ dấu `#`
trước `Color`.

### 10.4 Áp config, rồi đi tiếp

```sh
chezmoi apply
```

Từ đây:

1. [zram.md](zram.md): chép hai file `etc/` và apply. Bỏ qua phần GRUB, vì
   `zswap.enabled=0` đã có trong entry systemd-boot.
2. [greetd.md](greetd.md), rồi [niri.md](niri.md).

## Bước 11 — Mạng trong nhà (LAN)

Phần này cũng dùng được cho box `home`: cả hai đều chạy NetworkManager.

### 11.1 `sshd` với key

Trên laptop:

```sh
sudo systemctl enable --now sshd
```

Trên box `home`, tạo một key riêng cho LAN và chép sang:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/lan -C lan
ssh-copy-id -i ~/.ssh/lan.pub <username>@<hostname>.local
ssh -i ~/.ssh/lan <username>@<hostname>.local      # phải vào được mà không hỏi mật khẩu
```

Khi key đã chạy, tắt đăng nhập bằng mật khẩu. Trên laptop:

```sh
sudo tee /etc/ssh/sshd_config.d/10-lan.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sudo sshd -t && sudo systemctl reload sshd
```

- `sshd` lấy **giá trị đầu tiên** nó gặp, và file trong `sshd_config.d/` được đọc
  theo thứ tự tên, nên `10-` thắng `99-archlinux.conf`.
- `sshd -t` kiểm cú pháp trước khi reload. Giữ phiên SSH đang mở, mở thêm phiên
  thứ hai để thử; hỏng thì còn phiên cũ để sửa.

### 11.2 Tên `.local` qua mDNS

systemd-resolved bật mDNS sẵn, nhưng NetworkManager phải bật nó **cho từng kết
nối**. Bật mặc định cho mọi kết nối:

```sh
sudo tee /etc/NetworkManager/conf.d/mdns.conf <<'EOF'
[connection]
connection.mdns=2
EOF
sudo systemctl restart NetworkManager
resolvectl status wlan0 | grep -i mdns     # mong đợi: +mDNS
```

`2` nghĩa là `yes` (phân giải **và** quảng bá tên). Từ box `home`:
`ping <hostname>.local`.

- Không cài thêm Avahi trên laptop: hai trình mDNS trên một máy tranh nhau cổng
  5353. Box `home` dùng Avahi thì không sao, vì đó là máy khác
  ([lý thuyết §8.5](boot-disk-network-concepts.vi.md)).
- Khi bật firewalld ([firewalld.md](firewalld.md)), mở mDNS (zone `public` đã cho
  `ssh` sẵn):

  ```sh
  sudo firewall-cmd --permanent --add-service=mdns && sudo firewall-cmd --reload
  ```

### 11.3 Địa chỉ cố định bằng DHCP reservation

1. Kiểm tra NetworkManager dùng **MAC thật** khi kết nối Wi-Fi nhà:

   ```sh
   nmcli -g 802-11-wireless.cloned-mac-address connection show "<SSID>"
   # rỗng, "preserve" hoặc "permanent" → ổn
   # "random" hoặc "stable" → sửa:
   sudo nmcli connection modify "<SSID>" 802-11-wireless.cloned-mac-address permanent
   ```

2. Lấy MAC: `ip link show wlan0` (dòng `link/ether`).
3. Trên trang quản trị router: mục **DHCP → Address Reservation / Static Lease**
   (tên khác nhau theo hãng), gán MAC đó với một IP ngoài dải cấp động.
4. Kết nối lại rồi kiểm tra:

   ```sh
   nmcli connection up "<SSID>"
   ip -4 addr show wlan0
   ```

Dongle Ethernet có MAC **riêng**. Muốn cố định cả khi cắm dây thì tạo thêm một
reservation cho MAC đó.

### 11.4 Mạng có dây (dongle USB-C, USB tethering)

Cắm vào là chạy: NetworkManager tự tạo kết nối "Wired connection 1" và xin DHCP.

```sh
nmcli device                # interface ethernet: connected
ip route                    # default via … dev enx… metric 100  ← dây thắng Wi-Fi (600)
```

Route metric nhỏ hơn thắng, nên cắm dây là traffic tự sang dây, rút ra thì tự về
Wi-Fi ([lý thuyết §8.6](boot-disk-network-concepts.vi.md)).
Box `home` có cổng Ethernet trên bo mạch và cũng dùng NetworkManager, nên mọi lệnh
ở đây áp dụng y nguyên.

### 11.5 Chế độ bảo vệ pin (giữ sạc ~60%)

Laptop cắm sạc gần như cả ngày thì nên giới hạn mức sạc. Kernel mới đưa tính năng
này về một file chuẩn. Tên pin có thể là `BAT0` hoặc `BAT1`
(`ls /sys/class/power_supply/`):

```sh
cat /sys/class/power_supply/BAT0/charge_types        # vd: Fast [Standard] Long_Life
echo Long_Life | sudo tee /sys/class/power_supply/BAT0/charge_types
```

Nếu file trên không tồn tại, dùng đường cũ (đã deprecated) của driver `ideapad_laptop`:

```sh
echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

Reboot rồi đọc lại. Nếu chế độ mất sau reboot, ghi lại lúc boot bằng `tmpfiles.d`:

```sh
echo 'w /sys/class/power_supply/BAT0/charge_types - - - - Long_Life' \
  | sudo tee /etc/tmpfiles.d/battery-conservation.conf
```

## Gỡ lỗi

| Triệu chứng                                           | Nguyên nhân thường gặp → cách sửa                                                                                                                                                                   |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ISO dừng ở "device did not show up after 30 seconds"  | Ventoy cũ. Update USB bằng `Ventoy2Disk.sh -u`, thử cổng USB khác, hoặc ghi ISO thẳng bằng `dd`                                                                                                     |
| Menu systemd-boot không có entry Arch, chỉ có Windows | Firmware **Fast Boot** bỏ qua phân vùng ngoài ESP → tắt trong BIOS. Kiểm `bootctl list` từ ISO + chroot                                                                                             |
| Máy vào thẳng Windows, không hiện menu                | `BootOrder` bị đổi (BIOS update, Windows Update) → đưa **Linux Boot Manager** lên đầu trong BIOS, hoặc `sudo efibootmgr -o <số-Linux>,<số-Windows>`                                                 |
| Passphrase đúng mà không mở được                      | Layout bàn phím. Lúc boot là `us`; kiểm `keyboard` + `sd-vconsole` trong `HOOKS` và `KEYMAP=us`                                                                                                     |
| "Timed out waiting for device /dev/mapper/root"       | Sai UUID trong entry (lấy nhầm UUID ext4) hoặc thiếu `sd-encrypt` → **Bước 8**, sửa entry, `mkinitcpio -P`                                                                                          |
| Wi-Fi ping giật, độ trễ cao                           | ASPM của MT7921 → `echo 'options mt7921e disable_aspm=1' \| sudo tee /etc/modprobe.d/mt7921e.conf`, reboot. Tốn pin hơn chút                                                                        |
| Gập nắp xong máy tự thức dậy ngay                     | Máy chỉ có `s2idle`. Xem `journalctl -b -1` quanh lúc suspend. Cách bật S3 qua BIOS ẩn có trong [research §1.3](research/arch-install-ideapad-5-pro-14.md#13-linux-quirks), ngoài phạm vi guide này |
| Touchpad chậm vài phút sau khi resume                 | Lỗi đã biết của model này (ArchWiki Laptop/Lenovo). Chờ, hoặc reload module `i2c_hid_acpi`                                                                                                          |
| `runtime_status` của MX450 luôn là `active`           | Có process giữ dGPU (`nvidia-smi` để xem). Nếu không có gì mà vẫn không ngủ, ArchWiki gợi ý thêm `NVreg_EnableGpuFirmware=0`                                                                        |

## Phụ lục A — archinstall

Cùng kết quả, ít thấy hơn. Nếu dùng (bản 4.5 trên ISO), chọn:

- **Disk configuration → Manual partitioning:** `p1` mount `/efi`, **không
  format**; `p4` mount `/boot`, format FAT32; `p5` mount `/`, format ext4, bật
  **Disk encryption**. Không đụng `p2`, `p3`, `p6`. Manual partitioning của
  archinstall không kiểm chồng lấn hay căn lề, nên đọc kỹ trước khi xác nhận.
- **Bootloader:** Systemd-boot, **không** UKI (UKI nằm trên ESP, mà ESP chỉ 100 MB).
- **Kernels:** `linux` + `linux-lts`.
- **Profile: Minimal.** **Không** chọn profile `niri`: nó kéo theo lightdm và
  waybar, đụng với greetd và Noctalia của repo.
- **Network configuration:** NetworkManager (default backend).

Sau đó làm tiếp từ **Bước 7.5** (RTD3),
kiểm `HOOKS` và entry có `zswap.enabled=0`. Việc archinstall xử lý đúng bố cục
ESP `/efi` + XBOOTLDR `/boot` **chưa được kiểm chứng** trên máy này.

## Phụ lục B — Việc tiếp theo, chưa làm

- **Secure Boot với khoá tự ký** (`sbctl`), kèm **UKI** (kernel + initramfs +
  cmdline trong một file ký được) và **mở khoá LUKS bằng TPM2**. Viết khi đã làm
  thật, để guide không có bước chưa kiểm chứng. UKI cần chỗ trên ESP, nên phải
  tính lại chuyện ESP 100 MB.
- **Home lab:** hành vi khi gập nắp, chạy headless, Docker, mở port firewall.
- **btrfs + snapshot**, nếu có lúc cần rollback cả hệ thống thay vì từng package.

## Tham khảo

- [ArchWiki — Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [ArchWiki — systemd-boot (XBOOTLDR)](https://wiki.archlinux.org/title/Systemd-boot) ·
  [EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition)
- [ArchWiki — dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
- [ArchWiki — PRIME](https://wiki.archlinux.org/title/PRIME) ·
  [Lenovo IdeaPad 5 Pro 14ACN6](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6)
- [ArchWiki — NetworkManager](https://wiki.archlinux.org/title/NetworkManager) ·
  [systemd-resolved](https://wiki.archlinux.org/title/Systemd-resolved) ·
  [Install Arch Linux via SSH](https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH)
- Dữ kiện và nguồn cho máy này: [research note](research/arch-install-ideapad-5-pro-14.md)
