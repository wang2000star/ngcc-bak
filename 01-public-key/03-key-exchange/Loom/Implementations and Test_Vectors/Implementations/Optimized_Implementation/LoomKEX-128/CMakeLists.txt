# CMakeLists.txt for LoomKEX-128 (Optimized AVX2 Implementation)

if(NOT DEFINED LOOM_MODE_128 OR "${LOOM_MODE_128}" STREQUAL "")
  set(LOOM_MODE_128 "1")
endif()

set(LOOM_128_SUBDIR "${PROJECT_SOURCE_DIR}/LoomKEX-128")
set(LOOM_SUBDIR "${LOOM_128_SUBDIR}")

set(LOOM_MODE "${LOOM_MODE_128}")
message(STATUS "Configuring LoomKEX-128 (AVX2) with mode ${LOOM_MODE}")

if(LOOM_MODE STREQUAL "1")
  set(SHUTTLE_QSETDIR "ntt/q15361n256")
  set(SHUTTLE_QSET "q15361n256")
elseif(LOOM_MODE STREQUAL "3")
  set(SHUTTLE_QSETDIR "ntt/q61441n512")
  set(SHUTTLE_QSET "q61441n512")
elseif(LOOM_MODE STREQUAL "5")
  set(SHUTTLE_QSETDIR "ntt/q59393n1024")
  set(SHUTTLE_QSET "q59393n1024")
else()
  message(FATAL_ERROR "LOOM_MODE must be 1, 3, or 5")
endif()

set(_loom_use_shake_enabled OFF)
if(LOOM_USE_SHAKE)
  set(_loom_use_shake_enabled ON)
endif()

add_subdirectory(kem)
add_subdirectory(sig)
add_subdirectory(loom)
