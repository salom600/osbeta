#!/bin/bash
#
# kernel/build.sh — build a custom NexoraOS Linux kernel as Debian .deb packages
#
# Builds Linux 6.12 LTS (vanilla) with our custom .config + patch set.
# Produces:
#   linux-image-6.12.<x>-nexora1_6.12.<x>-nexora1-1_amd64.deb
#   linux-headers-6.12.<x>-nexora1_6.12.<x>-nexora1-1_amd64.deb
#   linux-libc-dev_6.12.<x>-nexora1-1_amd64.deb
#
# Usage:
#   ./kernel/build.sh                  # build latest 6.12.x
#   KVER=6.12.10 ./kernel/build.sh     # build specific version
#
# Requirements (host): build-essential, libssl-dev, libelf-dev, bc, cpio,
#                      kmod, rsync, wget, ccache, debhelper, flex, bison
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KVER="${KVER:-6.12.10}"
KMAJOR="${KVER%.*}"        # e.g. 6.12
SRC_URL="https://cdn.kernel.org/pub/linux/kernel/v${KMAJOR%%.*}.x/linux-${KVER}.tar.xz"
WORK_DIR="${WORK_DIR:-$ROOT/work/kernel}"
OUT_DIR="${OUT_DIR:-$ROOT/work/kernel-out}"

echo "==> NexoraOS kernel build"
echo "    Version: $KVER"
echo "    Work:    $WORK_DIR"
echo "    Output:  $OUT_DIR"

mkdir -p "$WORK_DIR" "$OUT_DIR"
cd "$WORK_DIR"

# ---- 1. Download + extract source ----
if [ ! -d "linux-${KVER}" ]; then
    echo "==> Downloading $SRC_URL..."
    wget -q --show-progress "$SRC_URL" -O "linux-${KVER}.tar.xz"
    echo "==> Extracting..."
    tar xf "linux-${KVER}.tar.xz"
fi

cd "linux-${KVER}"

# ---- 2. Apply patches ----
PATCH_DIR="$ROOT/kernel/patches"
if [ -d "$PATCH_DIR" ] && [ -n "$(ls -A "$PATCH_DIR" 2>/dev/null)" ]; then
    echo "==> Applying patches from $PATCH_DIR..."
    for p in "$PATCH_DIR"/*.patch; do
        echo "    - $(basename "$p")"
        patch -p1 --forward < "$p" || {
            echo "ERROR: patch $(basename "$p") failed"
            exit 1
        }
    done
else
    echo "==> No patches to apply."
fi

# ---- 3. Copy our config ----
echo "==> Installing NexoraOS .config..."
cp "$ROOT/kernel/configs/x86_64_defconfig" .config

# Let the kernel fill in defaults for any options we didn't specify
make olddefconfig

# Sanity check: print key responsiveness knobs
echo "==> Effective config (key options):"
grep -E "^(CONFIG_HZ|CONFIG_PREEMPT|CONFIG_DEFAULT_TCP_CONG|CONFIG_CPU_FREQ_DEFAULT|CONFIG_MQ_IOSCHED_BFQ|CONFIG_LOCALVERSION)=" .config

# ---- 4. Enable ccache if available ----
if command -v ccache >/dev/null; then
    echo "==> Enabling ccache..."
    export CC="ccache gcc"
    export HOSTCC="ccache gcc"
    ccache -M 5G 2>/dev/null || true
fi

# ---- 5. Build + produce .deb packages ----
echo "==> Building kernel (this takes ~30-60 min on 4 cores)..."
NPROC=$(nproc)
make -j"$NPROC" bindeb-pkg \
    LOCALVERSION="-nexora1" \
    KDEB_PKGVERSION="${KVER}-nexora1-1" \
    KBUILD_DEBARCH=amd64

# ---- 6. Move artifacts to OUT_DIR ----
echo "==> Collecting .deb packages..."
cd "$WORK_DIR"
for f in linux-image-${KVER}-nexora1_*.deb \
         linux-headers-${KVER}-nexora1_*.deb \
         linux-libc-dev_${KVER}-nexora1-1_*.deb \
         linux-image-${KVER}-nexora1-dbg_*.deb; do
    if [ -f "$f" ]; then
        mv "$f" "$OUT_DIR/"
        echo "    -> $(basename "$f")"
    fi
done

echo "==> Done. .deb packages in $OUT_DIR:"
ls -lh "$OUT_DIR"/*.deb

# Generate checksums
cd "$OUT_DIR"
sha256sum *.deb > checksums.sha256
echo "    -> checksums.sha256"
