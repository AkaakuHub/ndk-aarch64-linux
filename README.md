# How to Build Android NDK r26d Host Tools on AArch64 Linux

This branch documents an unofficial Linux AArch64 host-tools overlay for Android NDK r26d.

This is not an official Google or Android NDK release.

## Target

```text
Android NDK: r26d
Pkg.Revision: 26.3.11579264
Clang: Android clang 17.0.2, based on r487747e
LLVM base revision: c4c5e79dd4b4c78eee7cffd9b0d7394b5bedcf12
Android llvm_android revision: 0f058ab00ec6c9b8b39956c1393bcc405a5498d3
Host: Linux AArch64
Verified Android ABI: arm64-v8a
```

The goal is to run the NDK host tools natively on Linux AArch64 while keeping the official NDK r26d layout.

The overlay intentionally keeps this directory name:

```text
toolchains/llvm/prebuilt/linux-x86_64/
```

That path is part of the official NDK layout expected by Android Gradle Plugin, CMake, and the NDK toolchain file. The path name does not imply that the host executables are x86_64. In this overlay, the executables inside `bin/` are Linux AArch64 binaries.

## Clone Source Code

```shell
cd ${SOURCE_ROOT_PARENT}
repo init -u https://android.googlesource.com/platform/manifest -b llvm-toolchain
repo sync -c
```

Then check out the r26d toolchain revisions:

```shell
cd ${SOURCE_ROOT}/toolchain/llvm_android
git checkout 0f058ab00ec6c9b8b39956c1393bcc405a5498d3

cd ${SOURCE_ROOT}/toolchain/llvm-project
git checkout c4c5e79dd4b4c78eee7cffd9b0d7394b5bedcf12
```

## Prepare Environment

Install host tools and libraries:

```shell
sudo apt update
sudo apt install -y build-essential cmake ninja-build python3 rsync zstd libc++-dev libc++abi-dev libz-dev libxml2-dev
```

Use an official Android NDK r26d installation as the base NDK:

```text
${ANDROID_SDK_ROOT}/ndk/26.3.11579264
```

## Modify Build Scripts

The local patch summary is in [`diff.txt`](./diff.txt). The important points are:

- use host Python instead of x86 prebuilt Python;
- use AArch64 host CMake/Ninja/toolchain paths;
- set the Linux host triple to `aarch64-unknown-linux-gnu`;
- ensure stage1 builds AArch64 support;
- keep stage1 runtimes disabled;
- skip Windows, LLDB, tests, and musl paths;
- avoid running generated host tools through qemu.

## Build the Toolchain

```shell
cd ${SOURCE_ROOT}
export PYTHONPATH="$PWD/external/toolchain-utils${PYTHONPATH:+:$PYTHONPATH}"
python3 toolchain/llvm_android/build.py \
  --incremental \
  --no-build windows,lldb \
  --skip-tests \
  --no-musl \
  --skip-runtimes
```

The complete stage2 build may still fail late while building `builtins-i386-unknown-linux-gnu` if the AArch64 host does not have an i386 glibc sysroot/header setup. For this overlay, the required host executables were already produced before that failure under:

```text
${SOURCE_ROOT}/out/stage2/bin
```

The tested release package uses `out/stage2/bin` and `out/stage2/lib/libxml2.so.16`.

## Modify Android NDK r26d

Back up the official NDK host `bin` directory and original libxml2 files, then overlay the AArch64 host tools:

```shell
NDK_R26D=${ANDROID_SDK_ROOT}/ndk/26.3.11579264
NDKPRE=${NDK_R26D}/toolchains/llvm/prebuilt/linux-x86_64
NDKBIN=${NDKPRE}/bin
NDKLIB=${NDKPRE}/lib
TS=$(date +%Y%m%d%H%M%S)

cp -a "$NDKBIN" "$NDKPRE/bin.x86_64.backup-$TS"
mkdir -p "$NDKPRE/lib.backup-$TS"
cp -a "$NDKLIB"/libxml2.so* "$NDKPRE/lib.backup-$TS/" 2>/dev/null || true

cp -a "${SOURCE_ROOT}/out/stage2/bin/." "$NDKBIN/"
cp -a "${SOURCE_ROOT}/out/stage2/lib/libxml2.so.16" "$NDKLIB/libxml2.so.16"
```

## SDK-side tools

NDK host tools alone are not enough for full Android Gradle builds on Linux AArch64. The SDK-side tools also need to be Linux AArch64 binaries or wrappers:

```text
build-tools/<version>/aapt2
build-tools/<version>/aapt
build-tools/<version>/aidl
build-tools/<version>/zipalign
cmake/<version>/bin/cmake
cmake/<version>/bin/ninja
```

If the SDK CMake package contains x86_64 `cmake` and `ninja`, replace them with AArch64 host tools while keeping the SDK path stable:

```shell
SDK=${ANDROID_SDK_ROOT}
CMAKEBIN=${SDK}/cmake/3.22.1/bin
TS=$(date +%Y%m%d%H%M%S)

cp -a "$CMAKEBIN" "${SDK}/cmake/3.22.1/bin.x86_64.backup-$TS"
mv "$CMAKEBIN/cmake" "$CMAKEBIN/cmake.x86_64"
mv "$CMAKEBIN/ninja" "$CMAKEBIN/ninja.x86_64"
ln -s /usr/bin/cmake "$CMAKEBIN/cmake"
ln -s /usr/bin/ninja "$CMAKEBIN/ninja"
```

For Gradle/AGP, force AArch64 `aapt2` instead of Maven's x86_64 `aapt2`:

```shell
export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/34.0.0/aapt2 ${GRADLE_OPTS:-}"
```

## Verify

See [`VERIFY.md`](./VERIFY.md).

The key checks are:

```shell
file -L ${NDK_R26D}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
ps -ef | grep -Ei 'qemu|box64|box86|rosetta' | grep -v grep || true
```

Expected:

```text
clang: ELF 64-bit ... ARM aarch64
qemu process list: empty
```

## Package a release

See [`RELEASE.md`](./RELEASE.md) and [`scripts/package-r26d-release.sh`](./scripts/package-r26d-release.sh).

The recommended asset name is:

```text
android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst
```

The archive is an overlay for an official NDK r26d installation. It is not a full NDK mirror.

## Cleanup

See [`CLEANUP.md`](./CLEANUP.md). Run the cleanup script in dry-run mode first.
