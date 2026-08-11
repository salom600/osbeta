# ◆ NexoraOS 2026.1 — Vortex

> A lightweight, modern, Arch-based Linux distribution built for **2026**.
> Idle RAM < 300 MB · BIOS + UEFI · 2009+ hardware · bootable USB · live mode · installer.

![Build ISO](https://github.com/salom600/osbeta/actions/workflows/build-iso.yml/badge.svg)
![Auto-fix](https://github.com/salom600/osbeta/actions/workflows/auto-fix.yml/badge.svg)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)
![Arch](https://img.shields.io/badge/arch-x86__64-red)

**NexoraOS** is an independent Linux distribution assembled on top of the Arch
Linux base. It ships a custom-built lightweight desktop environment (NexoraDE)
written in Python + GTK3 on top of the Openbox window manager, and a graphical
app store (**Nexora Store**) that wraps both official repositories and the AUR.

The entire project is built by **GitHub Actions**. Every push to `main` triggers
a fresh ISO build inside an `archlinux:latest` container; the resulting ISO is
attached to an auto-generated GitHub release. When a build fails, an issue is
opened automatically and a second workflow (`auto-fix.yml`) parses the failure
log, applies a patch on a new branch, opens a PR, and auto-merges it — re-triggering
the build. The loop continues until green.

---

## Why NexoraOS?

| Modern distros | NexoraOS |
|----------------|----------|
| GNOME/KDE idle at 800-1500 MB RAM | NexoraDE idles at <300 MB |
| Builtin app store is just a pacman wrapper | Nexora Store searches both repos + AUR |
| Bootloaders often only UEFI | NexoraOS supports both BIOS + UEFI |
| Old GPUs (2009+) often drop | NexoraOS ships all `xf86-video-*` drivers + all Vulkan drivers |
| Need to memorize commands | nexora-launcher (W-r) + nexora-settings cover everything |

---

## Features

- **Hybrid ISO**: boots on BIOS (syslinux) and UEFI (systemd-boot) from the same image
- **Live mode**: persistent CowFS overlay (`cow_spacesize=4G`) so changes survive reboot on USB
- **Low-RAM boot mode**: `nomodeset` + multi-user target boots on 1 GB RAM
- **NexoraDE**: Openbox + custom Python/GTK3 panel, launcher, settings, logout
- **Nexora Store**: graphical installer for official repos + AUR via `yay -Ss`
- **Calamares installer**: GUI installer for permanent disk install (BIOS + UEFI)
- **Full driver coverage**: xf86-video-{amdgpu,ati,intel,nouveau,vesa,fbdev} + Vulkan-{radeon,intel}
- **Gaming**: Steam, Lutris, Wine, Proton-ready, all major Vulkan drivers, gamemode
- **Virtualization**: VirtualBox, QEMU, libvirt/virt-manager preinstalled
- **Modern stack**: PipeWire audio, NetworkManager, systemd, btrfs default with snapper-friendly layout
- **Multiple language packs**: en, ar, fr, es, de, it, pt, ru, zh, ja, ko, tr

---

## Repository layout

```
osbeta/
├── .github/workflows/
│   ├── build-iso.yml          # main ISO build + release
│   ├── auto-fix.yml           # parse failure log + open PR
│   └── nightly.yml            # daily trigger
├── .github/issue-templates/
│   └── build-failure.md       # auto-issue body
├── archiso/profile/
│   ├── profiledef.sh          # archiso profile metadata
│   ├── packages.x86_64        # package list for the live ISO
│   ├── pacman.conf            # pacman config used during build
│   ├── airootfs/
│   │   ├── etc/               # system config (hostname, lightdm, calamares, X11)
│   │   ├── root/customize_airootfs.sh   # post-install customization script
│   │   └── boot/loader/entries/         # systemd-boot entries
│   └── syslinux/syslinux.cfg  # BIOS boot menu
├── nexora-de/bin/             # NexoraDE desktop scripts (Python)
│   ├── nexora-session         # Openbox session launcher
│   ├── nexora-panel           # top panel (GTK3)
│   ├── nexora-launcher        # app launcher (W-r)
│   ├── nexora-settings        # control center
│   ├── nexora-logout          # logout/reboot/poweroff dialog
│   └── nexora-welcome         # first-run welcome
├── nexora-store/
│   └── nexora-store           # graphical app store
├── nexora-installer/
│   └── nexora-installer       # Calamares wrapper
├── scripts/
│   ├── build-local.sh         # local build helper
│   ├── test-iso.sh            # QEMU smoke test
│   └── dev-setup.sh           # install dev deps
├── docs/                      # architecture + build + roadmap docs
└── README.md
```

---

## Building the ISO

### On GitHub Actions (recommended)

Push to `main` and the workflow runs automatically. The ISO will be uploaded
both as a CI artifact (30-day retention) and as a GitHub release asset (prerelease).

### Locally on an Arch Linux host

```bash
sudo pacman -S archiso archlinux-keyring
./scripts/build-local.sh
```

### Locally via Docker (any Linux host)

```bash
./scripts/build-local.sh --docker
```

### Smoke-testing the ISO

```bash
./scripts/build-local.sh
./scripts/test-iso.sh bios     # or: uefi
```

---

## Downloading a built ISO

1. Go to the [Releases page](https://github.com/salom600/osbeta/releases)
2. Download `nexora-<version>-x86_64.iso` and the `.sha256sum`
3. Verify: `sha256sum -c nexora-<version>-x86_64.iso.sha256sum`
4. Flash to USB:
   ```bash
   sudo dd if=nexora-<version>-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   Or use [balenaEtcher](https://etcher.balena.io/) / [Ventoy](https://www.ventoy.net/).

---

## Installing to disk

1. Boot the live ISO.
2. Click **Install NexoraOS** on the desktop (or in the Nexora menu).
3. Calamares walks you through language, partitioning, user creation.
4. Reboot — done.

The installer supports:
- BIOS + UEFI
- ext4, btrfs (default), xfs, f2fs
- Side-by-side install (resize existing partition)
- LUKS full-disk encryption

---

## Auto-fix loop

This repo ships a self-healing CI system:

```
   push to main ─▶ build-iso.yml runs
                          │
                  ┌───────┴───────┐
                  │               │
              success          failure
                  │               │
            release ISO     open issue (build-failure.md)
                                     │
                              auto-fix.yml runs
                                     │
                          parse log → patch files → push branch
                                     │
                              open PR → auto-merge
                                     │
                              triggers build-iso.yml again
```

Failure patterns currently recognized:

| Pattern | Action |
|---------|--------|
| `target not found: <pkg>` | Remove package from `packages.x86_64` and `packages.conf` |
| `missing dependency: <pkg>` | Add package to `packages.x86_64` |
| PGP signature failure | Add `pacman-key --refresh-keys` to the workflow |
| `No space left on device` | Trim package list (manual review) |
| bash syntax error in profiledef | Flag for review |
| `ModuleNotFoundError: No module named '<x>'` | Add `python-<x>` to package list |
| Docker daemon error | Retry |

---

## Minimum system requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU       | x86_64, 2009+ | x86_64, 2016+ |
| RAM       | 1 GB (low-RAM mode) | 2 GB |
| Disk      | 10 GB | 30 GB+ |
| Boot mode | BIOS or UEFI | UEFI |
| GPU       | Any VESA-compatible | Intel/AMD/NVIDIA with Vulkan |

---

## License

- The distribution as a whole: **GPL-3.0-or-later** (inherits Arch packages)
- NexoraDE / Nexora Store / Nexora tools: **MIT**
- See [LICENSE](LICENSE) and [LICENSE.MIT](LICENSE.MIT)

---

## Acknowledgments

- [Arch Linux](https://archlinux.org) — base distribution
- [archiso](https://gitlab.archlinux.org/archlinux/archiso) — ISO builder
- [Calamares](https://calamares.io) — installer
- [Openbox](http://openbox.org) — window manager
- [GTK](https://gtk.org) — GUI toolkit
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — icon theme
