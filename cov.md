```
./build.sh coverage
./build-cov/wasm/fuzz/wasm_fuzzer -runs=0 -print-coverage <corpus>
llvm-profdata-21 merge -sparse default.profraw -o default.profdata
llvm-cov-21 show -format=html -instr-profile ./default.profdata ./build-cov/fuzz/wasm/wasm_fuzzer -o ./cov-out
```
