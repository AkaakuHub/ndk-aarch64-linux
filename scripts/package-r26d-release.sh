#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_ROOT:?Set SOURCE_ROOT to the Android LLVM source root}"
: "${NDK_R26D:?Set NDK_R26D to the official Android NDK r26d root}"
: "${RELEASE_DIR:=./ndk-r26d-release}"

SRC_STAGE="$SOURCE_ROOT/out/stage2"
PKGROOT="$RELEASE_DIR/package-root"
NAME="android-ndk-r26d-linux-aarch64-host-tools-unofficial"
ARCHIVE="$RELEASE_DIR/$NAME.tar.zst"

case "$RELEASE_DIR" in
  ""|"/"|"/home"|"/home/"|"/tmp"|"/tmp/")
    echo "Refusing suspicious RELEASE_DIR: $RELEASE_DIR" >&2
    exit 1
    ;;
esac

test -d "$SOURCE_ROOT/toolchain/llvm_android" || { echo "SOURCE_ROOT does not look like an Android LLVM source root: $SOURCE_ROOT"; exit 1; }
test -d "$NDK_R26D/toolchains/llvm/prebuilt/linux-x86_64" || { echo "NDK_R26D does not look like r26d NDK root: $NDK_R26D"; exit 1; }

rm -rf "$PKGROOT"
mkdir -p "$RELEASE_DIR" \
  "$PKGROOT/toolchains/llvm/prebuilt/linux-x86_64/bin" \
  "$PKGROOT/toolchains/llvm/prebuilt/linux-x86_64/lib" \
  "$PKGROOT/LICENSES"

test -x "$SRC_STAGE/bin/clang" || { echo "missing $SRC_STAGE/bin/clang"; exit 1; }
test -x "$SRC_STAGE/bin/clang++" || { echo "missing $SRC_STAGE/bin/clang++"; exit 1; }
test -x "$SRC_STAGE/bin/ld.lld" || { echo "missing $SRC_STAGE/bin/ld.lld"; exit 1; }
test -f "$SRC_STAGE/lib/libxml2.so.16" || { echo "missing $SRC_STAGE/lib/libxml2.so.16"; exit 1; }
test -f "$SOURCE_ROOT/toolchain/llvm-project/LICENSE.TXT" || { echo "missing LLVM LICENSE.TXT"; exit 1; }

cp -a "$SRC_STAGE/bin/." "$PKGROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/"
cp -a "$SRC_STAGE/lib/libxml2.so.16" "$PKGROOT/toolchains/llvm/prebuilt/linux-x86_64/lib/libxml2.so.16"

cat > "$PKGROOT/BUILD_INFO.txt" <<INFO
Android NDK r26d Linux AArch64 host-tools overlay

Official NDK: 26.3.11579264 / r26d
Clang: Android clang 17.0.2, based on r487747e
LLVM base revision: c4c5e79dd4b4c78eee7cffd9b0d7394b5bedcf12
Android llvm_android revision: 0f058ab00ec6c9b8b39956c1393bcc405a5498d3
Host: Linux AArch64
Overlay target: toolchains/llvm/prebuilt/linux-x86_64/

This is not an official Google or Android NDK release.
INFO

cp -a "$SOURCE_ROOT/toolchain/llvm-project/LICENSE.TXT" "$PKGROOT/LICENSES/LLVM-LICENSE.TXT"

for f in \
  "$SOURCE_ROOT/toolchain/llvm-project/NOTICE.TXT" \
  "$SOURCE_ROOT/toolchain/llvm-project/NOTICE" \
  "$NDK_R26D/NOTICE" \
  "$NDK_R26D/NOTICE.txt" \
  "$NDK_R26D/LICENSE" \
  "$NDK_R26D/LICENSE.txt"; do
  [ -f "$f" ] && cp -a "$f" "$PKGROOT/LICENSES/$(basename "$f")"
done

cat > "$PKGROOT/LICENSES/README.txt" <<LICENSEINFO
This overlay is built from Android's LLVM/Clang toolchain sources and is distributed with the available LLVM, Android NDK, and third-party license/notice files copied from the source tree and official NDK package.

Before publishing, inspect this directory and add any missing license or notice file required by your exact binary contents.
LICENSEINFO

cd "$PKGROOT"
find . -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.contents
cd - >/dev/null

tar --zstd -C "$PKGROOT" -cf "$ARCHIVE" .

cd "$RELEASE_DIR"
sha256sum "$(basename "$ARCHIVE")" > SHA256SUMS
cp "$PKGROOT/BUILD_INFO.txt" "$RELEASE_DIR/BUILD_INFO.txt"

cat > "$RELEASE_DIR/RELEASE_NOTES.md" <<NOTES
# Android NDK r26d Linux AArch64 host tools

Unofficial host-tools overlay for Android NDK r26d \`26.3.11579264\`.

This release is not an official Google or Android NDK release.

Install the official NDK r26d first, then extract this archive on top of the NDK root.

The overlay keeps the official NDK \`toolchains/llvm/prebuilt/linux-x86_64\` path name for compatibility, but the included host executables are Linux AArch64 binaries.
NOTES

ls -lh "$RELEASE_DIR"
sha256sum -c "$RELEASE_DIR/SHA256SUMS"
