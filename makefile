MAKEFLAGS += --no-print-directory

SVN	?=trunk
REV	?={2018-05-03}
URL	?=https://llvm.org/svn/llvm-project
PREFIX	?=/opt/llvm
SHARED	?=OFF
STATIC	?=ON
JOBS	?=4

all:
	@if [ ! -d "$(PREFIX)" ]; then \
	  make llvm; \
	fi
	@if [ ! -e "$(PREFIX)/bin/wasm" ]; then \
	  make wasm; \
	fi
	@if [ ! -e "$(PREFIX)/wasm.syms" ]; then \
	  make wasm.syms; \
	fi
	@if [ ! -e "$(PREFIX)/wasm/lib/libc.a" ]; then \
	  make musl; \
	fi
	@if [ ! -e "$(PREFIX)/wasm/lib/libclang_rt.builtins-wasm32.a" ]; then \
	  make compiler-rt; \
	fi
	@if [ ! -e "$(PREFIX)/wasm/lib/libc++abi.a" ]; then \
	  make libcxxabi; \
	fi
	@if [ ! -e "$(PREFIX)/wasm/lib/libc++.a" ]; then \
	  make libcxx; \
	fi
	@if [ "`stat -c "%A" $(PREFIX)/bin`" != "drwxr-xr-x" ]; then \
	  make permissions; \
	fi

src:
	svn co -r "$(REV)" $(URL)/llvm/$(SVN) $@
	svn co -r "$(REV)" $(URL)/cfe/$(SVN) $@/tools/clang
	svn co -r "$(REV)" $(URL)/clang-tools-extra/$(SVN) $@/tools/clang/tools/extra
	svn co -r "$(REV)" $(URL)/libcxx/$(SVN) $@/projects/libcxx
	svn co -r "$(REV)" $(URL)/libcxxabi/$(SVN) $@/projects/libcxxabi
	svn co -r "$(REV)" $(URL)/compiler-rt/$(SVN) $@/projects/compiler-rt
	svn co -r "$(REV)" $(URL)/libunwind/$(SVN) $@/projects/libunwind
	svn co -r "$(REV)" $(URL)/lld/$(SVN) $@/projects/lld
	git clone -b wasm-prototype-1 https://github.com/jfbastien/musl $@/projects/musl

build:
	mkdir $@

llvm: build src
	rm -rf build/llvm; mkdir build/llvm && cd build/llvm && \
	  cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
	    -DCMAKE_INSTALL_PREFIX="$(PREFIX)" \
	    -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86;WebAssembly" \
	    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="WebAssembly" \
	    -DLLVM_INCLUDE_EXAMPLES=OFF \
	    -DLLVM_INCLUDE_TESTS=OFF \
	    -DLLVM_ENABLE_WARNINGS=OFF \
	    -DLLVM_ENABLE_PEDANTIC=OFF \
	    -DCLANG_DEFAULT_CXX_STDLIB="libc++" \
	    -DCLANG_INCLUDE_TESTS=OFF \
	    -DLIBCXX_ENABLE_SHARED=$(SHARED) \
	    -DLIBCXX_ENABLE_STATIC=$(STATIC) \
	    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
	    -DLIBCXX_ENABLE_FILESYSTEM=ON \
	    -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
	    -DLIBCXX_INSTALL_EXPERIMENTAL_LIBRARY=ON \
	    -DLIBCXXABI_ENABLE_SHARED=$(SHARED) \
	    -DLIBCXXABI_ENABLE_STATIC=$(STATIC) \
	    ../../src && \
	  cmake --build . --target install -- -j$(JOBS)

wasm:
	cp wasm.sh $(PREFIX)/bin/wasm
	@cd $(PREFIX)/bin && for i in cc c++ clang clang++; do \
	  echo "$(PREFIX)/bin/wasm-$$i -> wasm"; \
	  rm -f wasm-$$i; ln -s wasm wasm-$$i; \
	done
	@cd $(PREFIX)/bin && for i in ar as nm objcopy objdump ranlib readelf readobj size strings; do \
	  echo "$(PREFIX)/bin/wasm-$$i -> llvm-$$i"; \
	  rm -f wasm-$$i; ln -s llvm-$$i wasm-$$i; \
	done

wasm.syms:
	cp wasm.syms $(PREFIX)/wasm.syms

musl: build src
	rm -rf build/musl; mkdir build/musl && cd build/musl && \
	  CROSS_COMPILE="$(PREFIX)/bin/wasm-" CFLAGS="-Wno-everything -I/usr/include" \
	  ../../src/projects/musl/configure --prefix=$(PREFIX)/wasm --disable-shared && \
	  make all install -j$(JOBS)

