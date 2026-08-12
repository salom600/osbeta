# Build Guide

## Quick start (CI)

1. Push to `main`. Watch the **Lint** workflow first.
2. If lint passes, **Build custom kernel** and **Build NexoraOS ISO** run.
3. On success, find artifacts at:
   - Kernel `.deb`: https://github.com/salom600/osbeta/releases (tagged `kernel-v*`)
   - ISO: https://github.com/salom600/osbeta/releases (tagged `v*`)
4. On failure, an issue opens automatically; `auto-fix.yml` runs and proposes a PR.

## Local build

### Build the kernel (Linux 6.12 LTS .deb)

Requirements: build-essential, libssl-dev, libelf-dev, bc, cpio, kmod, ccache, wget.

```bash
# On Debian/Ubuntu host:
sudo apt install build-essential libssl-dev libelf-dev bc cpio kmod rsync wget ccache

# On Arch host:
sudo pacman -S base-devel libelf openssl ccache wget

# Build:
./kernel/build.sh                # builds Linux 6.12.10 (default)
KVER=6.12.10 ./kernel/build.sh   # explicit version

# Output:
ls -lh work/kernel-out/
# linux-image-6.12.10-nexora1_6.12.10-nexora1-1_amd64.deb
# linux-headers-6.12.10-nexora1_6.12.10-nexora1-1_amd64.deb
# linux-libc-dev_6.12.10-nexora1-1_amd64.deb
```

Build time: ~45-90 min on first run, ~20-30 min with ccache on rebuilds.

### Build the ISO

Requirements: Docker (we build inside a `debian:trixie` container).

```bash
# Ensure the kernel .deb packages exist at work/kernel-out/
ls work/kernel-out/*.deb

# Build:
./debian-live/build.sh

# Output:
ls -lh out/
# nexora-<version>-amd64.iso
# nexora-<version>-amd64.iso.sha256sum
# build.log
```

### Smoke-test in QEMU

```bash
./scripts/test-iso.sh bios    # BIOS boot
./scripts/test-iso.sh uefi    # UEFI boot (requires OVMF)
```

## Manual workflow dispatch

1. Go to **Actions → Build NexoraOS ISO → Run workflow**.
2. Set `version_tag` (e.g. `2026.1-rc1`) and `make_release: true`.
3. Set `use_custom_kernel: true` to download the latest kernel .deb from CI artifacts.
4. The workflow runs, builds, and creates a release tagged `v2026.1-rc1`.

## Iterating on NexoraDE scripts without rebuilding the ISO

```bash
./scripts/dev-setup.sh    # installs deps on Debian/Ubuntu
./nexora-de/bin/nexora-panel       # test panel
./nexora-de/bin/nexora-launcher    # test launcher (W-r in Openbox)
./nexora-de/bin/nexora-settings    # test settings
./nexora-de/bin/nexora-store       # test app store
```

To test inside an existing Openbox session, add to `~/.config/openbox/autostart`:
```bash
/usr/local/bin/nexora-panel &
```

## Debugging a build failure

1. Download the `build.log` artifact from the failed run.
2. Common issues:
   - `E: Unable to locate package <pkg>` — package not in trixie; remove from `nexora.list.chroot`.
   - PGP signature errors — apt keyring out of date; the build installs `debian-archive-keyring` fresh.
   - Disk full in Actions runner — the `Free disk space` step should help; trim large packages (nvidia-driver, linux-image-amd64 + headers).
   - `debootstrap` failed — usually network or mirror issue; check `build.log` for the failing URL.

3. The `auto-fix.yml` workflow already handles the most common cases automatically.

## Output naming convention

- Kernel: `linux-image-<kver>-nexora1_<kver>-nexora1-1_amd64.deb`
- ISO: `nexora-<version>-amd64.iso`
- Checksum: `nexora-<version>-amd64.iso.sha256sum`
- Build log: `build.log`
- Kernel release tag: `kernel-v<kver>` (e.g. `kernel-v6.12.10`)
- ISO release tag: `v<version>` (e.g. `v2026.1-beta1`)
