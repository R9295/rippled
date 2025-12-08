#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 [afl|asan|coverage]
  afl       Build with afl-clang-fast instrumention (default)
  asan      Build with clang + AddressSanitizer to triage crashes
  coverage  Build with clang + sancov 8-bit counters for raw coverage
USAGE
}

variant=${1:-afl}
case "$variant" in
  afl|asan|coverage) ;;
  -h|--help) usage; exit 0;;
  *) echo "Unknown variant '$variant'" >&2; usage; exit 1;;
esac

setup() {
  local build_dir=$1
  local build_type=$2
  local c_comp=$3
  local cxx_comp=$4
  local extra_cmake=$5
  mkdir -p "$build_dir"
  conan remote add xrplf https://conan.ripplex.io --force
  conan export external/wasmi --version=0.42.1
  conan install . \
    --output-folder="$build_dir" \
    -o fuzzer=True \
    -o tests=False \
    --build=missing \
    -s compiler=clang \
    -s compiler.version=21 \
    -s compiler.cppstd=20 \
    -s compiler.libcxx=libstdc++11 \
    -s build_type=$build_type
  cmake -S . -B "$build_dir" \
    -DCMAKE_TOOLCHAIN_FILE="$build_dir/build/generators/conan_toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=$build_type \
    -DCMAKE_C_COMPILER=$c_comp \
    -DCMAKE_CXX_COMPILER=$cxx_comp \
    -Dxrpld=ON \
    -Dtests=OFF $extra_cmake
}

case "$variant" in
  afl)
    setup build-afl Release afl-clang-fast afl-clang-fast++ "-DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld"
    AFL_LLVM_CMPLOG=1 AFL_LLVM_ALLOWLIST=$(pwd)/afl_allowlist.txt cmake --build build-afl --target wasm_fuzzer -j$(nproc)
    ;;
  asan)
    AFL_USE_ASAN=1 setup build-asan Debug afl-clang-fast afl-clang-fast++ "-DSANITIZE_ADDRESS=ON -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld"
    cmake --build build-asan --target wasm_fuzzer -j$(nproc)
    ;;
  coverage)
    export SANITIZE_COVERAGE=ON
    setup build-cov Debug clang clang++ ""
    cmake --build build-cov --target wasm_fuzzer -j$(nproc)
    ;;
esac
