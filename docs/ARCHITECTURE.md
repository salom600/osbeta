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
│  Xorg (default) · Wayland/labwc (optional) · libinput · Wacom│
├──────────────────────────────────────────────────────────────┤
│                       Multimedia stack                        │
│  PipeWire · WirePlumber · PulseAudio compat · Bluetooth audio│
├──────────────────────────────────────────────────────────────┤
│                      Hardware drivers                         │
│  mesa · Vulkan-{radeon,intel} · xf86-video-{amdgpu,ati,      │
│  intel,nouveau,vesa,fbdev} · NVIDIA DKMS · libinput          │
├──────────────────────────────────────────────────────────────┤
│                          Base system                          │
│  Arch Linux · Linux 6.x kernel · systemd · pacman · glibc    │
├──────────────────────────────────────────────────────────────┤
│                         Boot stack                            │
│  BIOS: syslinux + isohybrid · UEFI: systemd-boot + GRUB      │
└──────────────────────────────────────────────────────────────┘
```

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
2. **syslinux** (BIOS) or **systemd-boot** (UEFI) loads `vmlinuz-linux` + `initramfs-linux.img` + CPU microcode.
3. **mkinitcpio** with the `archiso` hook:
   - Mounts the ISO (`archisolabel=NEXORA_YYYYMM`).
   - Loads the squashfs (`airootfs.sfs`) as the lower layer.
   - Creates a tmpfs upper layer + persistent overlay file (`cow_spacesize=4G`) for live USB writes.
4. **systemd** boots to `graphical.target`.
5. **lightdm** autologins `nexora` and starts the `nexora` X session.
6. **nexora-session** launches Openbox + nexora-panel + helpers.

## Install flow (Calamares)

1. User clicks **Install NexoraOS**.
2. Calamares runs `welcome → locale → keyboard → partition → users → summary`.
3. **exec** stage:
   - `partition` creates partitions per layout (boot ext4 + root btrfs by default).
   - `mount` mounts target at `/target`.
   - `unpackfs` copies the squashfs content into `/target` (this is the base system).
   - `fstab` writes `/etc/fstab` for the new system.
   - `initcpiocfg` + `initcpio` regenerate initramfs for the installed kernel.
   - `users` creates the user, sets password, adds to groups.
   - `displaymanager` enables lightdm with autologin for the new user.
   - `networkcfg` copies NetworkManager config.
   - `services-systemd` enables NetworkManager, lightdm, bluetooth, etc.
   - `packages` runs `pacman -S --needed` for the meta-packages (idempotent).
   - `bootloader` installs GRUB to the target disk (BIOS) or ESP (UEFI).
   - `shellprocess@nexora-finalize` runs the post-install chroot script.
4. **finished** screen → reboot.

## GitHub Actions build pipeline

```
┌─────────────────┐
│   push to main  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  build-iso.yml (ubuntu-latest)      │
│                                     │
│  1. Free disk space                 │
│  2. docker run archlinux:latest     │
│       - pacman -Sy archiso          │
│       - pacman-key --init           │
│       - mkarchiso -v -w work -o out │
│  3. Upload ISO as artifact          │
│  4. Create release (softprops)      │
└────────┬────────────────────────────┘
         │
    ┌────┴────┐
    │         │
 success   failure
    │         │
    │         ▼
    │   ┌────────────────────────────────┐
    │   │  report-failure job:           │
    │   │  open issue (build-failure.md) │
    │   └────────────┬───────────────────┘
    │                │
    │                ▼
    │   ┌────────────────────────────────┐
    │   │  auto-fix.yml                  │
    │   │                                │
    │   │  1. gh run view --log-failed   │
    │   │  2. python: match patterns     │
    │   │  3. patch files                │
    │   │  4. push branch                │
    │   │  5. gh pr create + merge       │
    │   └────────────┬───────────────────┘
    │                │
    │                ▼
    └──────────► (re-triggers build-iso.yml)
```

## File permissions model

The live ISO runs as user `nexora` (uid 1000), member of:
`wheel, storage, power, network, video, audio, input, lp, autologin`.

- `wheel` → passwordless sudo on the live ISO (so users can install packages without prompt friction).
- After install, Calamares removes the `NOPASSWD` sudoers file and the user must use their password.

## Security

- The live user has password `nexora` (auto-login, no prompt) — documented in the welcome screen.
- After install, the user picks their own password; the live user is removed by `removeuser` module.
- `ufw` and `firejail` are preinstalled but not enabled by default (user enables via nexora-settings → System).
- `fail2ban` is preinstalled and enabled for `sshd` (which is *not* enabled by default).
