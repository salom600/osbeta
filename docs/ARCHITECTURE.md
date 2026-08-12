# NexoraOS Architecture

## High-level stack

```
┌──────────────────────────────────────────────────────────────┐
│                       User-facing layer                       │
│  Nexora Store · Nexora Launcher · Nexora Settings · Welcome  │
├──────────────────────────────────────────────────────────────┤
│                       NexoraDE desktop                        │
│  Openbox WM · nexora-panel · nexora-logout · GTK3 theming    │
├──────────────────────────────────────────────────────────────┤
│                     Display + input stack                     │
│  Xorg (default) · Wayland (optional) · libinput · Wacom      │
├──────────────────────────────────────────────────────────────┤
│                       Multimedia stack                        │
│  PipeWire · WirePlumber · PulseAudio compat · Bluetooth audio│
├──────────────────────────────────────────────────────────────┤
│                      Hardware drivers                         │
│  mesa · vulkan-{radeon,intel} · xserver-xorg-video-{amdgpu,  │
│  ati,intel,nouveau,vesa,fbdev,vmware} · NVIDIA DKMS ·        │
│  VirtualBox / QEMU / VMware guest additions                  │
├──────────────────────────────────────────────────────────────┤
│              Custom NexoraOS kernel (Linux 6.12 LTS)          │
│  1000 Hz timer · BFQ I/O · schedutil · KSM · BBR TCP ·       │
│  WireGuard built-in · BPF JIT · all 2009+ GPU drivers as m   │
├──────────────────────────────────────────────────────────────┤
│                          Base system                          │
│  Debian 13 (Trixie) · systemd · apt/dpkg · glibc             │
├──────────────────────────────────────────────────────────────┤
│                         Boot stack                            │
│  BIOS: grub-pc · UEFI: grub-efi-amd64 · hybrid ISO via xorriso│
└──────────────────────────────────────────────────────────────┘
```

## Why Debian 13 (Trixie) instead of Arch

| Aspect | Arch (old choice) | Debian 13 Trixie (new choice) |
|--------|-------------------|-------------------------------|
| Update model | Rolling — daily breakage risk | Stable — point release every ~2 months, major release every 2 years |
| Repo size | ~13,000 packages | ~59,000 packages |
| Hardware support | Excellent | Excellent (better firmware coverage in non-free) |
| Stability | Hit-or-miss | Battle-tested |
| Security updates | Fast but breaking | Slower but stable |
| Tooling | archiso (frequent breaking changes) | live-build (stable, well-documented) |
| Custom kernel | Have to build everything | We can build just the kernel and use Debian's userspace |

## Why a custom kernel

Debian's stock `linux-image-amd64` is configured for the lowest common denominator — server + desktop + embedded, with `allyesconfig`-ish defaults that make the kernel big and slow to load modules.

Our custom kernel (Linux 6.12 LTS) is configured for **modern desktop only**:

| Knob | Debian default | NexoraOS | Why |
|------|----------------|----------|-----|
| `CONFIG_HZ` | 250 | **1000** | Lower scheduler latency = snappier desktop |
| `CONFIG_PREEMPT_*` | `NONE` | **`VOLUNTARY`** | Better desktop responsiveness without throughput hit |
| `CONFIG_MQ_IOSCHED_BFQ` | m | **y** | BFQ gives interactive apps priority over background I/O |
| `CONFIG_CPU_FREQ_DEFAULT_GOV` | `powersave` | **`schedutil`** | Schedutil uses scheduler info to pick CPU freq — better balance |
| `CONFIG_KSM` | n | **y** | KSM dedups identical pages — saves RAM when running many browsers/VMs |
| `CONFIG_TCP_CONG_DEFAULT` | `cubic` | **`bbr`** | BBR TCP handles packet loss better, faster downloads |
| `CONFIG_WIREGUARD` | m | **y** | Built-in WireGuard, no module loading |
| `CONFIG_BPF_JIT_ALWAYS_ON` | n | **y** | Hardened BPF JIT (used by systemd, gaming, observability) |
| Server drivers (NFS, SR-IOV, 10GbE NICs) | y | **disabled** | Saves ~10 MB kernel + faster boot |

