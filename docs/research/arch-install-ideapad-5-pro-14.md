# Reinstalling the IdeaPad 5 Pro 14 (2021) with plain Arch from a Ventoy USB

Research note, investigated 2026-10-16. Question: what does it take to wipe
the EndeavourOS "no desktop" install on the Lenovo IdeaPad 5 Pro 14 (2021) and
put plain Arch Linux on it from the official ISO booted off a Ventoy USB, with
no desktop environment (niri + Noctalia and chezmoi come later)? The variant
is not known yet, so both are covered. The owner finds CLI-only networking
intimidating, so networking gets the most detail.

Method: primary sources only. That means Lenovo PSREF spec sheets and Lenovo's
own driver and BIOS listings, the ArchWiki, archlinux.org (download page,
package database, news), the archiso and archinstall sources, ventoy.net docs
plus the Ventoy GitHub repo, kernel sources, and EndeavourOS's own repos for
EndeavourOS claims. PSREF and Lenovo support pages render with JavaScript, so
they were read through the JSON APIs those pages call and through the PSREF
PDF spec sheets. Package versions are what the Arch package database and the
`2026.10.01` ISO package list showed on 2026-10-16. Anything not seen in a
primary source is marked **unverified**. Statements marked _inference_ are my
own conclusions, not quotes.

## Summary

**The variant names are slightly off.** PSREF has no "IdeaPad 5 Pro 14ACH5": a
request for its spec PDF returns 404. The two 2021 14-inch models are:

- **14ACN6** (type 82L7): AMD Ryzen 5 5600U / Ryzen 7 5800U, which are
  **U-series, not H-series**.
- **14ITL6** (type 82L3): Intel Core i5-1135G7 / i5-1155G7 / i7-1165G7 /
  i7-1195G7.

