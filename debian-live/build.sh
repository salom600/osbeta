#!/bin/bash
#
# debian-live/build.sh — build the NexoraOS ISO using Debian live-build
#
# Produces a hybrid BIOS+UEFI live ISO with NexoraDE preinstalled.
#
# Usage:
#   ./debian-live/build.sh                  # build with latest kernel .deb from ../work/kernel-out
#   KERNEL_DIR=/path/to/debs ./debian-live/build.sh
#
# Requirements (host): live-build, debian-archive-keyring, sudo, wget
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE_DIR="$ROOT/debian-live"
KERNEL_DIR="${KERNEL_DIR:-$ROOT/work/kernel-out}"
WORK_DIR="${WORK_DIR:-$LIVE_DIR/.build}"
OUT_DIR="${OUT_DIR:-$ROOT/out}"

VERSION="${VERSION:-$(date +%Y.%m.%d)}"
ISO_NAME="${ISO_NAME:-nexora}"
ISO_LABEL="${ISO_LABEL:-NEXORA_$(date +%Y%m)}"

echo "==> NexoraOS ISO build"
echo "    Version:   $VERSION"
echo "    Live dir:  $LIVE_DIR"
echo "    Kernel:    $KERNEL_DIR"
echo "    Output:    $OUT_DIR"

mkdir -p "$OUT_DIR"
cd "$LIVE_DIR"

# ---- 1. Clean previous build ----
echo "==> Cleaning previous build..."
lb clean || true
rm -rf "$WORK_DIR" .build
rm -rf config/packages.chroot/*.deb 2>/dev/null || true

# ---- 2. Install custom kernel .deb packages (if present) ----
if [ -d "$KERNEL_DIR" ] && ls "$KERNEL_DIR"/*.deb >/dev/null 2>&1; then
    echo "==> Installing custom kernel .deb packages..."
    cp "$KERNEL_DIR"/*.deb config/packages.chroot/
    ls -1 config/packages.chroot/*.deb | while read -r f; do
        echo "    -> $(basename "$f")"
    done
else
    echo "==> WARNING: No custom kernel .deb found in $KERNEL_DIR"
    echo "    The ISO will use Debian's stock linux-image-amd64 kernel instead."
fi

# ---- 3. Configure live-build ----
echo "==> Configuring live-build..."
# Note: --squashfs-comp was removed in newer live-build; the --compression flag
# handles chroot compression. Squashfs compression is configured separately.
lb config \
    --distribution trixie \
    --architecture amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootloaders "grub-pc grub-efi" \
    --binary-images iso-hybrid \
    --iso-volume "$ISO_LABEL" \
    --iso-application "NexoraOS $VERSION" \
    --iso-publisher "NexoraOS Project <https://github.com/salom600/osbeta>" \
    --image-name "$ISO_NAME-$VERSION" \
    --debian-installer live \
    --debian-installer-gui true \
    --chroot-filesystem squashfs \
    --compression zstd \
    --memtest none \
    --updates true \
    --security true \
    --backports false

# Configure squashfs compression (live-build reads this from a separate file)
echo "zstd" > config/squashfs-compression

# ---- 4. Build the ISO ----
echo "==> Building ISO (this takes ~10-20 min)..."
sudo lb build 2>&1 | tee "$OUT_DIR/build.log"

# ---- 5. Move ISO to OUT_DIR ----
ISO_FILE="$LIVE_DIR/${ISO_NAME}-${VERSION}-amd64.iso"
if [ -f "$ISO_FILE" ]; then
    echo "==> Built ISO: $(basename "$ISO_FILE")"
    mv "$ISO_FILE" "$OUT_DIR/"
    sha256sum "$OUT_DIR/$(basename "$ISO_FILE")" > "$OUT_DIR/$(basename "$ISO_FILE").sha256sum"
    echo "    -> $OUT_DIR/$(basename "$ISO_FILE")"
    echo "    -> $OUT_DIR/$(basename "$ISO_FILE").sha256sum"
    ls -lh "$OUT_DIR/"
else
    echo "ERROR: ISO not produced. Check $OUT_DIR/build.log"
    exit 1
fi
