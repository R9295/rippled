conan remote add xrplf https://conan.ripplex.io --force
conan export external/wasmi --version=0.42.1
conan install . --output-folder=build-afl -o fuzzer=True -o tests=False --build=missing -s compiler=clang -s compiler.version=21 -s compiler.cppstd=20 -s compiler.libcxx=libstdc++11 -s build_type=Release
AFL_LLVM_CMPLOG=1 AFL_LLVM_ALLOWLIST=$(pwd)/afl_allowlist.txt cmake -S . -B build-afl -DCMAKE_TOOLCHAIN_FILE=build/build/generators/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=afl-clang-fast -DCMAKE_CXX_COMPILER=afl-clang-fast++ -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld"  -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld" -Dxrpld=ON -Dtests=OFF
AFL_LLVM_CMPLOG=1 AFL_LLVM_ALLOWLIST=$(pwd)/afl_allowlist.txt cmake --build build-afl --target wasm_fuzzer -j$(nproc)
