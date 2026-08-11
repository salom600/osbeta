#!/bin/bash
#
# scripts/build-local.sh — build the NexoraOS ISO locally (Arch Linux host)
#
# Usage:
#   ./scripts/build-local.sh                # build, output to ./out/
#   ./scripts/build-local.sh --clean        # clean work/ and out/ first
#   ./scripts/build-local.sh --docker       # build inside Docker container
#
# Requirements (host): archiso, archlinux-keyring, docker (for --docker mode)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="$ROOT/archiso/profile"
WORK_DIR="$ROOT/work"
OUT_DIR="$ROOT/out"
VERSION="${VERSION:-$(date +%Y.%m.%d)-local}"

# Parse args
MODE="host"
CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    --docker) MODE="docker" ;;
    *) echo "Unknown arg: $arg" >&2 ;;
  esac
done

if [ "$CLEAN" = "1" ]; then
  echo "==> Cleaning work/ and out/"
  sudo rm -rf "$WORK_DIR" "$OUT_DIR"
fi

mkdir -p "$WORK_DIR" "$OUT_DIR"

# Patch version
sed -i "s/^iso_version=.*/iso_version=\"$VERSION\"/" "$PROFILE_DIR/profiledef.sh"

if [ "$MODE" = "docker" ]; then
  echo "==> Building inside Docker container..."
  docker run --rm -v "$ROOT":/work -w /work --privileged \
    -e ISO_VERSION="$VERSION" \
    archlinux:latest \
    bash -euo pipefail -c '
      sed -i "s/^#ParallelDownloads.*/ParallelDownloads = 8/" /etc/pacman.conf
      pacman -Sy --noconfirm --needed archiso archlinux-keyring sudo grub syslinux mtools dosfstools squashfs-tools
      pacman-key --init && pacman-key --populate archlinux
      mkarchiso -v -w ./work -o ./out ./archiso/profile
    '
else
  echo "==> Building on host (requires Arch Linux + archiso)..."
  command -v mkarchiso >/dev/null || { echo "mkarchiso not installed. Install 'archiso'."; exit 1; }
  sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"
fi

echo "==> Done. ISO:"
ls -lh "$OUT_DIR"/*.iso 2>/dev/null || echo "(no ISO produced)"
