# CMakeLists.txt for LoomKEX Optimized Implementation (AVX2)
# Builds all three security levels: 128, 256, 512

cmake_minimum_required(VERSION 3.10)
project(LoomKEX-Optimized C ASM)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -O3 -mavx2 -mbmi2 -mpopcnt -mfma)
endif()

add_compile_definitions(LOOM_AVX2)

option(LOOM_USE_SHAKE
  "Optimized kem/sig use internal SHAKE (KAT_KEX always uses ICCS/SM3)"
  ON)

set(LOOM_MODE_128 "1" CACHE STRING "LOOM mode for LoomKEX-128 (1, 3, or 5)")
set_property(CACHE LOOM_MODE_128 PROPERTY STRINGS "1" "3" "5")

set(LOOM_MODE_256 "3" CACHE STRING "LOOM mode for LoomKEX-256 (1, 3, or 5)")
set_property(CACHE LOOM_MODE_256 PROPERTY STRINGS "1" "3" "5")

set(LOOM_MODE_512 "5" CACHE STRING "LOOM mode for LoomKEX-512 (1, 3, or 5)")
set_property(CACHE LOOM_MODE_512 PROPERTY STRINGS "1" "3" "5")

add_subdirectory(LoomKEX-128)
add_subdirectory(LoomKEX-256)
add_subdirectory(LoomKEX-512)

add_custom_target(generate_kat
    COMMAND ./KAT_KEX_LoomKEX-128 && ./KAT_KEX_LoomKEX-256 && ./KAT_KEX_LoomKEX-512
    WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    COMMENT "Generating KAT_KEX_LoomKEX-xxx.txt"
)

add_dependencies(generate_kat KAT_KEX_LoomKEX-128 KAT_KEX_LoomKEX-256 KAT_KEX_LoomKEX-512)

add_custom_target(test_kex_state
    DEPENDS test_kex_state_LoomKEX-128 test_kex_state_LoomKEX-256 test_kex_state_LoomKEX-512
    COMMENT "Run LSTA pack/unpack tests for all parameter sets"
)
