cmake_minimum_required(VERSION 3.16)

# Fuzzer executable
add_executable(wasm_fuzzer
    fuzz.cc
)

# Use the same approach as xrpld: include all xrpld and test sources
file(GLOB_RECURSE xrpld_sources CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/xrpld/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${xrpld_sources})

file(GLOB_RECURSE test_sources CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/test/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${test_sources})

# Use the same includes and links as xrpld
target_include_directories(wasm_fuzzer
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
)

target_link_libraries(wasm_fuzzer
    Xrpl::boost
    Xrpl::opts
    Xrpl::libs
    xrpl.libxrpl
)

# Add fuzzer instrumentation
target_compile_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)
target_link_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)

# Disable unity build for fuzzer (same as xrpld does for some test files)
set_target_properties(wasm_fuzzer PROPERTIES UNITY_BUILD OFF)
