#!/bin/bash
#
# scripts/test-iso.sh — boot the ISO in QEMU for smoke testing
#
# Usage:
#   ./scripts/test-iso.sh [bios|uefi]
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO=$(ls "$ROOT"/out/*.iso 2>/dev/null | head -1 || true)
if [ -z "$ISO" ]; then
  echo "No ISO found in $ROOT/out/ — run build-local.sh first."
  exit 1
fi

MODE="${1:-bios}"
RAM="${RAM:-2048}"
CPUS="${CPUS:-2}"

echo "==> Booting $(basename "$ISO") in QEMU ($MODE mode, ${RAM}MB RAM, $CPUS CPU)"
echo "    (Ctrl-Alt-G to release mouse; close window to stop)"

case "$MODE" in
  bios)
    qemu-system-x86_64 \
      -enable-kvm \
      -m "$RAM" \
      -smp "$CPUS" \
      -cdrom "$ISO" \
      -boot d \
      -vga virtio \
      -netdev user,id=net0 -device virtio-net,netdev=net0 \
      -display gtk
    ;;
  uefi)
    if [ ! -f /usr/share/OVMF/OVMF_CODE.fd ]; then
      echo "UEFI boot requires OVMF. Install with: sudo apt install ovmf"
      exit 1
    fi
    cp /usr/share/OVMF/OVMF_VARS.fd /tmp/OVMF_VARS.fd 2>/dev/null || true
    qemu-system-x86_64 \
      -enable-kvm \
      -m "$RAM" \
      -smp "$CPUS" \
      -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
      -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
      -cdrom "$ISO" \
      -boot d \
      -vga virtio \
      -netdev user,id=net0 -device virtio-net,netdev=net0 \
      -display gtk
    ;;
  *) echo "Unknown mode: $MODE (use 'bios' or 'uefi')"; exit 1 ;;
esac
