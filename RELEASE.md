# Release procedure

This repository branch contains documentation and helper scripts. Binary assets should be uploaded through GitHub Releases, not committed to Git.

The packaging script creates release files locally. It does not upload anything by itself.

## 1. Package the overlay

From a machine where the r26d AArch64 host tools were built:

```sh
export SOURCE_ROOT=/path/to/aosp-llvm-r26d
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
export NDK_R26D=${ANDROID_SDK_ROOT}/ndk/26.3.11579264
export RELEASE_DIR=/path/to/release-output

./scripts/package-r26d-release.sh
```

Expected outputs:

```text
android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst
SHA256SUMS
BUILD_INFO.txt
RELEASE_NOTES.md
```

## 2. Inspect the archive

```sh
cd ${RELEASE_DIR}
ls -lh
sha256sum -c SHA256SUMS
tar --zstd -tf android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst | sed -n '1,120p'
```

Expected archive structure:

```text
toolchains/llvm/prebuilt/linux-x86_64/bin/...
toolchains/llvm/prebuilt/linux-x86_64/lib/libxml2.so.16
BUILD_INFO.txt
LICENSES/...
```

## 3. Create or upload a GitHub Release

Use GitHub CLI on the machine with the archive.

```sh
cd ${RELEASE_DIR}

gh auth status || gh auth login

gh release create r26d-linux-aarch64-host-tools \
  android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst \
  SHA256SUMS \
  BUILD_INFO.txt \
  --repo AkaakuHub/ndk-aarch64-linux \
  --target r26 \
  --title "Android NDK r26d Linux AArch64 host tools" \
  --notes-file RELEASE_NOTES.md
```

If the release already exists:

```sh
gh release upload r26d-linux-aarch64-host-tools \
  android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst \
  SHA256SUMS \
  BUILD_INFO.txt \
  --repo AkaakuHub/ndk-aarch64-linux \
  --clobber
```

## 4. Verify the uploaded release

```sh
gh release view r26d-linux-aarch64-host-tools --repo AkaakuHub/ndk-aarch64-linux --web
```

Download the archive in a clean location and check:

```sh
sha256sum -c SHA256SUMS
tar --zstd -tf android-ndk-r26d-linux-aarch64-host-tools-unofficial.tar.zst | sed -n '1,120p'
```
