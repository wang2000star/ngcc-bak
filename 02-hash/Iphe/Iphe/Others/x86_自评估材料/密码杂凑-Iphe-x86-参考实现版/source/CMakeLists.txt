cmake_minimum_required(VERSION 3.16)
project(iphe_x86_reference C)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

foreach(IPHE_BITS IN ITEMS 512 768 1024)
  add_library(iphe_${IPHE_BITS} STATIC
    Iphe-${IPHE_BITS}/CryptHash_AlgorithmInstance.c
  )
  target_include_directories(iphe_${IPHE_BITS} PUBLIC Iphe-${IPHE_BITS})
  target_compile_options(iphe_${IPHE_BITS} PRIVATE -O2 -std=c99 -Wpedantic -Wall -Wextra)
  target_compile_definitions(iphe_${IPHE_BITS} PUBLIC
    CryptHash=CryptHash_iphe${IPHE_BITS}
    CryptHash_AlgorithmInstance_permutation=CryptHash_AlgorithmInstance_permutation_iphe${IPHE_BITS}
  )
endforeach()
