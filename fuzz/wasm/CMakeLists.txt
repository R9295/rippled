cmake_minimum_required(VERSION 3.16)

# Fuzzer executable
add_executable(wasm_fuzzer
    fuzz.cc
)

# Add the WASM sources that xrpld uses but aren't in libxrpl
file(GLOB wasm_sources
    "${CMAKE_SOURCE_DIR}/src/xrpld/app/wasm/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/app/wasm/detail/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${wasm_sources})

# Add NFToken utils
target_sources(wasm_fuzzer PRIVATE
    "${CMAKE_SOURCE_DIR}/src/xrpld/app/tx/detail/NFTokenUtils.cpp"
)

# Add test framework sources needed for Env
file(GLOB test_jtx_sources
    "${CMAKE_SOURCE_DIR}/src/test/jtx/impl/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${test_jtx_sources})

# Add core application sources needed by Env
file(GLOB_RECURSE app_sources
    "${CMAKE_SOURCE_DIR}/src/xrpld/app/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/core/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/ledger/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/net/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/nodestore/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/overlay/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/peerfinder/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/rpc/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/shamap/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/perflog/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/consensus/*.cpp"
    "${CMAKE_SOURCE_DIR}/src/xrpld/conditions/*.cpp"
)
target_sources(wasm_fuzzer PRIVATE ${app_sources})

# Use the same includes as xrpld
target_include_directories(wasm_fuzzer
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
)

# Link against all libraries that xrpld uses
target_link_libraries(wasm_fuzzer
    Xrpl::boost
    Xrpl::opts
    Xrpl::libs
    xrpl.libxrpl
    xrpl.libpb
    OpenSSL::Crypto
    OpenSSL::SSL
    LibArchive::LibArchive
    lz4::lz4
    soci::soci
    SQLite::SQLite3
    gRPC::grpc++
    protobuf::libprotobuf
    date::date
    xxHash::xxhash
)

# Add nudb (handle different target names)
if(TARGET nudb::core)
    target_link_libraries(wasm_fuzzer nudb::core)
elseif(TARGET NuDB::nudb)
    target_link_libraries(wasm_fuzzer NuDB::nudb)
endif()

# Add RocksDB if enabled
if(rocksdb)
    target_link_libraries(wasm_fuzzer RocksDB::rocksdb)
endif()

# Add fuzzer instrumentation
target_compile_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)
target_link_options(wasm_fuzzer PRIVATE -fsanitize=fuzzer)

# Disable unity build for fuzzer
set_target_properties(wasm_fuzzer PROPERTIES UNITY_BUILD OFF)
