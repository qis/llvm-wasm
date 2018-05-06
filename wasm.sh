#/bin/sh
self=$(readlink -f "$0")
self=/opt/llvm/bin/wasm
base=$(dirname $(dirname ${self}))
name=`echo $(basename "$0") | cut -c6-`

args="$@ -target wasm32-unknown-unknown-wasm -mthread-model single"
args="${args} -D__linux=1 -D__linux__=1 -D__gnu_linux__=1 -Dlinux=1"
args="${args} -isystem ${base}/wasm/include -B ${base}/bin -L ${base}/wasm/lib"
args="${args} -Wno-unused-command-line-argument"

nostdlib=0
nostdlibxx=0

while [ $# -ne 0 ]; do
  if [ "$1" = "-nostdlib" ]; then
    nostdlib=1
  elif [ "$1" = "-nostdlib++" ]; then
    nostdlibxx=1
  fi
  shift
done

if [ ${nostdlib} -eq 0 ]; then
  args="${args} -rtlib=compiler-rt -resource-dir ${base}/wasm --sysroot ${base}/wasm"
fi

if [ -z "`echo -- "${args}" | grep allow-undefined-file`" ]; then
  args="${args} -Wl,--allow-undefined-file=${base}/wasm.syms"
fi

case "${name}" in
"cc" | "clang")
  ${base}/bin/clang ${args}
  ;;
"c++" | "clang++")
  if [ ${nostdlibxx} -eq 0 ]; then
    args="-isystem ${base}/wasm/include/c++/v1 ${args} -fno-exceptions"
  fi
  ${base}/bin/clang++ -stdlib=libc++ -nostdinc++ ${args}
  ;;
*) echo "unknown ${self} symlink: ${name}"; exit 1 ;;
esac
