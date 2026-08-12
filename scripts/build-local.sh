#!/bin/bash
#
# scripts/build-local.sh — build the NexoraOS ISO locally
#
# Usage:
#   ./scripts/build-local.sh                  # build kernel + ISO
#   ./scripts/build-local.sh --kernel-only    # build just the kernel .deb
#   ./scripts/build-local.sh --iso-only       # build just the ISO (assumes kernel is built)
#   ./scripts/build-local.sh --clean          # clean work/ and out/ first
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="all"
CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    --kernel-only) MODE="kernel" ;;
    --iso-only) MODE="iso" ;;
    *) echo "Unknown arg: $arg" >&2 ;;
  esac
done

if [ "$CLEAN" = "1" ]; then
  echo "==> Cleaning work/ and out/"
  sudo rm -rf "$ROOT/work" "$ROOT/out"
  rm -rf "$ROOT/debian-live/.build"
  (cd "$ROOT/debian-live" && lb clean 2>/dev/null || true)
fi

mkdir -p "$ROOT/work" "$ROOT/out"

if [ "$MODE" = "all" ] || [ "$MODE" = "kernel" ]; then
  echo "==> Building kernel .deb packages..."
  (cd "$ROOT" && ./kernel/build.sh)
fi

if [ "$MODE" = "all" ] || [ "$MODE" = "iso" ]; then
  echo "==> Building ISO via live-build (in Docker)..."
  (cd "$ROOT" && ./debian-live/build.sh)
fi

echo "==> Done. Output in $ROOT/out/:"
ls -lh "$ROOT/out/"*.iso 2>/dev/null || echo "(no ISO produced)"
