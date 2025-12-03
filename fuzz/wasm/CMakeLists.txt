cmake_minimum_required(VERSION 3.16)

# Fuzzer executable
add_executable(wasm_fuzzer
    fuzz.cc
)

# Link against xrpld's already-compiled object files (exclude main.o)
file(GLOB_RECURSE xrpld_objects
    "${CMAKE_BINARY_DIR}/CMakeFiles/xrpld.dir/src/xrpld/*.o"
)
list(FILTER xrpld_objects EXCLUDE REGEX ".*main\\.cpp\\.o$")
target_link_libraries(wasm_fuzzer PRIVATE ${xrpld_objects})

# Compile only the test framework sources we need (test::jtx::Env and helpers)
file(GLOB_RECURSE test_jtx_sources
    "${CMAKE_SOURCE_DIR}/src/test/jtx/impl/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/test/unit_test/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${test_jtx_sources})

# Enable tests flag
target_compile_definitions(wasm_fuzzer PRIVATE ENABLE_TESTS)

# Use the same includes and links as xrpld
target_include_directories(wasm_fuzzer
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
)

target_link_libraries(wasm_fuzzer
    PRIVATE
        Xrpl::boost
        Xrpl::opts
        Xrpl::libs
        xrpl.libxrpl
)

# Add fuzzer instrumentation
target_compile_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)
target_link_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)

# Disable unity build
set_target_properties(wasm_fuzzer PROPERTIES UNITY_BUILD OFF)
