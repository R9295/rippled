conan remote add xrplf https://conan.ripplex.io --force
conan export external/wasmi --version=0.42.1
conan install . --output-folder=build -o fuzzer=True -o tests=False --build=missing -s compiler=clang -s compiler.version=21 -s compiler.cppstd=20 -s compiler.libcxx=libstdc++11 -s build_type=Release
AFL_LLVM_CMPLOG=1 AFL_LLVM_ALLOWLIST=$(pwd)/afl_allowlist.txt cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/build/generators/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang-21 -DCMAKE_CXX_COMPILER=clang++-21 -Dxrpld=ON -Dtests=OFF
AFL_LLVM_CMPLOG=1 AFL_LLVM_ALLOWLIST=$(pwd)/afl_allowlist.txt cmake --build build --target wasm_fuzzer -j$(nproc)
