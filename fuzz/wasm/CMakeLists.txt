cmake_minimum_required(VERSION 3.16)

# Fuzzer executable
add_executable(wasm_fuzzer
    fuzz.cc
)

# Link against xrpld's object files (exclude main.o)
file(GLOB_RECURSE xrpld_objects
    "${CMAKE_BINARY_DIR}/CMakeFiles/xrpld.dir/src/xrpld/*.o"
    "${CMAKE_BINARY_DIR}/CMakeFiles/xrpld.dir/src/test/*.o"
)
# Exclude main.o since it has rippled's main() function
list(FILTER xrpld_objects EXCLUDE REGEX ".*main\\.cpp\\.o$")
target_link_libraries(wasm_fuzzer PRIVATE ${xrpld_objects})

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