compiler-rt: build src
	rm -rf build/compiler-rt; mkdir build/compiler-rt && cd build/compiler-rt && \
	  LDFLAGS="-lc -nodefaultlibs -nostdlib++ -fuse-ld=lld" \
	  cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(PREFIX)/wasm" \
	    -DCMAKE_C_COMPILER="$(PREFIX)/bin/wasm-clang" \
	    -DCMAKE_CXX_COMPILER="$(PREFIX)/bin/wasm-clang++" \
	    -DLLVM_CONFIG_PATH="$(PREFIX)/bin/llvm-config" \
	    -DCMAKE_RANLIB="$(PREFIX)/bin/llvm-ranlib" \
	    -DCMAKE_NM="$(PREFIX)/bin/llvm-nm" \
	    -DCMAKE_AR="$(PREFIX)/bin/llvm-ar" \
	    -DCMAKE_SYSTEM_NAME="Linux" \
	    -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE="wasm32-unknown-unknown-wasm" \
	    -DCOMPILER_RT_BUILD_BUILTINS=ON \
	    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
	    -DCOMPILER_RT_BUILD_XRAY=OFF \
	    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
	    -DCOMPILER_RT_BUILD_PROFILE=OFF \
	    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
	    -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=ON \
	    -DCAN_TARGET_wasm32=ON \
	    ../../src/projects/compiler-rt && \
	  cmake --build . --target install -- -j$(JOBS) && \
	  cd $(PREFIX)/wasm/lib && ln -s linux/libclang_rt.builtins-wasm32.a
  
libcxxabi: build src
	rm -rf build/libcxxabi; mkdir build/libcxxabi && cd build/libcxxabi && \
	  CXXFLAGS="-I $(PWD)/src/projects/libunwind/include" LDFLAGS="-nostdlib++ -fuse-ld=lld" \
	  cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(PREFIX)/wasm" \
	    -DCMAKE_C_COMPILER="$(PREFIX)/bin/wasm-clang" \
	    -DCMAKE_CXX_COMPILER="$(PREFIX)/bin/wasm-clang++" \
	    -DLLVM_CONFIG_PATH="$(PREFIX)/bin/llvm-config" \
	    -DCMAKE_RANLIB="$(PREFIX)/bin/llvm-ranlib" \
	    -DCMAKE_NM="$(PREFIX)/bin/llvm-nm" \
	    -DCMAKE_AR="$(PREFIX)/bin/llvm-ar" \
	    -DCMAKE_SYSTEM_NAME="Linux" \
	    -DLIBCXXABI_TARGET_TRIPLE="wasm32-unknown-unknown-wasm" \
	    -DLIBCXXABI_LIBCXX_PATH="$(PREFIX)/wasm" \
	    -DLIBCXXABI_ENABLE_EXCEPTIONS=OFF \
	    -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
	    -DLIBCXXABI_USE_COMPILER_RT=ON \
	    -DLIBCXXABI_ENABLE_THREADS=OFF \
	    -DLIBCXXABI_INCLUDE_TESTS=OFF \
	    -DLIBCXXABI_ENABLE_SHARED=OFF \
	    -DLIBCXXABI_ENABLE_STATIC=ON \
	    -DLIBCXXABI_BAREMETAL=ON \
	    -DLIBCXXABI_SILENT_TERMINATE=ON \
	    -DLLVM_ENABLE_LIBCXX=ON \
	    ../../src/projects/libcxxabi && \
	  cmake --build . --target install -- -j$(JOBS)
  
libcxx: build src
	rm -rf build/libcxx; mkdir build/libcxx && cd build/libcxx && \
	  LDFLAGS="-lc -nodefaultlibs -fuse-ld=lld" \
	  cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(PREFIX)/wasm" \
	    -DCMAKE_C_COMPILER="$(PREFIX)/bin/wasm-clang" \
	    -DCMAKE_CXX_COMPILER="$(PREFIX)/bin/wasm-clang++" \
	    -DLLVM_CONFIG_PATH="$(PREFIX)/bin/llvm-config" \
	    -DCMAKE_RANLIB="$(PREFIX)/bin/llvm-ranlib" \
	    -DCMAKE_NM="$(PREFIX)/bin/llvm-nm" \
	    -DCMAKE_AR="$(PREFIX)/bin/llvm-ar" \
	    -DLIBCXX_CXX_ABI_INCLUDE_PATHS="$(PWD)/src/projects/libcxxabi/include" \
	    -DLIBCXX_CXX_ABI="libcxxabi" \
	    -DLIBCXX_HAS_ATOMIC_LIB=OFF \
	    -DLIBCXX_ENABLE_SHARED=OFF \
	    -DLIBCXX_ENABLE_STATIC=ON \
	    -DLIBCXX_ENABLE_FILESYSTEM=ON \
	    -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
	    -DLIBCXX_INSTALL_EXPERIMENTAL_LIBRARY=ON \
	    -DLIBCXX_INCLUDE_TESTS=OFF \
	    -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
	    -DLIBCXX_INCLUDE_DOCS=OFF \
	    -DLIBCXX_USE_COMPILER_RT=ON \
	    -DLIBCXX_ENABLE_EXCEPTIONS=OFF \
	    -DLIBCXX_ENABLE_RTTI=ON \
	    -DLIBCXX_ENABLE_STDIN=OFF \
	    -DLIBCXX_ENABLE_STDOUT=ON \
	    -DLIBCXX_ENABLE_THREADS=OFF \
	    -DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF \
	    -DLIBCXX_HAS_MUSL_LIBC=ON \
	    ../../src/projects/libcxx && \
	  cmake --build . --target install -- -j$(JOBS)

permissions:
	find $(PREFIX) -type d -exec chmod 0755 '{}' ';'

test: test/main.wasm

test/main.wasm: test/main.cpp
	$(PREFIX)/bin/wasm-clang++ -std=c++2a -O0 -o $@ $<

clean:
	rm -f test/main.wasm

.PHONY: llvm wasm wasm.syms musl compiler-rt libcxxabi libcxx permissions test test/main.wasm clean
