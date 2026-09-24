foreach(IPHE_BITS IN ITEMS 512 768 1024)
  add_library(iphe_${IPHE_BITS} STATIC
    Implementations/Iphe-${IPHE_BITS}/CryptHash_AlgorithmInstance.c
  )
  target_include_directories(iphe_${IPHE_BITS} PUBLIC Implementations/Iphe-${IPHE_BITS})
  target_compile_definitions(iphe_${IPHE_BITS} PRIVATE
    CryptHash=CryptHash_iphe${IPHE_BITS}_perf
    CryptHash_AlgorithmInstance_permutation=CryptHash_AlgorithmInstance_permutation_iphe${IPHE_BITS}_perf
  )
  if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(iphe_${IPHE_BITS} PRIVATE -std=c99 -Wpedantic -Wall -Wextra -O3)
  endif()
endforeach()
