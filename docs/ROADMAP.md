# NexoraOS Roadmap

## Status (as of 2026-08)

- [x] Project restructured to Debian 13 (Trixie) base
- [x] Custom Linux 6.12 LTS kernel config (1000 Hz, BFQ, schedutil, KSM, BBR)
- [x] Kernel build pipeline in GitHub Actions
- [x] live-build configuration (hybrid BIOS + UEFI)
- [x] NexoraDE: session + panel + launcher + settings + logout + welcome
- [x] Nexora Store (apt wrapper)
- [x] debootstrap-based installer
- [x] Pre-build lint workflow (shellcheck, yamllint, pyflakes, bash -n, ref check)
- [x] Auto-fix workflow
- [x] Documentation

## v2026.1 — Vortex (beta)

- [ ] First successful CI kernel build
- [ ] First successful CI ISO build with custom kernel
- [ ] QEMU smoke test in CI (boot the ISO, verify login)
- [ ] Real-hardware install test (BIOS + UEFI)
- [ ] Persistent USB live mode verification
- [ ] NVIDIA driver load test (post-install via DKMS)
- [ ] Old GPU (Intel HD 2009-era) test
- [ ] Multilingual live session test

## v2026.2 — Pulse

- [ ] ARM64 (aarch64) kernel + ISO target (Raspberry Pi 5, Orange Pi)
- [ ] Wayland session (labwc) as default-on-compatible
- [ ] Snapper auto-snapshots on btrfs root
- [ ] Nexora Cloud sync (Nextcloud integration in nexora-settings)
- [ ] "Nexora Lang" — the lightweight custom programming language mentioned in the brief (a small interpreter shipped as `nexora-lang`; purpose: educational scripting + a unified config format for NexoraOS components).
- [ ] Apply kernel patch sets (Project C / BMQ scheduler, tkg, hardened-usercopy) — opt-in via a separate `kernel/patches/` directory.

## v2026.3 — Aurora

- [ ] Full disk encryption installer UI (LUKS + TPM auto-unlock)
- [ ] Phone-as-modem first-class support (NetworkManager + mmcli wizard in settings)
- [ ] Gaming mode (similar to SteamOS game mode) — disables panel, launches Steam Big Picture
- [ ] Tablet / 2-in-1 mode: auto-rotate, on-screen keyboard
- [ ] Recovery partition on installed systems (bootable snapshot)

## v2026.4 — Helix

- [ ] Immutable variant (read-only root, transactional updates via OSTree or Btrfs snapshots)
- [ ] Nexora Store: ratings, screenshots, auto-updates
- [ ] Web-based management UI (reach the box over LAN, manage packages + services)
- [ ] First-party theme store

## Beyond

- [ ] RISC-V experimental image
- [ ] Nexora Phone (mobile UI variant on Phosh)
- [ ] NexoraOS Server edition (no DE, web admin UI only)

## Out of scope (for now)

- **Replacing systemd.** systemd is the init system for the foreseeable future; a `runit`/`openrc` variant would be a separate subproject.
- **A from-scratch package manager.** apt/dpkg is the foundation. The Nexora Store wraps apt, doesn't replace it.
- **Hard-forking the Linux kernel.** We use vanilla LTS from kernel.org with config tweaks + optional patch sets, not a source fork.
