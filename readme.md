# LLVM
Automatically installs LLVM with optional [libcxx][libcxx] WebAssembly support using [jfbastien/musl][musl] on Linux.

## Dependencies
Install dependencies in [WSL][wsl].

```sh
apt install build-essential binutils-dev ninja-build nasm git subversion libedit-dev
```

## Usage
Download this repository.

```sh
git clone https://github.com/qis/llvm && cd llvm
```

Install LLVM with **one** of the following commands. (WebAssembly is only supported in LLVM trunk.)

```sh
# Release (disables WebAssembly support).
# make TAG=tags/RELEASE_600/final PREFIX=/opt/llvm-6.0.0 SHARED=ON STATIC=OFF WASM=OFF JOBS=4

# Trunk revision.
# make REV={2018-05-03} PREFIX=/opt/llvm JOBS=4

# Trunk head.
# make PREFIX=/opt/llvm JOBS=4
```

Configure shared libraries in case llvm was installed with the `SHARED=ON` option.

```sh
cat > /etc/ld.so.conf.d/llvm.conf <<EOF
/opt/llvm/lib
/opt/llvm/lib/clang/7.0.0/lib/linux
EOF
ldconfig
```

## Example
A precompiled WebAssembly binary can seen in action [here][example].

[libcxx]: https://libcxx.llvm.org/
[musl]: https://github.com/jfbastien/musl/
[wsl]: https://de.wikipedia.org/wiki/Windows_Subsystem_for_Linux
[exmaple]: https://qis.github.io/llvm/
