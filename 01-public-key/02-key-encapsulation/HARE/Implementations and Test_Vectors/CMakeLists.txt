cmake_minimum_required(VERSION 3.11.4)
project(HARE_Code_Package C)

include(CTest)
enable_testing()

include(cmake/HareCompilerOptions.cmake)
include(cmake/HareAddInstance.cmake)

option(HARE_ENABLE_X86 "Build x86 optimized KR targets" ON)
option(HARE_ENABLE_ARM_SVE "Build Additional ARM/SVE KR implementation targets" OFF)
option(HARE_ARM_SVE_ENABLE_PMULL "Enable NEON PMULL base case for ARM/SVE GF2X" ON)

# HARE submission-oriented KR line.
set(HARE_SUBMISSION_LEVELS HARE-128 HARE-256 HARE-384 HARE-512)
set(HARE_COMPRESSION_BACKENDS kr)

foreach(hare IN LISTS HARE_SUBMISSION_LEVELS)
  foreach(backend IN LISTS HARE_COMPRESSION_BACKENDS)
    string(TOUPPER "${backend}" backend_upper)
    hare_add_instance(
      NAME ${hare}-${backend}
      ROLE Reference
      BACKEND ${backend_upper}
      INSTANCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/Reference_Implementation/${hare}/${backend}
      ENABLED ON
    )
  endforeach()
endforeach()

if(HARE_ENABLE_X86)
  foreach(hare IN LISTS HARE_SUBMISSION_LEVELS)
    foreach(backend IN LISTS HARE_COMPRESSION_BACKENDS)
      string(TOUPPER "${backend}" backend_upper)
      hare_add_instance(
        NAME ${hare}-${backend}-x86
        ROLE Optimized
        BACKEND ${backend_upper}
        CORE_KIND X86
        INSTANCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/Optimized_Implementation/${hare}/${backend}
        ENABLED ON
      )
    endforeach()
  endforeach()
endif()

if(HARE_ENABLE_ARM_SVE)
  foreach(hare IN LISTS HARE_SUBMISSION_LEVELS)
    hare_add_instance(
      NAME ${hare}-kr-arm-sve
      ROLE Optimized
      BACKEND KR
      CORE_KIND ARM_SVE
      INSTANCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/Additional_Implementation/${hare}/kr-arm-sve
      ENABLED ON
    )
  endforeach()
endif()

get_property(HARE_REFERENCE_RUN_KAT_TARGETS GLOBAL PROPERTY HARE_REFERENCE_RUN_KAT_TARGETS)
get_property(HARE_REFERENCE_VERIFY_KAT_TARGETS GLOBAL PROPERTY HARE_REFERENCE_VERIFY_KAT_TARGETS)
get_property(HARE_OPTIMIZED_VERIFY_KAT_TARGETS GLOBAL PROPERTY HARE_OPTIMIZED_VERIFY_KAT_TARGETS)

if(HARE_REFERENCE_RUN_KAT_TARGETS)
  add_custom_target(run_kat_all DEPENDS ${HARE_REFERENCE_RUN_KAT_TARGETS})
endif()

if(HARE_REFERENCE_VERIFY_KAT_TARGETS)
  add_custom_target(verify_kat_all DEPENDS ${HARE_REFERENCE_VERIFY_KAT_TARGETS})
endif()

if(HARE_OPTIMIZED_VERIFY_KAT_TARGETS)
  add_custom_target(verify_kat_optimized_all DEPENDS ${HARE_OPTIMIZED_VERIFY_KAT_TARGETS})
endif()
