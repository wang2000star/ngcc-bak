project(PQC_BENCH DESCRIPTION "TaiChi Hash Benchmark" LANGUAGES C)

cmake_minimum_required(VERSION 3.16)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(TARGET_ARCH "x86" CACHE STRING "Target architecture: x86 or arm")

set(TAICHI_REF_FLAGS
    -std=c99 -Wpedantic -Wall -Wextra -O2
)

if(TARGET_ARCH STREQUAL "x86")
    set(TAICHI_OP_PER_FLAGS
        -O3 -march=x86-64 -mavx2 -mtune=native -flto
        -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
    )
    set(TAICHI_OP_RES_FLAGS
        -Os -march=x86-64 -mavx2 -flto
        -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
    )
elseif(TARGET_ARCH STREQUAL "arm")
    set(TAICHI_OP_PER_FLAGS
        -O3 -march=armv8.2-a+sve -flto
        -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
    )
    set(TAICHI_OP_RES_FLAGS
        -Os -march=armv8-a -flto
        -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
    )
else()
    message(FATAL_ERROR "Unsupported TARGET_ARCH: ${TARGET_ARCH}")
endif()

include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/adapter/include
)

add_subdirectory(API_CryptHash)
add_subdirectory(adapter)
add_subdirectory(bench)

add_executable(ngcc_bench
    src/main.c
    src/parse_option.c
    src/print_banner.c
    src/registry.c
)

target_link_libraries(ngcc_bench
    adapter
    benchlib
)