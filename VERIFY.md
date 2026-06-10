# Verification

Use these commands after applying the overlay to an official Android NDK r26d installation.

## Check tool architectures

```sh
SDK=${ANDROID_SDK_ROOT}
NDK_R26D=${SDK}/ndk/26.3.11579264
NDKBIN=${NDK_R26D}/toolchains/llvm/prebuilt/linux-x86_64/bin

file -L \
  "$NDKBIN/clang" \
  "$NDKBIN/clang++" \
  "$NDKBIN/ld.lld" \
  "$SDK/build-tools/34.0.0/aapt2" \
  "$SDK/build-tools/34.0.0/aapt" \
  "$SDK/build-tools/34.0.0/aidl" \
  "$SDK/build-tools/34.0.0/zipalign" \
  "$SDK/cmake/3.22.1/bin/cmake" \
  "$SDK/cmake/3.22.1/bin/ninja" \
  "$(readlink -f "$(command -v java)")"
```

Expected: the relevant host tools are `ARM aarch64` ELF binaries.

## Check Android arm64 compile/link

```sh
NDKBIN=${NDK_R26D}/toolchains/llvm/prebuilt/linux-x86_64/bin

cat >/tmp/android-smoke.c <<'SRC'
int foo(void) { return 42; }
SRC

"$NDKBIN/aarch64-linux-android23-clang" -c /tmp/android-smoke.c -o /tmp/android-smoke.o
file /tmp/android-smoke.o

"$NDKBIN/aarch64-linux-android23-clang" -shared -fPIC /tmp/android-smoke.c -o /tmp/libandroid-smoke.so
file /tmp/libandroid-smoke.so
```

Expected:

```text
/tmp/android-smoke.o: ELF 64-bit LSB relocatable, ARM aarch64
/tmp/libandroid-smoke.so: ELF 64-bit LSB shared object, ARM aarch64
```

## Check qemu is not active during a Gradle build

```sh
echo "=== qemu / emulation processes: should be empty ==="
ps -ef | grep -Ei 'qemu|box64|box86|rosetta' | grep -v grep || true

echo

echo "=== active Android build processes and arch ==="
for p in $(pgrep -f 'GradleDaemon|gradlew|java|aapt2|ninja|cmake|clang|clang\+\+|ld\.lld|llvm-ar|llvm-ranlib|zipalign|aidl'); do
  exe="$(readlink -f /proc/$p/exe 2>/dev/null || true)"
  cmd="$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null || true)"

  echo
  echo "PID=$p"
  echo "EXE=$exe"
  echo "CMD=$cmd"
  [ -n "$exe" ] && file -L "$exe" 2>/dev/null || true
done
```

Expected:

```text
qemu / emulation processes: empty
java: ARM aarch64
aapt2: ARM aarch64
cmake: ARM aarch64
ninja: ARM aarch64
clang/clang++: ARM aarch64
```

## Note about linux-x86_64 path names

Seeing this path is expected:

```text
.../toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/...
```

That is the official NDK layout. It does not mean the running host executable is x86_64. Check the executable with `file -L` and check active processes with `/proc/<pid>/exe`.

For Android output architecture, check:

```text
--target=aarch64-none-linux-android29
```

or Gradle/CMake task names such as:

```text
buildCMakeRelWithDebInfo[arm64-v8a]
```
