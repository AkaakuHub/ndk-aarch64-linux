# Cleanup checklist

Do not remove local build artifacts until the GitHub Release exists and the uploaded archive has been verified.

## Safe order

1. Build and verify the overlay locally.
2. Package the release archive.
3. Upload to GitHub Release.
4. Download/check the release asset or inspect its checksum.
5. Run cleanup in dry-run mode.
6. Delete only after reviewing the dry-run output.

## Dry run

```sh
export SOURCE_ROOT=/path/to/aosp-llvm-r26d
export ANDROID_SDK_ROOT=/path/to/Android/Sdk
export NDK_R26D=${ANDROID_SDK_ROOT}/ndk/26.3.11579264
export RELEASE_DIR=/path/to/release-output

./scripts/cleanup-local-r26d-build.sh
```

## Delete

```sh
./scripts/cleanup-local-r26d-build.sh delete
```

## Not removed by default

The cleanup script does not remove an application work cache such as `.arm-build/` from another project. That cache may be needed for fast incremental Android builds.

The cleanup script also does not remove the official NDK installation. It only lists/removes build source trees and old backup directories when explicitly requested.
