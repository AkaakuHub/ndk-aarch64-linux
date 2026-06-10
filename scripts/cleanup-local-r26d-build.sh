#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dry-run}"
: "${SOURCE_ROOT:?Set SOURCE_ROOT to the Android LLVM source root}"
: "${NDK_R26D:?Set NDK_R26D to the official Android NDK r26d root}"
: "${RELEASE_DIR:=./ndk-r26d-release}"

NDKPRE="$NDK_R26D/toolchains/llvm/prebuilt/linux-x86_64"

test -d "$SOURCE_ROOT/toolchain/llvm_android" || { echo "SOURCE_ROOT does not look like an Android LLVM source root: $SOURCE_ROOT"; exit 1; }
test -d "$NDKPRE" || { echo "NDK_R26D does not look like r26d NDK root: $NDK_R26D"; exit 1; }

fixed_paths=(
  "$SOURCE_ROOT"
  "$RELEASE_DIR/package-root"
)

backup_globs=(
  "$NDKPRE/bin.x86_64.backup-*"
  "$NDKPRE/lib.backup-*"
)

echo "Mode: $MODE"
echo

echo "Fixed paths:"
for p in "${fixed_paths[@]}"; do
  [ -e "$p" ] && du -sh "$p" || true
done

echo
echo "Backup directories:"
for pat in "${backup_globs[@]}"; do
  for p in $pat; do
    [ -e "$p" ] && du -sh "$p" || true
  done
done

if [ "$MODE" != "delete" ]; then
  echo
  echo "Dry run only. Re-run with:"
  echo "  $0 delete"
  exit 0
fi

echo
echo "Deleting listed paths..."
for p in "${fixed_paths[@]}"; do
  [ -e "$p" ] && rm -rf -- "$p"
done

for pat in "${backup_globs[@]}"; do
  for p in $pat; do
    [ -e "$p" ] && rm -rf -- "$p"
  done
done

echo "Done."
