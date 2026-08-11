# Build Guide

## Quick start (CI)

1. Push to `main`. Watch the **Build NexoraOS ISO** workflow.
2. On success, find the ISO under [Releases](https://github.com/salom600/osbeta/releases).
3. On failure, an issue opens automatically; `auto-fix.yml` runs and proposes a PR.

## Local build on Arch Linux

```bash
sudo pacman -S --needed archiso archlinux-keyring docker
git clone https://github.com/salom600/osbeta.git
cd osbeta

# Build inside Docker (recommended on non-Arch hosts too)
./scripts/build-local.sh --docker

# Or build natively (requires Arch host + archiso package)
./scripts/build-local.sh
```

Output: `out/nexora-<version>-x86_64.iso` (+ `.sha256sum` + `build.log`).

## Smoke-test in QEMU

```bash
./scripts/test-iso.sh bios    # BIOS boot
./scripts/test-iso.sh uefi    # UEFI boot (requires OVMF)
```

## Manual workflow dispatch (with custom tag)

1. Go to **Actions → Build NexoraOS ISO → Run workflow**.
2. Set `version_tag` (e.g. `2026.1-rc1`) and `make_release: true`.
3. The workflow runs, builds, and creates a release tagged `v2026.1-rc1`.

## Iterating on NexoraDE scripts without rebuilding the ISO

```bash
./scripts/dev-setup.sh    # installs deps
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
   - `target not found: <pkg>` — package no longer in repos; remove from `packages.x86_64`.
   - PGP signature errors — keyring out of date; the workflow already does `pacman-key --populate`. If still failing, add `pacman-key --refresh-keys`.
   - Disk full in Actions runner — `--free disk space` step should help; if still failing, trim large packages (libreoffice-fresh, jdk*, etc.).
   - Docker `permission denied` — make sure the `--privileged` flag is present (it is).

3. The `auto-fix.yml` workflow already handles the most common cases automatically.

## Reproducibility

- The build uses the official `archlinux:latest` Docker image at build time, so package versions are pinned to whatever was in the Arch repos on the build date.
- For bit-for-bit reproducible ISOs you'd need to pin specific package versions; out of scope for the beta.

## Output naming convention

- ISO: `nexora-<version>-x86_64.iso`
- Checksum: `nexora-<version>-x86_64.iso.sha256sum`
- Build log: `build.log`
- Release tag: `v<version>` (e.g. `v2026.1-beta1`)
