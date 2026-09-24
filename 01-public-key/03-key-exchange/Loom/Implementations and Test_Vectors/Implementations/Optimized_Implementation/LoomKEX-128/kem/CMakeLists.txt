set(_kem1_sources
  cbd.c
  indcpa.c
  kem_cpaf.c
  msgenc.c
  ntt.c
  poly.c
  poly_invq.c
  polyvec.c
  reduce.c
  verify.c
  avx2/ntt3329_avx128.c
  avx2/ntt7681_avx.c
  avx2/poly_compress_avx.c
  avx2/poly_compress9.c
  keccak4x/fips202x4.c
  keccak4x/KeccakP-1600-times4-SIMD256.c
  avx2/cbd_avx2.c
  avx2/indcpa_gen_matrix_avx128.c
  avx2/rejsample.c
)

function(loom_kem1_configure TARGET)
  target_include_directories(${TARGET}
    PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/avx2
      ${CMAKE_CURRENT_SOURCE_DIR}/keccak4x
      ${LOOM_128_SUBDIR}
      ${LOOM_128_SUBDIR}/loom
      ${LOOM_128_SUBDIR}/sig
  )
  target_compile_definitions(${TARGET}
    PUBLIC LOOM_MODE=${LOOM_MODE}
    PRIVATE
      WEAVER_USE_AVX_NTT128
      WEAVER_USE_AVX_NTT7681
      WEAVER_USE_AVX_COMPRESS
      WEAVER_USE_AVX_CBD
      WEAVER_AVX_GEN_MATRIX128
  )
endfunction()

# KAT oracle: scalar gen_matrix (matches Reference DRNG/XOF consumption).
function(loom_kem1_configure_kat TARGET)
  target_include_directories(${TARGET}
    PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/avx2
      ${CMAKE_CURRENT_SOURCE_DIR}/keccak4x
      ${LOOM_128_SUBDIR}
      ${LOOM_128_SUBDIR}/loom
      ${LOOM_128_SUBDIR}/sig
  )
  target_compile_definitions(${TARGET}
    PUBLIC LOOM_MODE=${LOOM_MODE}
    PRIVATE
      WEAVER_USE_AVX_NTT128
      WEAVER_USE_AVX_NTT7681
      WEAVER_USE_AVX_COMPRESS
      WEAVER_USE_AVX_CBD
  )
endfunction()

add_library(kem1 STATIC ${_kem1_sources})
loom_kem1_configure(kem1)
if(_loom_use_shake_enabled)
  target_compile_definitions(kem1 PRIVATE LOOM_USE_SHAKE)
endif()

add_library(kem1_kat STATIC ${_kem1_sources})
loom_kem1_configure_kat(kem1_kat)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  set_source_files_properties(
    keccak4x/fips202x4.c
    keccak4x/KeccakP-1600-times4-SIMD256.c
    avx2/rejsample.c
    avx2/poly_compress_avx.c
    avx2/poly_compress9.c
    PROPERTIES COMPILE_FLAGS "-fno-lto"
  )
endif()