Ryzen 5000**H** with "ACH6" in the name is the 16-inch
**IdeaPad 5 Pro 16ACH6** ([PSREF 16ACH6 PDF](https://psref.lenovo.com/syspool/Sys/PDF/IdeaPad/IdeaPad_5_Pro_16ACH6/IdeaPad_5_Pro_16ACH6_Spec.pdf)).
The sticker under the laptop, or `cat /sys/class/dmi/id/product_name` on the
current EndeavourOS install, settles which model it is.

**Wi-Fi chip per variant.** PSREF only gives the class ("802.11ac 2x2" or "Wi-Fi
6 802.11ax 2x2, M.2 card"). Lenovo's driver downloads show which chip vendors
were fitted:

- **14ACN6:** Intel, Qualcomm Atheros, **Realtek RTL8852AE** or **MediaTek
  MT7921**. The ArchWiki page for this model lists units seen with **Intel
  AX200** (`8086:2723`) and **MediaTek** (`14c3:7961`).
- **14ITL6:** Intel ("Intel Wi-Fi 6" in PSREF), **Realtek RTL8822CE** or
  **Realtek RTL8852AE**.

All of these have in-kernel drivers, and their firmware ships in
`linux-firmware-{intel,realtek,mediatek,atheros}`. All four packages are on the
2026.10.01 ISO, so Wi-Fi should work on the live ISO and on the installed
system with no extra steps (_inference_ from the package lists). `lspci -k` on
the current install shows which chip is actually fitted.

**No RJ45.** Both PSREF sheets say "No onboard Ethernet". There are two USB-C
3.2 Gen 1 ports. Both carry data and PD 3.0; only one also carries DisplayPort
1.4. A USB-C Ethernet dongle or Android USB tethering is the wired fallback, and
the ISO configures it by DHCP automatically.

**Secure Boot.** The Arch ISO does not support Secure Boot (ArchWiki). Ventoy can
boot with Secure Boot on after a one-time MOK enrolment of its key, and its
default policy then "fully bypass[es] secure boot", so the unsigned Arch ISO
would probably boot through it. The installed Arch system would still not boot
until Secure Boot is set up (sbctl, etc.). **Verdict:** disable Secure Boot in
the BIOS (F2) before starting. It is simpler, and the ArchWiki page for this
exact model says to do it.

**archinstall.** Version **4.5** is on the 2026.10.01 ISO (released
2026-09-29). Its network menu offers "Copy ISO network configuration",
"NetworkManager (default backend)", "NetworkManager (iwd backend)", "standalone
iwd" and "Manual". The default bootloader on UEFI is systemd-boot. It even has
a `niri` profile. **Verdict:** it is fine for this machine, with "Minimal" plus
NetworkManager. Two warnings apply: the ArchWiki notes that archinstall uses
"different defaults than the regular installation process", and its manual
partitioning has no overlap or alignment checks. The manual guide is about 15
commands and is the better route if the reinstall is also meant to be learned
(it feeds the blog).

**Top EndeavourOS-to-Arch gotchas.**

1. Arch uses **mkinitcpio** by default. EndeavourOS uses **dracut** plus
   `eos-dracut` (GRUB) or `kernel-install-for-dracut` (systemd-boot).
2. **13 packages** in `packages/pacman-explicit.txt` exist in neither the Arch
   repos nor the AUR: `endeavouros-{branding,keyring,mirrorlist}`,
   `eos-{apps-info,dracut,hooks,log-tool,packagelist,quickstart,rankmirrors}`,
   `nvidia-hook`, `welcome` and `slack-desktop-wayland`. 16 more come from the
   AUR, `yay` and `downgrade` included. A plain `pacman -S - < pacman-explicit.txt`
   will fail.
3. **yay** is AUR-only and has to be bootstrapped with `git` + `base-devel` +
   `makepkg -si`.
4. EndeavourOS's GRUB defaults (`nowatchdog nvme_load=YES`,
   `GRUB_EARLY_INITRD_LINUX_STOCK=""`, EndeavourOS splash) and `nvidia-hook` do
   not exist on Arch. On Arch the NVIDIA packages are already
   `nvidia-open`.

**Easiest path for someone wary of the CLI.** Get online on the ISO in one of
two ways: (a) plug in a USB-C Ethernet dongle or USB-tether an Android phone,
both of which configure themselves; or (b) run four `iwctl` commands. Then set a
root password and **SSH in from another computer** as `root@archiso.local`. From
there, copy-paste the install from this note. On the installed system, use
**NetworkManager** and its `nmtui` menu.

## 1. Hardware per variant

### 1.1 Spec comparison (PSREF)

Sources: the [14ACN6 spec PDF](https://psref.lenovo.com/syspool/Sys/PDF/IdeaPad/IdeaPad_5_Pro_14ACN6/IdeaPad_5_Pro_14ACN6_Spec.pdf)
(dated June 16 2023) and the [14ITL6 spec PDF](https://psref.lenovo.com/syspool/Sys/PDF/IdeaPad/IdeaPad_5_Pro_14ITL6/IdeaPad_5_Pro_14ITL6_Spec.pdf)
(dated November 21 2022). Two model-level records, read through PSREF's
`/api/model/Info/SpecData` endpoint, confirm the per-SKU WLAN wording:
[82L7008PSC](https://psref.lenovo.com/Detail/IdeaPad/IdeaPad_5_Pro_14ACN6?M=82L7008PSC)
("11ac 2x2 + BT5.1") and
[82L30047ID](https://psref.lenovo.com/Detail/IdeaPad/IdeaPad_5_Pro_14ITL6?M=82L30047ID)
("Wi-Fi 6, 11ax 2x2 + BT5.1").

| Item               | 14ACN6 (82L7)                                                                                       | 14ITL6 (82L3)                                                                     |
| ------------------ | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| CPU                | Ryzen 5 5600U (6C/12T) or Ryzen 7 5800U (8C/16T)                                                    | i5-1135G7, i5-1155G7, i7-1165G7, i7-1195G7 (all 4C/8T)                            |
| iGPU               | AMD Radeon Graphics                                                                                 | Intel Iris Xe                                                                     |
| dGPU option        | NVIDIA GeForce MX450 2GB GDDR6                                                                      | NVIDIA GeForce MX450 2GB GDDR6                                                    |
| RAM                | 8 or 16 GB DDR4-3200, soldered, "not upgradable"                                                    | same                                                                              |
| Storage            | "One drive, up to 512GB M.2 2242 SSD or 1TB M.2 2280 SSD", PCIe 3.0 x4 NVMe                         | same                                                                              |
| Display            | 2.2K 2240x1400 300 nits (matte or touch), or **2.8K 2880x1800 IPS 400 nits 90Hz**, 16:10, 100% sRGB | 2.2K 300 nits or **2.8K 400 nits 90Hz** (no touch option)                         |
| Ethernet           | **"No onboard Ethernet"**                                                                           | **"No onboard Ethernet"**                                                         |
| WLAN + BT          | "802.11ac 2x2 Wi-Fi + Bluetooth 5.1, M.2 card" or "Wi-Fi 6, 802.11ax 2x2 … M.2 card"                | "Wi-Fi 6, 802.11ax 2x2 Wi-Fi + Bluetooth 5.1, M.2 card" (note: "Intel Wi-Fi 6 …") |
| Audio              | HD Audio, Realtek ALC3287 codec, 2x 2 W speakers, dual-mic array                                    | same codec                                                                        |
| Camera             | HD 720p + IR, ToF sensor                                                                            | same                                                                              |
| Keyboard backlight | LED backlight or none (per SKU)                                                                     | same                                                                              |
| Touchpad           | Buttonless Mylar, Precision TouchPad (PTP)                                                          | same                                                                              |
| Battery / charger  | 56.5 Wh; 65 W USB-C PD 3.0                                                                          | same                                                                              |
| Security           | Firmware TPM 2.0; no fingerprint reader                                                             | same                                                                              |
| External displays  | HDMI up to 4096x2160@24Hz; USB-C up to 7680x4320@30Hz                                               | HDMI up to 3840x2160@30Hz; USB-C up to 3840x2160@60Hz                             |

**Ports (identical on both):** "1x USB 3.2 Gen 1", "1x USB 3.2 Gen 1 (Always
On)", "1x USB-C 3.2 Gen 1 (support data transfer, Power Delivery 3.0 and
DisplayPort 1.4)", "1x USB-C 3.2 Gen 1 (support data transfer and Power
Delivery 3.0)", "1x HDMI 1.4b", card reader (SD/SDHC/SDXC/MMC) and a 3.5 mm
combo jack. The overview diagram labels port 4 (left side, next to HDMI)
"USB-C 3.2 Gen 1 (data transfer / PD 3.0 only)" and port 6 plain "USB-C 3.2 Gen
1". So **the DisplayPort-capable USB-C is the one further from the hinge**
(_inference_ from the diagram numbering). There is a **NOVO button hole** on the
left edge. Both USB-C ports can take a USB-C Ethernet dongle or the PD
charger.

### 1.2 Which Wi-Fi chip, and does it work

PSREF never names the chip. Lenovo's own support API
(`pcsupport.lenovo.com/us/en/api/v4/downloads/drivers?productId=…`, which feeds
the [14ACN6 driver list](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/5-series/ideapad-5-pro-14acn6/downloads/driver-list)
and the [14ITL6 driver list](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/5-series/ideapad-5-pro-14itl6/downloads/driver-list))
lists these WLAN packages:

- **14ACN6:** "Intel WLAN Driver" (version 22.170.0.3) and "WLAN Driver
  (Atheros, Realtek, Mediatek)" with versions
  `Atheros_12.0.0.1016, RTL8852AE_6001.0.10.332, MT7921_22.30.1.1340`.
- **14ITL6:** "Intel WLAN Driver" (22.170.0.3) and "Realtek WLAN Driver" with
  version `8822CE 2024.0.8.129_8852AE 6001.0.10.306`.

The Intel package covers several Intel cards, so the exact Intel model is
**unverified** from Lenovo's side. For the 14ACN6, the
[ArchWiki model page](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6)
lists "Wireless (Intel AX200) `8086:2723` Yes" and "Wireless (MediaTek)
`14c3:7961` Yes" ("All hardware works out of the box as tested with kernel
5.17").

| Chip (variant)                | Linux driver           | Firmware in Arch package (file seen in the package file list)                                                                            | Live ISO / installed |
| ----------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| Intel AX200 (ACN6)            | `iwlwifi`              | [`linux-firmware-intel`](https://archlinux.org/packages/core/any/linux-firmware-intel/files/): `iwlwifi-cc-a0-77.ucode`                  | works (ArchWiki)     |
| Intel Wi-Fi 6 (ITL6)          | `iwlwifi`              | `linux-firmware-intel` (exact card **unverified**)                                                                                       | expected to work     |
| MediaTek MT7921 (ACN6)        | `mt7921e`              | [`linux-firmware-mediatek`](https://archlinux.org/packages/core/any/linux-firmware-mediatek/files/): `WIFI_MT7961_patch_mcu_1_2_hdr.bin` | works (ArchWiki)     |
| Realtek RTL8852AE (both)      | `rtw89` (8852AE)       | [`linux-firmware-realtek`](https://archlinux.org/packages/core/any/linux-firmware-realtek/files/): `rtw89/rtw8852a_fw.bin`               | expected to work     |
| Realtek RTL8822CE (ITL6)      | `rtw88` (8822CE)       | `linux-firmware-realtek`: `rtw88/rtw8822c_fw.bin`                                                                                        | expected to work     |
| Qualcomm Atheros (ACN6, 11ac) | `ath10k` (_inference_) | [`linux-firmware-atheros`](https://archlinux.org/packages/core/any/linux-firmware-atheros/files/): `ath10k/QCA6174/…`                    | expected to work     |

The driver support lists come from
[Network configuration/Wireless](https://wiki.archlinux.org/title/Network_configuration/Wireless):
RTW88 supports "8822CE" among others; RTW89 supports "8852AE, 8851BE, 8852BE,
and 8852CE"; and there is a `mt7921 / mt7922` section. The Atheros chip is
unnamed. The 14ITL6/14ACN6 user guide is filed with the FCC under ID
`PPD-QCNFA344AH`, a Qualcomm card, which suggests a Qualcomm 802.11ac module was
fitted. The exact chip, and so `ath10k`, is **unverified**.

**On the ISO.** The
[2026.10.01 package list](https://geo.mirror.pkgbuild.com/iso/2026.10.01/arch/pkglist.x86_64.txt)
includes `linux 7.2.7`, `linux-firmware`, `linux-firmware-intel`,
`linux-firmware-realtek`, `linux-firmware-mediatek`, `linux-firmware-atheros`,
`iwd 3.12` and `sof-firmware`.

**After install.** `linux-firmware` is a meta package. It depends on
`linux-firmware-{amd,amdgpu,atheros,broadcom,cirrus,intel,mediatek,nvidia,other,radeon,realtek,ti}`
([package search](https://archlinux.org/packages/search/json/?q=linux-firmware)),
so `pacstrap … linux-firmware` covers every chip above. To slim it down, the
matching vendor package plus `linux-firmware-amdgpu` (ACN6) or
`linux-firmware-intel` (ITL6, which also covers the iGPU and SOF) would be
enough. That is **unverified** for this exact machine, so the default
meta package is the safe choice.

**Known Wi-Fi caveats (ArchWiki
[Network configuration/Wireless](https://wiki.archlinux.org/title/Network_configuration/Wireless)):**

- RTW89: "On some computers, you may experience unstable connections. It seems
  like a common issue on late models from HP and Lenovo." The suggested fix is
  `options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y` and
  `options rtw89_core disable_ps_mode=y` in `/etc/modprobe.d/70-rtw89.conf`.
- RTW88: set the regulatory domain (`wireless-regdb`), otherwise you "will be
  able to see all Wi-Fi networks, but will not be able to connect".
- MT7921: "high latency problems… the only solution is to disable ASPM":
  `options mt7921e disable_aspm=1`.
- A soft-blocked card needs `rfkill unblock wlan` (see §4).

### 1.3 Linux quirks

| Area                                    | Finding                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Source                                                                                                                                                                                                                                                                                                                                                            |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Audio (ACN6)                            | Works. "If the internal digital microphone is not detected out of the box, adding `snd_rn_pci_acp3x.dmic_acpi_check=1` to the kernel parameter does the trick".                                                                                                                                                                                                                                                                                                                                                                                             | [ArchWiki 14ACN6](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6)                                                                                                                                                                                                                                                                                   |
| Audio (ITL6)                            | Lenovo's Windows audio package is `6.0.9228.1_ISST_10.29.0.6367`. ISST is Intel Smart Sound Technology, i.e. a DSP, which on Linux means SOF. ArchWiki: SOF (`sof-firmware`) "is usually required for laptops". Install `sof-firmware` on either variant; the Installation guide names it for "onboard audio". Exact ITL6 behaviour is **unverified**.                                                                                                                                                                                                      | [Lenovo 14ITL6 driver list](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/5-series/ideapad-5-pro-14itl6/downloads/driver-list), [ArchWiki ALSA#Firmware](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture#Firmware)                                                                                                          |
| Touchpad                                | Works. Laptop/Lenovo table, 14ACN6 row: "After waking from suspend, the trackpad may be slow to respond for several minutes."                                                                                                                                                                                                                                                                                                                                                                                                                               | [ArchWiki Laptop/Lenovo](https://wiki.archlinux.org/title/Laptop/Lenovo)                                                                                                                                                                                                                                                                                          |
| Suspend (ACN6)                          | Ships with Modern Standby (s2idle). On Linux this "will manifest as the device immediately exiting stand-by". Fix: in the **hidden** advanced BIOS, AMD PBS menu, set Modern Standby to "S3 Enabled". The unlock steps: disable "HotKey Mode" and "OneKeyBattery", switch the BIOS language to Chinese, save and power off, then type `F1 1 Q A Z` … `F6 6 Y H N` while it is off. The page warns: "Do not touch these setting unless you know what you are doing".                                                                                         | [ArchWiki 14ACN6](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6)                                                                                                                                                                                                                                                                                   |
| Suspend (general)                       | `cat /sys/power/mem_sleep` shows `[s2idle] shallow deep`. If `deep` is not offered, look for an S3 option in the UEFI or keep s2idle.                                                                                                                                                                                                                                                                                                                                                                                                                       | [ArchWiki Power management/Suspend and hibernate](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)                                                                                                                                                                                                                                        |
| Suspend (ITL6)                          | No ArchWiki page and no Laptop/Lenovo row exist for the 14ITL6. **Unverified**.                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | (absence: `Lenovo_IdeaPad_5_Pro_14ITL6` returns 404 on the wiki)                                                                                                                                                                                                                                                                                                  |
| Keyboard backlight / Fn keys            | `Fn+Space` toggles the backlight; `Fn+Esc` sets Fn lock. F1–F12 emit `XF86AudioMute`, volume, mic-mute, brightness, `XF86RFKill` (F8, handled by logind) and so on. `Fn+q` emits `XF86Launch4`, the performance-mode key. Whether `ideapad_laptop` exposes a `kbd_backlight` LED on this model is **unverified** (the driver has `kbd_bl` support).                                                                                                                                                                                                         | [ArchWiki 14ACN6 Function keys](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6#Function_keys), [ideapad-laptop.c](https://github.com/torvalds/linux/blob/master/drivers/platform/x86/lenovo/ideapad-laptop.c)                                                                                                                                       |
| `ideapad_laptop` / battery conservation | Classic path: `echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode` (limits charge to "55-60%"). **Current kernels deprecate it**: the driver prints "conservation_mode attribute has been deprecated, see charge_types" and maps conservation to the power-supply `charge_types` value `Long_Life` (Rapid Charge to `Fast`). So `/sys/class/power_supply/BAT*/charge_types` reads like "Fast [Standard] Long_Life". The kernel release that introduced this mapping is **unverified**; check which file exists on the 7.2 kernel. | [ArchWiki Laptop/Lenovo#Battery conservation mode](https://wiki.archlinux.org/title/Laptop/Lenovo#Battery_conservation_mode), [ideapad-laptop.c](https://github.com/torvalds/linux/blob/master/drivers/platform/x86/lenovo/ideapad-laptop.c), [sysfs-class-power ABI](https://github.com/torvalds/linux/blob/master/Documentation/ABI/testing/sysfs-class-power)  |
| Performance modes                       | `/sys/firmware/acpi/platform_profile_choices` shows `low-power balanced performance`, matching Lenovo's "Battery Saving / Intelligent Cooling / Extreme Performance".                                                                                                                                                                                                                                                                                                                                                                                       | [ArchWiki 14ACN6](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6#System_performance_mode)                                                                                                                                                                                                                                                           |
| Webcam                                  | ACN6: webcam `04f2:b6be` "Yes". The IR camera and ToF sensor are not covered. ITL6: **unverified**.                                                                                                                                                                                                                                                                                                                                                                                                                                                         | [ArchWiki 14ACN6](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6)                                                                                                                                                                                                                                                                                   |
| BIOS updates                            | "fwupd does not officially support this device." Lenovo's BIOS packages are Windows `.exe` only: ACN6 `GECN39WW` (README dated 2024-10-30), ITL6 `GDCN69WW` (2024-04-09).                                                                                                                                                                                                                                                                                                                                                                                   | [ArchWiki 14ACN6#Firmware](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6#Firmware), [gecn39ww.txt](https://download.lenovo.com/consumer/mobiles/gecn39ww.txt), [gdcn69ww.txt](https://download.lenovo.com/consumer/mobiles/gdcn69ww.txt)                                                                                                           |
| MX450 dGPU                              | The MX450 is `TU117M`, i.e. Turing. For Turing the ArchWiki lists `nvidia-open` (linux), `nvidia-open-lts` or `nvidia-open-dkms`. Since driver 590, `nvidia` has been replaced by `nvidia-open`. Use `prime-run` from `nvidia-prime` to offload work to the dGPU.                                                                                                                                                                                                                                                                                           | [pci.ids](https://github.com/pciutils/pciids/blob/master/pci.ids), [ArchWiki NVIDIA](https://wiki.archlinux.org/title/NVIDIA#Installation), [Arch news 2025-12-20](https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/), [ArchWiki PRIME](https://wiki.archlinux.org/title/PRIME#PRIME_render_offload) |

## 2. Lenovo BIOS: keys and Secure Boot

**Entering setup and the boot menu.** Lenovo's IdeaPad article
([HT500216, "Recommended way to enter BIOS - ideapad"](https://pcsupport.lenovo.com/de/en/products/laptops-and-netbooks/500-series/520-15ikb-type-81bf/solutions/ht500216))
offers three routes:

- Turn the PC on and "immediately and repeatedly press F2 or (Fn+F2)".
- Press **F12** for the Boot Menu and pick setup from there.
- With the PC off, press the **Novo button** for the Novo Button Menu, which
  offers BIOS Setup and Boot Menu.

Lenovo also has an [introduction to the NOVO button](https://support.lenovo.com/us/en/solutions/ht062552-introduction-to-novo-button-ideapad).
The ArchWiki page for this model agrees: "pressing the `F2` or `F12` key while
turning on the device"
([14ACN6#Accessing the BIOS](https://wiki.archlinux.org/title/Lenovo_IdeaPad_5_Pro_14ACN6#Accessing_the_BIOS)).
PSREF shows the NOVO button hole on the left edge. The user guide (as indexed by
search) says it can also be reached by pressing Fn + power button with the
machine off. That is **unverified** against a Lenovo-hosted copy of the guide.
To boot the Ventoy stick: **F12** (or Novo → Boot Menu) → pick the USB entry.

**Disabling Secure Boot.** The ArchWiki model page says to "Disable Secure Boot
in the BIOS". The exact menu path on this Insyde-style BIOS (believed to be
_Security → Secure Boot → Disabled_, then _Exit → Save_ / F10) is
**unverified**. Lenovo's
[BIOS Simulator](https://download.lenovo.com/bsco/index.html) lists both
machines (82L7, 82L3) and can be used to confirm the path before touching the
laptop. Lenovo's own Secure Boot video warns "it is not recommended to disable
secure boot unless instructed to by a support professional"
([nvid500424](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/ideapad-s-series-netbooks/ideapad-slim-3-15amn8/videos/nvid500424-disable-and-enable-secure-boot-in-bios-lenovo-support-quick-tips)).
Arch can enable Secure Boot later with its own keys (sbctl).

**Does the Arch ISO boot with Secure Boot on?** No. The Installation guide
says: "Arch Linux installation images do not support Secure Boot. You will need
to disable Secure Boot to boot the installation medium"
([Installation guide](https://wiki.archlinux.org/title/Installation_guide#Boot_the_live_environment)).
The Secure Boot page adds: "The official installation image does not support
Secure Boot (archlinux/archiso#69)… There has been no support for Secure Boot
in the official installation medium ever since" 2016
([Secure Boot#Booting an installation medium](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Booting_an_installation_medium)).
The ISO boots with systemd-boot on UEFI (`bootmodes=('bios.syslinux' 'uefi.systemd-boot')`
in [releng/profiledef.sh](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/profiledef.sh),
read through the GitHub mirror) and has no signed shim.

**Ventoy and Secure Boot.**

- Ventoy's [Secure Boot page](https://www.ventoy.net/en/doc_secure.html) says
  that "Secure Boot was supported by default from Ventoy 1.0.76" (Ventoy2Disk
  menu Option → Secure Boot Support, or `-s` for `Ventoy2Disk.sh`). With
  Secure Boot on, the first boot shows MokManager and you enrol Ventoy's key
  once per computer. "Since Ventoy 1.1.13+ you need to enroll a new key for the
  UEFI CA 2023 issue."
- The [v1.1.16 notes](https://github.com/ventoy/Ventoy/releases/tag/v1.1.16)
  repeat that a new CA has been used since v1.1.14.
- The same page warns: "For some computers you must enable Allow Microsoft
  3rd Part UEFI CA option in the UEFI firmware".
- [SecureBoot.md](https://github.com/ventoy/Ventoy/blob/master/SecureBoot.md)
  explains that Ventoy uses Rocky Linux's shim, "signed with both UEFI CA 2011
  and UEFI CA 2023". After enrolment, the default policy is "Fully bypass
  secure boot… it will boot any EFI files without check". The stricter policy
  (`VTOY_SECURE_BOOT_POLICY: "1"`) only boots files signed with the UEFI CA,
  which the Arch ISO's systemd-boot is not.

**Verdict.** Under Ventoy's default policy, MOK enrolment should be enough to
start the Arch ISO with Secure Boot on (_inference_ from SecureBoot.md, not
tested on this laptop). It does not help the installed system, which needs
Secure Boot off or its own signing. Disabling Secure Boot first removes a
failure mode for no loss.

## 3. Ventoy

**Version.** The latest release is **v1.1.18, published 2026-10-09**
([GitHub releases](https://github.com/ventoy/Ventoy/releases/tag/v1.1.18)).
Assets: `ventoy-1.1.18-linux.tar.gz`, `ventoy-1.1.18-windows.zip`,
`ventoy-1.1.18-livecd.iso` and `sha256.txt`. The release body gives
`d86ff9de63d94c8b8f1f6b14d23c55af4b88e8207bf2893890892a6a97b1ad54` for the Linux
tarball and `082c478e8c432e1ac653899fcf50e3a4077a2851bc6112b5ddd30545962164a9`
for the Windows zip. Before that came v1.1.17 (2026-07-24), whose notes say
"Optimization for Secure Boot process".

**Trust caveat (ArchWiki).** The [Ventoy page](https://wiki.archlinux.org/title/Ventoy)
says "Ventoy might contain backdoors or other malicious code". It lists
unexplained precompiled blobs and authors whose identities are unknown, and
points to [Multiboot USB drive](https://wiki.archlinux.org/title/Multiboot_USB_drive)
for alternatives. For a single Arch install, writing the ISO directly (`dd` /
Rufus) avoids Ventoy entirely
([USB flash installation medium](https://wiki.archlinux.org/title/USB_flash_installation_medium)).

**Install Ventoy to the stick.** This erases the stick
([Get Started](https://www.ventoy.net/en/doc_start.html)).

- **Linux (CLI):** unpack the tarball, then as root run
  `sh Ventoy2Disk.sh -i /dev/sdX`. Options: `-I` forces the install, `-u`
  updates an existing stick, `-l` lists info, `-g` uses GPT (MBR is the
  default), `-s` enables secure boot support ("default is disabled") and
  `-r SIZE_MB` reserves space. ArchWiki adds that `dosfstools` is needed,
  because `mkfs.vfat` creates the EFI partition. A GTK/Qt GUI
  (`VentoyGUI.x86_64`) and a WebUI also ship in the tarball, and the AUR has
  `ventoy`.
- **Windows:** unzip, run `Ventoy2Disk.exe`, select the device and click
  Install. Choose MBR or GPT and Secure Boot support under the Option menu. A
  CLI also exists for Windows (since 1.0.86).
- **Updating** with `-u` or the Update button keeps the files on the data
  partition.

**Copy the ISO.** The stick ends up with two partitions: an exFAT data
partition (label `Ventoy`) and `VTOYEFI`. Copy `archlinux-2026.10.01-x86_64.iso`
anywhere on the data partition; Ventoy scans every directory recursively. Put a
sidecar `archlinux-….iso.sha256` next to it, and Ventoy will compare checksums
when you press **`m`** on the menu entry
([checksum doc](https://www.ventoy.net/en/doc_checksum.html)).

**Verify the ISO first.** These are the exact commands from
[archlinux.org/download](https://archlinux.org/download/#checksums), current
release **2026.10.01**, kernel 7.2.7, 1.5 GB, PGP fingerprint `0x54449A5C`:

```sh
# checksum (download b2sums.txt or sha256sums.txt alongside the ISO)
b2sum -c b2sums.txt
# PGP with Sequoia
sq network wkd search pierre@archlinux.org --output release-key.pgp
sq verify --signer-file release-key.pgp --signature-file archlinux-2026.10.01-x86_64.iso.sig archlinux-2026.10.01-x86_64.iso
# or PGP with GnuPG
gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
gpg --verify archlinux-2026.10.01-x86_64.iso.sig archlinux-2026.10.01-x86_64.iso
```

The page gives the SHA256 value
(`684ded26c63240ff4a41e8c25ee84ea6da233f557364821f13d12c2b0a9059a5`) and links
`sha256sums.txt`, but it shows no `sha256sum` command. `sha256sum -c` works the
same way as `b2sum -c`. Both txt files also list the bootstrap tarball, so
`--ignore-missing` silences the "No such file" lines (_inference_). From an
existing Arch or EndeavourOS system, the Installation guide offers
`pacman-key -v archlinux-version-x86_64.iso.sig`
([Installation guide#Verify signature](https://wiki.archlinux.org/title/Installation_guide#Verify_signature)).

**Boot modes.**

- **Normal mode** emulates the ISO as a CD-ROM.
- **GRUB2 mode** (Ctrl+r, or `r`) is "an alternative for booting Linux ISO".
  "Use GRUB2 mode only when you run into problem with the default mode". It
  needs a grub2 config inside the ISO
  ([GRUB2 mode](https://www.ventoy.net/en/doc_grub2boot.html)). The archiso
  releng profile ships `grub/grub.cfg` and `grub/loopback.cfg`, but whether
  GRUB2 mode boots this ISO is **unverified**.
- **Memdisk mode** (Ctrl+d) loads the whole image into RAM. It needs an ISO
  "normally less than 1GB" that does not need to be mounted after boot
  ([Memdisk](https://www.ventoy.net/en/doc_memdisk.html)). The 1.5 GB Arch ISO
  does not qualify (_inference_). See also the old
  [issue #432](https://github.com/ventoy/Ventoy/issues/432), "Memdisk Failed
  To Boot ArchLinux UEFI".

**Known Arch-on-Ventoy issues.** The archiso boot loaders "expect the ISO
contents to reside on volume with a year and month label (`ARCH_YYYYXX`)".
The classic failure is "device did not show up after 30 seconds" waiting for
`/dev/disk/by-label/ARCH_YYYYMM`
([USB flash installation medium#Troubleshooting](https://wiki.archlinux.org/title/USB_flash_installation_medium#Troubleshooting)).
The same symptom under Ventoy was
[issue #1887](https://github.com/ventoy/Ventoy/issues/1887), closed after
"Updated ventoy on USB & ArchLinux October ISO & issue seems to go away". So the
documented fix is to update Ventoy (`-u`), plus the ArchWiki's "try using a USB
2.0 port" for losetup errors. Recent success reports exist
([#3162](https://github.com/ventoy/Ventoy/issues/3162), archlinux-2025.03.01 on
Ventoy 1.1.05). The open "Timed out waiting for device /dev/disk/by-uuid" issues
([#3271](https://github.com/ventoy/Ventoy/issues/3271),
[#3503](https://github.com/ventoy/Ventoy/issues/3503)) concern booting an
installed Arch **vdisk** through vtoyboot, not the ISO.

## 4. Networking

### 4.1 Live ISO

The Installation guide says: "In the installation image, systemd-networkd,
systemd-resolved, iwd and ModemManager are preconfigured and enabled by
default. That will not be the case for the installed system." It also says
"DHCP… should work out of the box for Ethernet, WLAN, and WWAN"
([Connect to the internet](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet)).
The ISO's networkd units confirm this:
[`20-ethernet.network`](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-ethernet.network)
matches `Type=ether` (excluding virtual `Kind=`) and
[`20-wlan.network`](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wlan.network)
matches `Type=wlan`. Both set `DHCP=yes` and `MulticastDNS=yes`, with route
metric 100 for Ethernet and 600 for Wi-Fi, so wired wins.

**Wired: USB-C dongle or Android USB tethering.** Plug it in and wait a few
seconds, then `ip link` and `ping`. A USB Ethernet dongle is `Type=ether`. On
Android, enable _Settings → … → USB tethering_
([Android tethering](https://wiki.archlinux.org/title/Android_tethering)). The
phone appears as a USB network interface (the ArchWiki example uses
`ID_USB_DRIVER=="rndis_host"`), which is also Ethernet-type, so the ISO should
pick it up with DHCP and no commands (_inference_; not tested). This is the
least-CLI path.

**Wi-Fi with iwctl** ([iwd#iwctl](https://wiki.archlinux.org/title/Iwd#iwctl)):

```sh
rfkill                         # SOFT/HARD state; F8 is the RF-kill key on this model
rfkill unblock wlan            # if soft-blocked
iwctl                          # interactive prompt [iwd]#, Tab completes names and SSIDs
[iwd]# device list             # usually wlan0
[iwd]# device wlan0 set-property Powered on     # only if it shows off
[iwd]# station wlan0 scan      # prints nothing
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "Your SSID"        # prompts for the passphrase
[iwd]# station wlan0 connect-hidden "Your SSID" # hidden network
# one-shot form:
iwctl --passphrase 'passphrase' station wlan0 connect 'Your SSID'
```

iwd notes from the same page:

- Passphrases must be "8 to 63 ASCII-encoded characters".
- SSIDs containing spaces must be quoted.
- Credentials are stored in `/var/lib/iwd`.

On the ISO, DHCP for `wlan0` comes from networkd. iwd's own
`EnableNetworkConfiguration` is only needed when iwd runs standalone.
WPA-Enterprise is not needed here.

**Check, then the clock:**

```sh
ping ping.archlinux.org
timedatectl                    # systemd-timesyncd is enabled on the ISO; just confirm "System clock synchronized: yes"
```

The Installation guide: "The live system needs accurate time to prevent package
signature verification failures… The systemd-timesyncd service is enabled by
default in the live environment"
([Update the system clock](https://wiki.archlinux.org/title/Installation_guide#Update_the_system_clock)).

**Optional, and recommended for the CLI-shy: drive the install over SSH.** Once
the laptop is online, run `passwd` to set a root password on the live system,
then from another machine on the same LAN run
`ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@archiso.local`
([Install Arch Linux via SSH](https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH)).
That page states the `archiso.local` mDNS name works on the same LAN. It also
says to confirm `PermitRootLogin yes` in `/etc/ssh/sshd_config`. Every command
in this note can then be pasted from a real terminal.

### 4.2 Installed system: which stack, which packages

"No configuration (except for `/etc/pacman.d/mirrorlist`) gets carried over
from the live environment", and the network manager has to be installed _and
enabled_ ([Installation guide](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages)).
These options come from the
[Network configuration](https://wiki.archlinux.org/title/Network_configuration#Network_managers)
table:

| Option                                    | pacstrap packages                                   | enable                                                                                                            | CLI / TUI                           | Notes                                                                                                                                                                                                                                                                        |
| ----------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **NetworkManager** (recommended here)     | `networkmanager` (pulls `wpa_supplicant`)           | `NetworkManager.service`                                                                                          | `nmcli`, **`nmtui`** (menu-based)   | Handles Wi-Fi, Ethernet, dongles, tethering, VPN plugins (already used here: `networkmanager-openconnect` etc. in `packages/pacman-explicit.txt`).                                                                                                                           |
| NetworkManager with iwd backend           | `networkmanager iwd`                                | `NetworkManager.service` only. **Do not enable `iwd.service`**: "NetworkManager will start and manage iwd itself" | same                                | Needs `/etc/NetworkManager/conf.d/wifi_backend.conf` with `[device]` `wifi.backend=iwd`. ArchWiki calls it the "experimental iwd backend" ([NetworkManager#Using iwd as the Wi-Fi backend](https://wiki.archlinux.org/title/NetworkManager#Using_iwd_as_the_Wi-Fi_backend)). |
| iwd + systemd-networkd + systemd-resolved | `iwd` (networkd and resolved are part of `systemd`) | `iwd.service systemd-networkd.service systemd-resolved.service`                                                   | `iwctl`, `networkctl`, `impala` TUI | Closest to the ISO. You must write `.network` files yourself, e.g. `[Match] Name=… [Network] DHCP=yes` ([systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd)).                                                                                              |

**DNS for NetworkManager.** If systemd-resolved is not started, NetworkManager
logs flood with errors ([NetworkManager#Enable NetworkManager](https://wiki.archlinux.org/title/NetworkManager#Enable_NetworkManager)).
The recommended resolved setup is the stub symlink, and it cannot be made from
inside `arch-chroot`. Create it from outside:
`ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf`
([systemd-resolved](https://wiki.archlinux.org/title/Systemd-resolved)). Then
enable `systemd-resolved.service` alongside NetworkManager.

**First-boot recipe (NetworkManager).** Add `networkmanager` to `pacstrap`, then
inside the chroot run `systemctl enable NetworkManager systemd-resolved`. After
reboot, connect with `nmtui`, or with
`nmcli device wifi connect "Your SSID" password "…"`. For a hidden network, add
`hidden yes`
([NetworkManager#nmcli examples](https://wiki.archlinux.org/title/NetworkManager#nmcli_examples)).
The ISO's iwd credentials are not copied over by the manual install. archinstall
_does_ copy them when "Copy ISO network configuration" is chosen (§5).

### 4.3 Stable LAN address and `.local` name

- **Router DHCP reservation** (preferred, _inference_): keeps the laptop on
  DHCP everywhere else and needs no config on the laptop. ArchWiki's
  [local hostname resolution](https://wiki.archlinux.org/title/Network_configuration#Local_network_hostname_resolution)
  lists, among the options, a DNS server "and make the LAN devices use it (e.g.
  via DHCP)". How to set a reservation depends on the router (**unverified**,
  no primary source applies).
- **Static IP on one profile with nmcli:** NetworkManager's
  [nmcli-examples](https://networkmanager.dev/docs/api/latest/nmcli-examples.html)
  adds a profile with `ip4 192.168.100.100/24 gw4 192.168.100.1` and
  `nmcli con mod … ipv4.dns "…"`. Setting `ipv4.addresses` on an existing
  profile offers to switch `ipv4.method` to `manual`. A static address on a
  roaming laptop only suits the home profile, so apply it to that connection,
  not globally.
- **mDNS `.local` without touching the router**, two options
  ([Network configuration#Local network hostname resolution](https://wiki.archlinux.org/title/Network_configuration#Local_network_hostname_resolution)):
  - **systemd-resolved.** Its "mDNS support is enabled by default", but the
    network manager must also enable it per connection. For NetworkManager:
    `nmcli connection modify <name> connection.mdns yes`, or set the default
    with `connection.mdns=2` in a `/etc/NetworkManager/conf.d/` file. Open UDP
    5353 if there is a firewall (firewalld is in this repo), and disable Avahi
    if both are installed
    ([systemd-resolved#mDNS](https://wiki.archlinux.org/title/Systemd-resolved#mDNS)).
  - **Avahi + nss-mdns.** Install `nss-mdns`, enable `avahi-daemon.service`,
    and put `mdns_minimal [NOTFOUND=return]` before `resolve` and `dns` in the
    `hosts:` line of `/etc/nsswitch.conf`
    ([Avahi#Hostname resolution](https://wiki.archlinux.org/title/Avahi#Hostname_resolution)).

  Either way the laptop answers as `yourhostname.local`. "The older Win32 API
  does not support mDNS", which may matter for Windows clients.

## 5. archinstall

**Version.** `archinstall 4.5-1` is on the 2026.10.01 ISO
([pkglist](https://geo.mirror.pkgbuild.com/iso/2026.10.01/arch/pkglist.x86_64.txt))
and is the current `extra` package. Upstream tagged 4.5 on 2026-09-29
([release](https://github.com/archlinux/archinstall/releases/tag/4.5)). The
release notes include "Fix WiFi SSIDs with spaces missing from scan list",
"support optdepends of linux-firmware", and "Changed from polkit to
systemd-logind for hyprland, labwc, niri, sway". The ArchWiki suggests
`pacman -Sy archinstall` on the ISO if a newer release is out
([archinstall](https://wiki.archlinux.org/title/Archinstall)).

**Main menu (4.5 source,
[`global_menu.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/global_menu.py)):**
Archinstall language · Locales · Mirrors and repositories · Disk configuration
(with LVM, Btrfs snapshot type and **Disk encryption**) · Swap · Bootloader ·
Kernels · Additional firmware · Hostname · Authentication (root, users, U2F) ·
Profile · Applications (audio, bluetooth, print service, power management,
firewall, fonts) · Network configuration · Pacman · Additional packages ·
Timezone · Automatic time sync (NTP) · Save configuration · Install · Abort.

- **Profile.** "Minimal" is a bare profile with no extra packages
  ([`minimal.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/default_profiles/minimal.py)).
  A `niri` profile also exists, installing niri, alacritty, fuzzel, mako,
  waybar, swaybg, swayidle, swaylock and xdg-desktop-portal-gnome with lightdm
  as the greeter
  ([`niri.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/default_profiles/desktops/niri.py)).
  That clashes with this repo's greetd/Noctalia setup, so **use Minimal**.
- **Network configuration**
  ([`models/network.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/models/network.py)):
  "Copy ISO network configuration to installation", "Use Network Manager
  (default backend)", "Use Network Manager (iwd backend)", "Use standalone iwd"
  or "Manual configuration". Leaving it empty gives the warning "Network will
  need to be set up manually on the installed system." The ArchWiki notes that
  copying the ISO config copies the iwd network _including its password_.
- **Bootloader**
  ([`models/bootloader.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/models/bootloader.py)):
  Systemd-boot, Grub, Efistub, Limine or Refind. The default on UEFI is
  **Systemd-boot**, with UKI and "removable" options.
- **Kernels:** linux, linux-hardened, linux-lts, linux-rt, linux-rt-lts,
  linux-zen. **Audio:** pipewire or pulseaudio
  ([guided docs](https://archinstall.archlinux.page/installing/guided.html)).
- **Wi-Fi at start.** When no connection is detected, 4.5 offers "Would you
  like to connect to a Wifi?" unless run with `--skip-wifi-check`
  ([`main.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/main.py),
  [`wifi_handler.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/network/wifi_handler.py),
  which drives `wpa_cli`). How reliable this is next to the ISO's iwd is
  **unverified**. The guided docs still warn: "The installer will not configure
  WiFi before the installation begins", so connect with `iwctl` first.

**Save and load a config.** The "Save configuration" menu item writes
`user_configuration.json` and (optionally encrypted) `user_credentials.json`
to a directory you choose
([`configuration.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/configuration.py),
[`args.py`](https://github.com/archlinux/archinstall/blob/4.5/archinstall/lib/args.py)).
To replay it: `archinstall --config user_configuration.json --creds user_credentials.json`
(or `--config-url` / `--creds-url`). `archinstall --dry-run` generates a
config without touching disks. The keys are documented in the
[guided docs](https://archinstall.archlinux.page/installing/guided.html).
_Inference_: a saved config without credentials could live in this repo (under
`docs/` or a new `install/` dir) as a reproducible spec. Credentials must never
be committed.

**Reliability.**

- ArchWiki warnings: "Different defaults than the regular installation process
  are used". Include `/var/log/archinstall/install.log` in support requests.
  "Manual Partitioning does not protect against creating overlapping
  partitions, misaligned partitions…". Leaving the root password blank disables
  root.
- Shipped profiles "are specific to archinstall and not supported by package
  maintainers"
  ([archinstall](https://wiki.archlinux.org/title/Archinstall)).
- At research time GitHub showed 13 issues opened since 2026-08-01 and still
  open ([search](https://github.com/archlinux/archinstall/issues?q=is%3Aissue+is%3Aopen+created%3A%3E2026-08-01)).
  None of them is a broad regression of 4.5, but that is a snapshot, not a
  reliability measure.

**Manual guide vs archinstall.** Same result, different visibility. The manual
path (§7) makes every choice explicit: mkinitcpio hooks, fstab, bootloader
entries. That is what the blog and future debugging need. archinstall is faster
and, with "Minimal" + "Network Manager" + systemd-boot + ext4 or btrfs (+ LUKS
if wanted), produces an equivalent base. The difference is mostly what you
learn (_inference_).

## 6. EndeavourOS → plain Arch: differences that bite

| Topic            | EndeavourOS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Plain Arch                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| initramfs        | **dracut**. The installer maps bootloader → packages: grub → `grub, eos-dracut, os-prober`; systemd-boot → `kernel-install-for-dracut`; refind → `refind, eos-dracut` ([calamares `eos_bootloader.conf`](https://github.com/endeavouros-team/calamares/blob/calamares/data/eos/modules/eos_bootloader.conf)). `eos-dracut` provides `dracut-rebuild` and `/etc/eos-dracut.conf` ([eos-dracut README](https://github.com/endeavouros-team/PKGBUILDS/blob/master/eos-dracut/README.md)). ISO dracut defaults: `compress="zstd"` ([eos-defaults.conf](https://github.com/endeavouros-team/EndeavourOS-ISO/blob/main/airootfs/etc/dracut.conf.d/eos-defaults.conf)). | **mkinitcpio 42.2** in `core`. `linux` depends on the virtual `initramfs`, which `mkinitcpio`, `dracut` and `booster` all provide (repo db). The Installation guide assumes mkinitcpio ran during pacstrap. The default is now a **systemd-based initramfs** ([mkinitcpio](https://wiki.archlinux.org/title/Mkinitcpio)). Rebuild with `mkinitcpio -P`, not `dracut-rebuild`.                                                                                                                                                                                                                                                                                                                                         |
| GRUB defaults    | `kernel_params: nowatchdog, nvme_load=YES`; `GRUB_TIMEOUT 5`, `GRUB_DISABLE_SUBMENU false`, `GRUB_DISABLE_RECOVERY true`, `GRUB_BACKGROUND /usr/share/endeavouros/splash.png`, `GRUB_EARLY_INITRD_LINUX_STOCK ""` ([calamares `grubcfg.conf`](https://github.com/endeavouros-team/calamares/blob/calamares/data/eos/modules/grubcfg.conf)). The systemd-boot path uses the same params plus `efiBootloaderId: endeavouros`.                                                                                                                                                                                                                                      | Stock `/etc/default/grub` from the package. `grub-mkconfig` "will automatically detect the microcode update" ([Microcode](https://wiki.archlinux.org/title/Microcode)). The blank `GRUB_EARLY_INITRD_LINUX_STOCK` was needed because dracut embeds microcode. mkinitcpio's `microcode` hook embeds it too ("mkinitcpio and dracut generate combined initramfs files by default"). Do not copy EndeavourOS's grub file across.                                                                                                                                                                                                                                                                                         |
| NVIDIA hook      | `nvidia-hook` 1.5.3 runs `eos-nvidia-fix` on install, upgrade or removal of `nvidia-open`/`nvidia-open-lts`. It then calls `reinstall-kernels`, `dracut-rebuild` or `mkinitcpio -P`, whichever is installed ([PKGBUILDS/nvidia-hook](https://github.com/endeavouros-team/PKGBUILDS/tree/master/nvidia-hook)).                                                                                                                                                                                                                                                                                                                                                    | Not in Arch repos or the AUR. Install `nvidia-open` (MX450 is Turing). Whether an initramfs rebuild hook is needed at all depends on whether the NVIDIA modules are put in the initramfs. See [NVIDIA#Early loading](https://wiki.archlinux.org/title/NVIDIA#Early_loading).                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Mirrors          | `endeavouros-mirrorlist`, `eos-rankmirrors`, plus `reflector-simple` (AUR) and `rate-mirrors-bin` (AUR) in this repo's snapshot.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `reflector` from `extra`, configured in `/etc/xdg/reflector/reflector.conf`. Enable **only** `reflector.timer` (weekly); enabling the service too is "redundant" ([Reflector](https://wiki.archlinux.org/title/Reflector)). The ISO's mirrorlist is copied by pacstrap.                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| AUR helper       | `yay` comes from the EndeavourOS repo.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `yay` is AUR-only (13.0.1-1 on [AUR RPC](https://aur.archlinux.org/packages/yay)), so bootstrap it by hand (below). "AUR helpers are not supported by Arch Linux" ([AUR helpers](https://wiki.archlinux.org/title/AUR_helpers)).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Package snapshot | `packages/pacman-explicit.txt` was taken here.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Checked against the `core`, `extra` and `multilib` databases from `geo.mirror.pkgbuild.com` and the [AUR RPC](https://aur.archlinux.org/rpc/v5/info), 2026-10-16. 231 of 260 are official. **16 are AUR** (`banana-cursor-bin, bibata-cursor-theme-bin, bruno-bin, downgrade, flyctl, google-chrome, maplemono-ttf, papirus-folders-git, pgadmin4-bin, rate-mirrors-bin, reflector-simple, teams-for-linux-bin, visual-studio-code-bin, witr, yay, zen-browser-bin`). **13 are in neither** (`endeavouros-branding, endeavouros-keyring, endeavouros-mirrorlist, eos-apps-info, eos-dracut, eos-hooks, eos-log-tool, eos-packagelist, eos-quickstart, eos-rankmirrors, nvidia-hook, welcome, slack-desktop-wayland`). |

On `slack-desktop-wayland`: the AUR RPC returned no such package. The AUR
search shows `slack-desktop` and `slack-desktop-wayland-jetm`, so the name in
`packages/aur.txt` needs re-checking (it may have been renamed or deleted).

**Bootstrapping yay** ([AUR#Installing and upgrading packages](https://wiki.archlinux.org/title/Arch_User_Repository#Installing_and_upgrading_packages)).
Run this as the normal user, after `base-devel` and `git` are installed:

```sh
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
less PKGBUILD        # the wiki: "Carefully check the PKGBUILD"
makepkg -si          # -s install deps via pacman, -i install the built package
```

The ArchWiki points to the
[June 2026 AUR malware incident](https://archlinux.org/news/active-aur-malicious-packages-incident/)
as a reason to vet PKGBUILDs. `yay-bin` is the prebuilt alternative
(**unverified** that it is current).

**Other things that will not be there:** the `welcome` app, `eos-update`, the
`eos-*` helpers, and the EndeavourOS keyring and repo entry in
`/etc/pacman.conf`. Snapshots and scripts in this repo that assume them need a
check (_inference_; for example `docs/packages.md` describes the EndeavourOS
baseline).

## 7. Manual install essentials (ArchWiki Installation guide, current wording)

Source for everything not otherwise cited:
[Installation guide](https://wiki.archlinux.org/title/Installation_guide).

1. **Boot mode.** `cat /sys/firmware/efi/fw_platform_size` should print `64`.
   For HiDPI on the 2.8K panel, `setfont ter-132b` (the guide's example).
2. **Network and clock.** See §4.1.
3. **Partitioning (UEFI/GPT).** The example layout is an ESP mounted at
   `/boot`, **1 GiB** ("Suggested size"), plus root. The ESP page: "It is
   recommended to make the partition 1 GiB… If still in doubt, 4 GiB ought to
   be enough for anybody". Go larger (e.g. 8 GiB) for Limine + Snapper
   snapshots ([EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition)).
   - **`/boot` vs `/efi`:** ESP at `/boot` keeps kernel and initramfs readable
     by "most boot loaders". ESP at `/efi` with `/boot` on root is supported
     "Only [by] GRUB and rEFInd… Using a Unified kernel image… is also
     possible". `/boot/efi` is "historical and now discouraged".
     **systemd-boot ⇒ ESP at `/boot`**, _unless_ an XBOOTLDR partition holds
     the kernels: then the ESP goes at `/efi` and XBOOTLDR at `/boot`
     (`bootctl --esp-path=/efi --boot-path=/boot install`). systemd-boot reads
     XBOOTLDR through the firmware's file-system drivers, so in practice it must
     be FAT, and it "must be on the same physical disk as the ESP"
     ([systemd-boot#Installation using XBOOTLDR](https://wiki.archlinux.org/title/Systemd-boot#Installation_using_XBOOTLDR)).
   - **No swap partition:** "disk based swap can be avoided entirely by
     setting up swap on zram after installing the system". zram-generator
     needs only `/etc/systemd/zram-generator.conf` with `[zram0]`. The default
     is half the RAM, capped at 4 GiB
     ([zram](https://wiki.archlinux.org/title/Zram#Using_zram-generator)).
     This repo already has [docs/zram.md](../zram.md).
4. **Filesystem.** The guide uses `mkfs.ext4` as its example and
   `mkfs.fat -F 32` for the ESP. Btrfs is an option, and archinstall exposes
   Btrfs snapshot types. Choosing ext4 or btrfs is a judgement call that the
   guide does not make.
5. **LUKS on a laptop.** For the default systemd-based initramfs, add the
   `keyboard` and `sd-encrypt` hooks (and `sd-vconsole` for a non-US keymap):
   `HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)`.
   Then pass `rd.luks.name=device-UUID=root root=/dev/mapper/root`
   ([dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)).
   Note from [Arch news 2026-09-22](https://archlinux.org/news/mkinitcpio-42-requires-manual-intervention-for-tpm2-based-unlocking-of-luks-devices/):
   mkinitcpio ≥ 42 changes PCR measurements, so TPM2 unlocking has to be
   re-enrolled. That only matters if TPM2 unlocking is used. The firmware TPM
   2.0 is present per PSREF.
6. **Mount.** `mount /dev/root_partition /mnt`, then
   `mount --mkdir /dev/efi_system_partition /mnt/boot`.
7. **pacstrap.** The guide's minimum is `pacstrap -K /mnt base linux linux-firmware`.
   It lists what else to review: microcode (`amd-ucode` or `intel-ucode`),
   `sof-firmware`, filesystem utilities, networking software, a text editor,
   and `man-db man-pages texinfo`. A list for this laptop (_inference_,
   assembled from the cited pages):

   ```sh
   pacstrap -K /mnt base linux linux-firmware amd-ucode   # or intel-ucode on 14ITL6
   # plus: sof-firmware networkmanager sudo nano man-db man-pages texinfo
   #       base-devel git zram-generator   (+ btrfs-progs if btrfs, + nvidia-open nvidia-prime if MX450)
   ```

8. **fstab.** `genfstab -U /mnt >> /mnt/etc/fstab`, then check the result.
9. **chroot.** The current guide writes `arch-chroot -S /mnt`. `hostnamectl`,
   `localectl` and `timedatectl` do not work inside the chroot.
10. **Time.** `ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime`
    (the zone exists in [tzdata zone1970.tab](https://github.com/eggert/tz/blob/main/zone1970.tab)),
    then `hwclock --systohc`, then enable `systemd-timesyncd`.
11. **Locale.** Uncomment `en_US.UTF-8 UTF-8` (plus any others) in
    `/etc/locale.gen`, run `locale-gen`, and write `/etc/locale.conf` with
    `LANG=en_US.UTF-8`. Set `/etc/vconsole.conf` `KEYMAP=` only if not US.
12. **Hostname.** `/etc/hostname` with one line. Allowed characters are
    "lowercase a to z, 0 to 9, and -", 1–63 long.
13. **Network.** Enable the stack chosen in §4.2. Create the resolved symlink
    from outside the chroot.
14. **mkinitcpio.** Not needed unless LUKS, LVM or RAID is used, or the keymap
    changed. In those cases edit `mkinitcpio.conf` and run `mkinitcpio -P`.
15. **Root password.** `passwd`.
16. **Boot loader.** The guide only points to the comparison in
    [Arch boot process#Boot loader](https://wiki.archlinux.org/title/Arch_boot_process#Boot_loader).
    It makes no single recommendation. Options:
    - **systemd-boot:** `bootctl install`. It finds an ESP at `/efi`, `/boot` or
      `/boot/efi`. Entries look like `title Arch Linux`,
      `linux /vmlinuz-linux`, `initrd /initramfs-linux.img`. `systemd` 261.2+
      restarts `systemd-boot-update.service` on upgrade
      ([systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)). It is
      also archinstall's UEFI default.
    - **GRUB:** `grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB`
      then `grub-mkconfig -o /boot/grub/grub.cfg`. It is the one to pick for
      ESP-at-`/efi` or an encrypted `/boot` ([GRUB](https://wiki.archlinux.org/title/GRUB)).
    - **Limine 12.9.3** (`extra`): copy `/usr/share/limine/BOOTX64.EFI` to the
      ESP and register it with efibootmgr
      ([Limine](https://wiki.archlinux.org/title/Limine)). It has Snapper
      integration for Btrfs.

    _Correction (2026-10-18):_ an earlier version of this note inferred "no
    dual boot and the ESP at `/boot`". The machine dual-boots Windows. The
    on-machine snapshot shows a 100 MB Windows ESP at `/boot/efi` plus a 1 GiB
    XBOOTLDR partition (ext4, for GRUB) at `/boot`. systemd-boot still fits,
    with the ESP at `/efi`, XBOOTLDR reformatted FAT32 at `/boot`, and Windows
    auto-detected on the shared ESP. That is what
    [arch-install.vi.md](../arch-install.vi.md) does.
17. **Microcode.** "mkinitcpio and dracut generate combined initramfs files by
    default. The microcode will be loaded automatically at boot time." The
    `microcode` hook is in the default HOOKS
    ([Microcode](https://wiki.archlinux.org/title/Microcode)). Install
    `amd-ucode` (ACN6) or `intel-ucode` (ITL6).
18. **User + sudo** (post-install,
    [General recommendations](https://wiki.archlinux.org/title/General_recommendations)):
    `useradd -m -G wheel -s /usr/bin/fish username`, then `passwd username`
    ([Users and groups](https://wiki.archlinux.org/title/Users_and_groups)).
    Install `sudo` and create `/etc/sudoers.d/10-wheel` containing
    `%wheel ALL=(ALL:ALL) ALL` with `visudo`
    ([Sudo#Example entries](https://wiki.archlinux.org/title/Sudo#Example_entries)).
    `sudo-rs` is an alternative. The wheel group also matters for iwd, which
    allows "only root and members of the network or the wheel user group".
19. **Reboot.** `exit`, `umount -R /mnt`, `reboot`, and remove the stick.

## Open questions, to check on the laptop

- [x] **Which model?** Run `cat /sys/class/dmi/id/product_name` and
      `cat /sys/class/dmi/id/product_version` on the current EndeavourOS
      install. Expect 82L7 (14ACN6) or 82L3 (14ITL6). Does it have the MX450
      (`lspci -d ::03xx`)? **Answer (2026-10-17):** `IdeaPad 5 Pro 14ACN6`,
      Ryzen 7 5800U, with the MX450 (`10de:1f97`, TU117M) at `01:00.0` next to
      the Cezanne iGPU (`1002:1638`).
- [x] **Which Wi-Fi chip?** `lspci -nnk | grep -A3 -i network`. Compare the
      `[vendor:device]` ID with the table in §1.2 and note which driver is "in
      use". If it is RTW89 or MT7921, decide whether to pre-stage the ASPM
      modprobe option. **Answer:** MediaTek MT7921 (`14c3:7961`). The ASPM option
      is not pre-staged; it is a troubleshooting entry in the install guide.
- [ ] **Exact BIOS path to Secure Boot** and whether "Allow Microsoft 3rd Party
      UEFI CA" exists (only matters if Ventoy is used with Secure Boot on).
      Check in the [Lenovo BIOS Simulator](https://download.lenovo.com/bsco/index.html)
      or on the machine.
- [x] **BIOS version** (`cat /sys/class/dmi/id/bios_version`) against
      GECN39WW / GDCN69WW. The updates are Windows-only, and fwupd does not
      support the device. How to flash without Windows is **unverified**.
      **Answer:** `GECN26WW(V1.10)`, behind GECN39WW. Windows is still installed,
      so the guide flashes it from Windows before the install.
- [x] **Suspend.** `cat /sys/power/mem_sleep` on the current install. On a
      14ACN6, is the hidden-BIOS S3 change already done? On a 14ITL6, does
      s2idle resume cleanly? **Answer:** only `[s2idle]` is offered, so the S3
      change has not been done. The guide keeps s2idle.
- [ ] **Conservation mode file.** On the 7.2 kernel, does
      `/sys/class/power_supply/BAT*/charge_types` exist, or only the
      deprecated `conservation_mode`?
- [ ] **Does Arch on Ventoy boot first try** on this laptop, in normal mode,
      with Ventoy 1.1.18? If not, retry after `Ventoy2Disk.sh -u`, on another
      USB port, or with a plain `dd` stick.
- [ ] **Package list rewrite.** Drop the 13 non-Arch entries from
      `packages/pacman-explicit.txt` and move AUR entries out of it, then
      re-check `slack-desktop-wayland` in `packages/aur.txt`. _Deferred:_ the
      install guide filters the list at install time instead (`comm` against
      `pacman -Slq`, minus `dracut grub os-prober intel-ucode intel-media-driver
  libva-intel-driver vulkan-intel`). `downgrade` is AUR on plain Arch but
      missing from `aur.txt`, so the guide installs it by name.
- [ ] **Unverified in this note:** the exact Intel Wi-Fi model in each variant;
      whether the 11ac Atheros card is QCA6174/ath10k; ITL6 audio, webcam and
      suspend; whether `ideapad_laptop` exposes a keyboard-backlight LED on this
      model; Ventoy GRUB2 mode with this ISO; Android tethering behaviour on the
      ISO (inferred from `Type=ether`).

### Sources

Cited inline next to each claim. Package versions come from the Arch package
database (`core`, `extra`, `multilib` `.db` files from
`geo.mirror.pkgbuild.com`) and from
<https://geo.mirror.pkgbuild.com/iso/2026.10.01/arch/pkglist.x86_64.txt>, read
on 2026-10-16. Release dates come from the GitHub release API for
`ventoy/Ventoy` and `archlinux/archinstall`. Lenovo data was read through the
PSREF spec-data and pcsupport driver-list JSON endpoints that the public pages
call. ArchWiki pages were read as raw wikitext (`?action=raw`) on 2026-10-16.