## Resource budget (target: < 300 MB RAM at idle)

| Component | RSS (typical) |
|-----------|---------------|
| Linux kernel + initramfs (live) | 80–120 MB |
| systemd + dbus + logind | 25 MB |
| NetworkManager + wpa_supplicant | 15 MB |
| PipeWire + WirePlumber | 12 MB |
| Xorg server | 25 MB |
| Openbox WM | 10 MB |
| nexora-panel (Python+GTK3) | 25 MB |
| nm-applet, volumeicon, polkit-gnome | 20 MB |
| picom compositor (optional) | 8 MB |
| **Total idle** | **~220–260 MB** |

## Boot flow

1. **Firmware** loads the ISO's hybrid MBR (BIOS) or ESP (UEFI).
2. **GRUB** (BIOS) or **grub-efi-amd64** (UEFI) loads `vmlinuz` + `initrd.img`.
3. **initramfs-tools** with `live-boot` hook:
   - Mounts the ISO (`LABEL=NEXORA_YYYYMM`).
   - Loads the squashfs (`filesystem.squashfs`) as the lower layer.
   - Creates a tmpfs upper layer + persistent overlay for live USB writes.
4. **systemd** boots to `graphical.target`.
5. **lightdm** autologins `nexora` and starts the `nexora` X session.
6. **nexora-session** launches Openbox + nexora-panel + helpers.

## Install flow (nexora-installer)

1. User clicks **Install NexoraOS**.
2. nexora-installer wizard: language → timezone → disk → filesystem → user → summary.
3. On confirm, runs `/tmp/nexora-install.sh`:
   - `sgdisk` partitions the disk (1 GB ESP + root).
   - `mkfs.{btrfs,ext4,xfs,f2fs}` formats.
   - `debootstrap --arch=amd64 trixie /mnt http://deb.debian.org/debian` installs base system.
   - `chroot /mnt ...` installs kernel + GUI + NexoraDE.
   - `grub-install` (auto-detects UEFI vs BIOS).
   - `grub-mkconfig -o /boot/grub/grub.cfg`.
   - Unmounts.
4. Reboot → NexoraOS installed.

## GitHub Actions build pipeline

```
   push to main
        │
        ▼
   lint.yml (shellcheck + yamllint + pyflakes + bash -n + ref check)
        │
   ┌────┴────┐
   │         │
   ok      fail → block merge
   │
   ▼
   build-kernel.yml ──────▶ kernel .deb artifact + release
        │
        ▼
   build-iso.yml
        │
        ├─ download latest kernel .deb artifact
        ├─ docker run debian:trixie
        │     apt-get install live-build
        │     ./debian-live/build.sh
        │       ├─ lb config (trixie, hybrid BIOS+UEFI)
        │       ├─ copy kernel .deb to config/packages.chroot/
        │       ├─ sudo lb build
        │       └─ mv *.iso to out/
        ├─ upload ISO as CI artifact (30-day)
        └─ create release (with ISO if <2 GiB, otherwise just checksum + log)
              │
        ┌─────┴─────┐
        │           │
      ok         fail
        │           │
        │           ▼
        │     open issue (build-failure, auto-fix, automated labels)
        │           │
        │           ▼
        │     auto-fix.yml
        │       ├─ gh run view --log-failed
        │       ├─ python: match patterns
        │       ├─ patch files
        │       ├─ push branch
        │       └─ gh pr create + merge → re-trigger build
        │
        ▼
   release published
```

## File permissions model

The live ISO runs as user `nexora` (uid 1000), member of:
`sudo, storage, power, video, audio, input, lp, autologin`.

- `sudo` → passwordless sudo on the live ISO.
- After install, the user picks their own password; the live user is removed by the installer.

## Security

- The live user has password `nexora` (auto-login, no prompt) — documented in the welcome screen.
- After install, the user picks their own password.
- `ufw` and `firejail` are preinstalled but not enabled by default (user enables via nexora-settings → System).
- `fail2ban` is preinstalled and enabled for `sshd` (which is *not* enabled by default).
- `apparmor` is enabled by default.
