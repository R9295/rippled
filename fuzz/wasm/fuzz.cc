#include <xrpld/app/wasm/HostFuncWrapper.h>
#include <xrpld/app/wasm/HostFunc.h>
#include <xrpl/beast/utility/Journal.h>

extern "C" int
LLVMFuzzerTestOneInput(uint8_t const* ptr, size_t size)
{
    // Convert fuzzer input to wasm byte vector
    std::vector<uint8_t> wasm(ptr, ptr + size);

    // Get the WASM engine instance
    auto& engine = ripple::WasmEngine::instance();

    // Create a null journal for the fuzzer (no logging)
    beast::Journal journal{beast::Journal::getNullSink()};

    // Create basic host functions with null journal
    ripple::HostFunctions hfs(journal);

    // Create import vector for WASM host functions
    ripple::ImportVec imp = createWasmImport(hfs);

    // Set gas to 0 for all imports (unlimited gas for fuzzing)
    for (auto& i : imp)
        i.second.gas = 0;

    // Try to run the WASM module with "finish" entry point
    // Ignore any errors - we're just fuzzing for crashes
    try {
        auto re = engine.run(
            wasm, "finish", {}, imp, &hfs, 1'000'000, journal);
    } catch (...) {
        // Catch any exceptions to prevent fuzzer from stopping
    }

    return 0;
}
