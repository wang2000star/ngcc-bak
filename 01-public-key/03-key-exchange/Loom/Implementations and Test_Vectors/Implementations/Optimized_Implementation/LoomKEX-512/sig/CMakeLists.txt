set(_sig_shake_srcs
  symmetric_avx2.c
  fips202x4.c
  f1600x4.S
)

set(_sig5_core_sources
  rounding.c
  sign.c
  polyvec.c
  sampler.c
  sampler_u.c
  irs.c
  packing.c
  poly.c
  poly_ntt.c
  reduce.c
  rans.c
  approx_exp.c
  approx_log.c
  ${SHUTTLE_QSETDIR}/ntt_ref.c
  q59393n1024/ntt.S
  q59393n1024/ntt_consts.c
)

function(loom_sig5_configure TARGET USE_SHAKE)
  target_sources(${TARGET} PRIVATE ${_sig5_core_sources})
  target_include_directories(${TARGET}
    PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/q59393n1024
      ${LOOM_512_SUBDIR}
      ${LOOM_512_SUBDIR}/loom
  )
  target_compile_definitions(${TARGET}
    PUBLIC LOOM_MODE=${LOOM_MODE}
    PRIVATE
      USE_AVX2_NTT
      USE_AVX2_SAMPLER
  )
  if(USE_SHAKE)
    target_sources(${TARGET} PRIVATE ${_sig_shake_srcs})
    target_compile_definitions(${TARGET}
      PRIVATE
        LOOM_USE_SHAKE
        USE_AVX2_SHAKE4X
        USE_AVX2_XOF_NWAY
    )
  endif()
endfunction()

function(loom_sig5_configure_kat TARGET)
  target_sources(${TARGET} PRIVATE ${_sig5_core_sources})
  target_include_directories(${TARGET}
    PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/q59393n1024
      ${LOOM_512_SUBDIR}
      ${LOOM_512_SUBDIR}/loom
  )
  target_compile_definitions(${TARGET}
    PUBLIC LOOM_MODE=${LOOM_MODE}
    PRIVATE USE_AVX2_NTT
  )
endfunction()

add_library(sig5 STATIC)
loom_sig5_configure(sig5 ${_loom_use_shake_enabled})

add_library(sig5_kat STATIC)
loom_sig5_configure_kat(sig5_kat)

set_source_files_properties(q59393n1024/ntt.S PROPERTIES COMPILE_FLAGS "-x assembler-with-cpp")

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang" AND _loom_use_shake_enabled)
  set_source_files_properties(
    fips202x4.c symmetric_avx2.c
    PROPERTIES COMPILE_FLAGS "-fno-lto"
  )
endif()
