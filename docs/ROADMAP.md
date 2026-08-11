# NexoraOS Roadmap

## Status (as of 2026-08)

- [x] Project structure
- [x] archiso profile (BIOS + UEFI)
- [x] NexoraDE: session + panel + launcher + settings + logout + welcome
- [x] Nexora Store (pacman + AUR)
- [x] Calamares installer configuration
- [x] GitHub Actions build pipeline
- [x] Auto-fix workflow
- [x] Documentation

## v2026.1 — Vortex (beta)

- [ ] First successful CI build
- [ ] QEMU smoke test in CI
- [ ] Real-hardware install test (BIOS + UEFI)
- [ ] Persistent USB live mode verification
- [ ] NVIDIA driver load test
- [ ] Old GPU (Intel HD 2009-era) test
- [ ] Multilingual live session test

## v2026.2 — Pulse

- [ ] ARM64 (aarch64) build target
- [ ] Wayland session (labwc) as default-on-compatible
- [ ] Snapper auto-snapshots on btrfs root
- [ ] Nexora Cloud sync (Nextcloud integration in nexora-settings)
- [ ] "Nexora Lang" — the lightweight custom programming language mentioned in the brief (a small interpreter shipped as `nexora-lang`; purpose: educational scripting + a unified config format for NexoraOS components).

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

- [ ] ARM SBC images (Raspberry Pi 5, Orange Pi)
- [ ] RISC-V experimental image
- [ ] Nexora Phone (mobile UI variant on Phosh)
- [ ] NexoraOS Server edition (no DE, web admin UI only)

## Out of scope (for now)

- Building the kernel from source. The kernel ships as Arch's prebuilt `linux` package; we apply no patches at this stage. This can be revisited in v2026.3+ if specific patches are needed.
- A from-scratch package manager. pacman + AUR is the foundation.
- Replacing systemd. systemd is the init system for the foreseeable future; a `runit`/`openrc` variant would be a separate subproject.
