cmake_minimum_required(VERSION 3.16)
project(ngcc_bench_iphe_performance C)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_subdirectory(API_CryptHash)

add_executable(ngcc_bench
  src/main.c
  src/registry.c
  bench/hash/hash_bench.c
  adapter/iphe_adapter.c
)

target_include_directories(ngcc_bench PRIVATE include)
target_link_libraries(ngcc_bench PRIVATE iphe_512 iphe_768 iphe_1024)
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  target_compile_options(ngcc_bench PRIVATE -std=c99 -Wpedantic -Wall -Wextra -O3)
endif()
