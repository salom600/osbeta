# ◆ NexoraOS 2026.1 — Vortex

> A lightweight, modern, **Debian 13 (Trixie)**-based Linux distribution built for **2026**.
> Idle RAM < 300 MB · BIOS + UEFI · 2009+ hardware · bootable USB · live mode · installer.
> Built on a **custom Linux 6.12 LTS kernel** tuned for desktop responsiveness.

![Lint](https://github.com/salom600/osbeta/actions/workflows/lint.yml/badge.svg)
![Kernel](https://github.com/salom600/osbeta/actions/workflows/build-kernel.yml/badge.svg)
![ISO](https://github.com/salom600/osbeta/actions/workflows/build-iso.yml/badge.svg)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)
![Arch](https://img.shields.io/badge/arch-x86__64-red)

**NexoraOS** is an independent Linux distribution built on top of **Debian 13 (Trixie)** for stability (no daily breakage like rolling-release distros), with a **custom-built Linux 6.12 LTS kernel** optimized for desktop responsiveness. It ships a custom lightweight desktop environment (NexoraDE) written in Python + GTK3 on top of the Openbox window manager, and a graphical app store (**Nexora Store**) that wraps Debian's apt repositories.

The entire project is built by **GitHub Actions** in three stages:

1. **Lint** — every push runs shellcheck + yamllint + pyflakes + bash -n + broken-reference checks. Bugs never reach the build step.
2. **Build custom kernel** — Linux 6.12 LTS is downloaded from kernel.org, configured with NexoraOS-specific responsiveness knobs (1000 Hz timer, BFQ I/O, voluntary preempt, schedutil governor), built into `.deb` packages, and published as a release.
3. **Build ISO** — `live-build` boots a Debian trixie chroot, installs the custom kernel `.deb` + NexoraDE binaries, and produces a hybrid BIOS+UEFI live ISO.

When a build fails, an issue is opened automatically and the `auto-fix.yml` workflow parses the failure log, applies a patch on a new branch, opens a PR, and auto-merges it — re-triggering the build.

---

## Why Debian + custom kernel?

| Choice | Rationale |
|--------|-----------|
| **Debian 13 Trixie base** (instead of Arch) | Stable 2-year release cycle, huge well-tested repo, no daily breakage. Same apt/dpkg ecosystem as Ubuntu/Mint/Kali. |
| **Custom Linux 6.12 LTS kernel** | Vanilla kernel from kernel.org + NexoraOS `.config` (1000 Hz, BFQ, schedutil, KSM, BBR). All 2009+ GPU drivers as modules. Built fresh in CI as `.deb`. |
| **Openbox + Python/GTK3 desktop** (NexoraDE) | Idle RAM < 300 MB. No GNOME/KDE bloat. Easy to read and modify. |
| **live-build** (Debian's official ISO tool) | Battle-tested, stable, no surprises like archiso's frequent breaking changes. |
| **No VirtualBox host packages** | NexoraOS doesn't host VMs by default — saves ~500 MB. Users install via Store if needed. VirtualBox / QEMU / VMware **guest** additions ARE included so NexoraOS runs smoothly as a guest. |

---

## Features

- **Hybrid ISO**: boots on BIOS (grub-pc) and UEFI (grub-efi-amd64) from the same image
- **Live mode**: persistent overlay (`cow_spacesize=4G`) so changes survive reboot on USB
- **Custom kernel**: Linux 6.12 LTS with desktop-tuned `.config` (1000 Hz, BFQ, schedutil, KSM, BBR TCP, WireGuard built-in)
- **NexoraDE**: Openbox + custom Python/GTK3 panel, launcher, settings, logout, welcome
- **Nexora Store**: graphical installer for Debian repos
- **debootstrap-based installer**: nexora-installer uses debootstrap + chroot to install NexoraOS to disk (BIOS + UEFI, btrfs/ext4/xfs/f2fs, optional LUKS)
- **Full driver coverage**: xserver-xorg-video-{intel,amdgpu,radeon,nouveau,vesa,fbdev,vmware} + nvidia-driver (DKMS) + all firmware packages
- **VM guest support**: VirtualBox guest additions, QEMU guest agent, open-vm-tools, spice-vdagent, hyperv-daemons
- **Modern stack**: PipeWire audio, NetworkManager, systemd, btrfs default
- **Multiple language packs**: en, ar, fr, es, de, it, pt, ru, zh, ja, ko, tr

---

## Repository layout

```
osbeta/
├── .github/workflows/
│   ├── lint.yml               # pre-build syntax + reference checks
│   ├── build-kernel.yml       # builds Linux 6.12 LTS .deb
│   ├── build-iso.yml          # builds the live ISO via live-build
│   ├── auto-fix.yml           # parses failure logs + opens PR
│   └── nightly.yml            # daily kernel + ISO rebuild
├── .github/issue-templates/
│   └── build-failure.md
├── kernel/
│   ├── configs/x86_64_defconfig  # NexoraOS kernel .config
│   ├── patches/                   # kernel patches (initially empty)
│   └── build.sh                   # downloads source, applies patches, builds .deb
├── debian-live/
│   ├── build.sh                # live-build wrapper
│   ├── auto/                   # live-build auto scripts
│   └── config/
│       ├── package-lists/nexora.list.chroot   # packages installed in live chroot
│       ├── packages.chroot/                    # custom .deb files (kernel) drop here
│       ├── includes.chroot/                    # files copied into chroot (binaries, configs)
│       │   ├── usr/local/bin/nexora-*          # NexoraDE tools
│       │   ├── usr/share/xsessions/            # X session entry
│       │   └── etc/                            # hostname, hosts, lightdm, locale, os-release
│       └── hooks/normal/01-nexora-setup.hook.chroot  # creates user, enables services, etc.
├── nexora-de/bin/             # NexoraDE desktop scripts (Python)
├── nexora-store/nexora-store  # graphical app store
├── nexora-installer/nexora-installer  # debootstrap-based installer
├── scripts/
│   ├── build-local.sh         # local ISO build helper
│   ├── test-iso.sh            # QEMU smoke test
│   └── dev-setup.sh           # install dev deps
├── docs/                      # architecture + build + roadmap docs
└── README.md
```

---

## Building

### Full pipeline (recommended)

Push to `main` and three workflows run in sequence:

1. **Lint** runs first — fails fast on syntax errors.
2. **Build custom kernel** runs in parallel — produces `.deb` packages.
3. **Build ISO** runs after kernel — downloads the latest kernel `.deb`, runs live-build in a `debian:trixie` Docker container, uploads ISO as artifact + release.

Find built artifacts:
- ISO: https://github.com/salom600/osbeta/releases
- Kernel `.deb`: https://github.com/salom600/osbeta/releases (tagged `kernel-v*`)
- CI artifacts: https://github.com/salom600/osbeta/actions

### Local build

```bash
# Build kernel locally (Arch/Debian/Ubuntu host with build-essential + ccache)
./kernel/build.sh

# Build ISO locally (requires Docker)
./debian-live/build.sh
```

### Smoke-testing

```bash
./scripts/test-iso.sh bios     # or: uefi
```

---

## Downloading a built ISO

1. Go to the [Releases page](https://github.com/salom600/osbeta/releases)
2. Download `nexora-<version>-amd64.iso` (and the `.sha256sum`)
3. Verify: `sha256sum -c nexora-<version>-amd64.iso.sha256sum`
4. Flash to USB:
   ```bash
   sudo dd if=nexora-<version>-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   Or use [balenaEtcher](https://etcher.balena.io/) / [Ventoy](https://www.ventoy.net/).

If the ISO is missing from a release (size > 2 GiB GitHub asset limit), download it from the Actions run page as a CI artifact (30-day retention, 10 GiB limit).

---

## Installing to disk

1. Boot the live ISO.
2. Click **Install NexoraOS** on the desktop (or in the Nexora menu).
3. The nexora-installer wizard walks you through language, disk, user creation.
4. The wizard runs debootstrap + chroot to install NexoraOS to disk.
5. Reboot — done.

The installer supports:
- BIOS + UEFI
- ext4, btrfs (default), xfs, f2fs
- Auto-detection of UEFI vs BIOS for GRUB install
- LightDM autologin for the new user

---

## Auto-fix loop

```
   push to main ─▶ lint.yml
        │
        ▼
   ┌────┴────┐
   │         │
   ok      fail → block merge (don't waste CI cycles on broken syntax)
   │
   ▼
   build-kernel.yml  ──┐
                       ├──▶ build-iso.yml ──▶ release
                       │            │
                       │       ┌────┴────┐
                       │       │         │
                       │     ok       fail
                       │       │         │
                       │       │         ▼
                       │       │    open issue
                       │       │         │
                       │       │         ▼
                       │       │    auto-fix.yml
                       │       │         │
                       │       │    parse log → patch → PR → merge → re-trigger
                       │       │
                       └───────┘
```

Failure patterns currently recognized by `auto-fix.yml`:
- `target not found: <pkg>` (apt equivalent: `E: Unable to locate package`) — remove package
- `missing dependency: <pkg>` — add package
- PGP signature failure — refresh apt keyring
- bash syntax error in hooks — flag for review
- Python `ModuleNotFoundError` — add Python dependency

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

- The distribution as a whole: **GPL-3.0-or-later** (inherits Debian packages)
- NexoraDE / Nexora Store / Nexora tools: **MIT**
- Custom kernel config: **GPL-2.0** (kernel-derived)
- See [LICENSE](LICENSE) and [LICENSE.MIT](LICENSE.MIT)

---

## Acknowledgments

- [Debian](https://www.debian.org/) — base distribution
- [live-build](https://wiki.debian.org/DebianLive) — ISO builder
- [Linux kernel](https://kernel.org/) — the kernel itself
- [Openbox](http://openbox.org) — window manager
- [GTK](https://gtk.org) — GUI toolkit
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — icon theme
