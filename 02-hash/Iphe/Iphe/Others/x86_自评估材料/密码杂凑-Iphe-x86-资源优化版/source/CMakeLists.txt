cmake_minimum_required(VERSION 3.16)
project(iphe_x86_resource C)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

foreach(IPHE_BITS IN ITEMS 512 768 1024)
  add_library(iphe_${IPHE_BITS}_res STATIC
    Iphe-${IPHE_BITS}/CryptHash_AlgorithmInstance.c
  )
  target_include_directories(iphe_${IPHE_BITS}_res PUBLIC Iphe-${IPHE_BITS})
  target_compile_options(iphe_${IPHE_BITS}_res PRIVATE -Os -march=x86-64 -mavx2 -flto -ffat-lto-objects -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra)
  target_compile_definitions(iphe_${IPHE_BITS}_res PUBLIC
    CryptHash=CryptHash_iphe${IPHE_BITS}_res
    CryptHash_AlgorithmInstance_permutation=CryptHash_AlgorithmInstance_permutation_iphe${IPHE_BITS}_res
  )
endforeach()
