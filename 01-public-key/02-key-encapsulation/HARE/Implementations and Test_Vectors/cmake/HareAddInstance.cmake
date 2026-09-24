function(hare_add_instance)
  set(options)
  set(oneValueArgs NAME ROLE BACKEND INSTANCE_DIR ENABLED CORE_KIND)
  cmake_parse_arguments(HI "${options}" "${oneValueArgs}" "" ${ARGN})

  if(NOT HI_ENABLED)
    return()
  endif()

  if(NOT HI_CORE_KIND)
    set(HI_CORE_KIND REF)
  endif()

  string(REPLACE "-" "_" HI_SAFE_NAME ${HI_NAME})
  if(NOT HI_BACKEND)
    set(HI_BACKEND KR)
  endif()

  string(TOUPPER "${HI_BACKEND}" HI_BACKEND_UPPER)
  string(TOUPPER "${HI_ROLE}" HI_ROLE_UPPER)
  string(TOUPPER "${HI_CORE_KIND}" HI_CORE_KIND_UPPER)

  set(HARE_CORE_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/_shared/hare_core)
  set(HARE_APIPKC_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/Implementations/_shared/api_pkc)
  set(HARE_X86_ROOT ${HARE_CORE_ROOT}/x86_64)
  set(HARE_ARM_ROOT ${HARE_CORE_ROOT}/aarch64)

  file(GLOB common_src ${HARE_CORE_ROOT}/common/*.c)
  file(GLOB ref_src ${HARE_CORE_ROOT}/ref/*.c)
  set(x86_src)

  set(extra_src
    ${HARE_APIPKC_ROOT}/auxfunc.c
    ${HARE_APIPKC_ROOT}/drng.c
  )


  if(HI_CORE_KIND_UPPER STREQUAL "X86")
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/vector.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/gf.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/gf2x.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/reed_muller.c)
    list(APPEND x86_src
      ${HARE_X86_ROOT}/avx256/vector.c
      ${HARE_X86_ROOT}/avx256/gf.c
      ${HARE_X86_ROOT}/avx256/gf2x.c
      ${HARE_X86_ROOT}/avx256/reed_muller.c
    )
    # The x86 RS implementation uses static generator-polynomial constants for
    # the active KR parameter sets.
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/reed_solomon.c)
    list(APPEND x86_src ${HARE_X86_ROOT}/avx256/reed_solomon.c)
  elseif(HI_CORE_KIND_UPPER STREQUAL "ARM_SVE")
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/vector.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/gf.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/gf2x.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/reed_muller.c)
    list(REMOVE_ITEM ref_src ${HARE_CORE_ROOT}/ref/reed_solomon.c)
    list(APPEND x86_src
      ${HARE_ARM_ROOT}/sve/vector.c
      ${HARE_ARM_ROOT}/sve/gf.c
      ${HARE_ARM_ROOT}/sve/gf2x.c
      ${HARE_ARM_ROOT}/sve/reed_muller.c
      ${HARE_ARM_ROOT}/sve/reed_solomon.c
    )
  elseif(NOT HI_CORE_KIND_UPPER STREQUAL "REF")
    message(FATAL_ERROR "Unknown CORE_KIND=${HI_CORE_KIND}")
  endif()

  if(HI_BACKEND_UPPER STREQUAL "KR")
    # KR-only package: no historical hamming compression source is present.
  else()
    message(FATAL_ERROR "Unsupported BACKEND=${HI_BACKEND}; this package contains KR instances only")
  endif()

  add_library(core_${HI_SAFE_NAME} STATIC ${common_src} ${ref_src} ${x86_src} ${extra_src})

  target_include_directories(core_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR}
    ${HARE_CORE_ROOT}/common
    ${HARE_CORE_ROOT}/ref
    ${HARE_X86_ROOT}/avx256
    ${HARE_ARM_ROOT}/sve
    ${HARE_APIPKC_ROOT}
  )

  target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
    HARE_SYMMETRIC_MODE_B
  )

  if(HI_BACKEND_UPPER STREQUAL "KR")
    target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
      HARE_BACKEND_KR=1
    )
  endif()

  if(HI_CORE_KIND_UPPER STREQUAL "X86")
    target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
      HARE_X86_OPTIMIZED=1
      HARE_X86_AVX2_VECTOR=1
      HARE_X86_PCLMUL_GF=1
      HARE_X86_PCLMUL_GF2X=1
      HARE_X86_SELECTED_GF2X=1
      HARE_X86_AVX2_RM=1
    )
    target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC HARE_X86_RS_ERASURE=1)
  elseif(HI_CORE_KIND_UPPER STREQUAL "ARM_SVE")
    target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
      HARE_ARM_SVE_OPTIMIZED=1
      HARE_ARM_SVE_VECTOR=1
      HARE_ARM_SVE_GF=1
      HARE_ARM_SVE_RM=1
      HARE_ARM_SVE_RS_ERASURE=1
    )
    if(HARE_ARM_SVE_ENABLE_PMULL)
      target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
        HARE_ARM_PMULL_GF2X=1
      )
    else()
      target_compile_definitions(core_${HI_SAFE_NAME} PUBLIC
        HARE_ARM_GF2X_GENERIC=1
      )
    endif()
  endif()

  hare_apply_instance_compile_options(core_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # GF2X sparse-support property test: verifies multiplication modulo X^n-1
  # against a compact independent reference for deterministic low-weight inputs.
  add_executable(gf2x_property_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_gf2x_property.c
  )
  target_include_directories(gf2x_property_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_link_libraries(gf2x_property_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(gf2x_property_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # Code roundtrip: exercises encode/decode and compression/decompression paths.
  add_executable(code_roundtrip_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_code_roundtrip.c
  )
  target_include_directories(code_roundtrip_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_link_libraries(code_roundtrip_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(code_roundtrip_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # API/parameter formula contract and RS error+erasure boundary tests.
  add_executable(api_contract_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_api_contract.c
  )
  target_include_directories(api_contract_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_link_libraries(api_contract_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(api_contract_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  add_executable(rs_boundary_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_rs_erasure_boundary.c
  )
  target_include_directories(rs_boundary_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_link_libraries(rs_boundary_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(rs_boundary_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # KR backend table, systematic-coordinate, and projection tests.
  if(HI_BACKEND_UPPER STREQUAL "KR")
    add_executable(kr_table_${HI_SAFE_NAME}
      ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_kr_table.c
    )
    target_include_directories(kr_table_${HI_SAFE_NAME} PRIVATE
      ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
    )
    target_link_libraries(kr_table_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
    hare_apply_instance_compile_options(kr_table_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

    add_executable(kr_projection_${HI_SAFE_NAME}
      ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_kr_projection.c
    )
    target_include_directories(kr_projection_${HI_SAFE_NAME} PRIVATE
      ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
    )
    target_link_libraries(kr_projection_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
    hare_apply_instance_compile_options(kr_projection_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

    add_executable(kr_systematic_${HI_SAFE_NAME}
      ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_kr_systematic.c
    )
    target_include_directories(kr_systematic_${HI_SAFE_NAME} PRIVATE
      ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
    )
    target_link_libraries(kr_systematic_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
    hare_apply_instance_compile_options(kr_systematic_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})
  endif()

  # Internal KEM loop: deterministic keygen/encaps/decaps consistency check.
  add_executable(check_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_kem_loop.c
    ${HI_INSTANCE_DIR}/KEM_AlgorithmInstance.c
  )
  target_include_directories(check_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_compile_definitions(check_${HI_SAFE_NAME} PRIVATE HARE_INSTANCE_NAME="${HI_NAME}" HARE_KEM_LOOP_ROUNDS=10)
  target_link_libraries(check_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(check_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # Tamper test: verifies FO implicit rejection on modified ciphertext input.
  add_executable(tamper_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/test_tamper.c
    ${HI_INSTANCE_DIR}/KEM_AlgorithmInstance.c
  )
  target_include_directories(tamper_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_link_libraries(tamper_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
  hare_apply_instance_compile_options(tamper_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # Benchmark target for x86 self-evaluation and container smoke runs.
  add_executable(bench_${HI_SAFE_NAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/benchmark/bench_kem_instance.c
    ${HI_INSTANCE_DIR}/KEM_AlgorithmInstance.c
  )
  target_include_directories(bench_${HI_SAFE_NAME} PRIVATE
    ${HI_INSTANCE_DIR} ${HARE_CORE_ROOT}/common ${HARE_CORE_ROOT}/ref ${HARE_X86_ROOT}/avx256 ${HARE_APIPKC_ROOT}
  )
  target_compile_definitions(bench_${HI_SAFE_NAME} PRIVATE HARE_INSTANCE_NAME="${HI_NAME}")
  target_link_libraries(bench_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME} m)
  hare_apply_instance_compile_options(bench_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

  # Reference instances generate KAT; Reference and Optimized instances replay KAT.
  if(HI_ROLE_UPPER STREQUAL "REFERENCE")
    add_executable(kat_${HI_SAFE_NAME}
      ${HARE_APIPKC_ROOT}/KAT_KEM.c
      ${HARE_APIPKC_ROOT}/auxfunc.c
      ${HARE_APIPKC_ROOT}/drng.c
      ${HI_INSTANCE_DIR}/KEM_AlgorithmInstance.c
    )
    target_include_directories(kat_${HI_SAFE_NAME} PRIVATE
      ${HI_INSTANCE_DIR}
      ${HARE_APIPKC_ROOT}
      ${HARE_CORE_ROOT}/common
      ${HARE_CORE_ROOT}/ref
      ${HARE_X86_ROOT}/avx256
    )
    target_link_libraries(kat_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
    hare_apply_instance_compile_options(kat_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

    add_custom_target(run_kat_${HI_SAFE_NAME}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/Test_Vectors
      COMMAND $<TARGET_FILE:kat_${HI_SAFE_NAME}>
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS kat_${HI_SAFE_NAME}
    )

    set_property(GLOBAL APPEND PROPERTY HARE_REFERENCE_RUN_KAT_TARGETS run_kat_${HI_SAFE_NAME})
  endif()

  if(HI_ROLE_UPPER STREQUAL "REFERENCE" OR HI_ROLE_UPPER STREQUAL "OPTIMIZED")
    add_executable(verify_kat_kem_${HI_SAFE_NAME}
      ${CMAKE_CURRENT_SOURCE_DIR}/Self_Evaluation/tests/verify_kat_kem.c
      ${HI_INSTANCE_DIR}/KEM_AlgorithmInstance.c
    )
    target_include_directories(verify_kat_kem_${HI_SAFE_NAME} PRIVATE
      ${HI_INSTANCE_DIR}
      ${HARE_CORE_ROOT}/common
      ${HARE_CORE_ROOT}/ref
      ${HARE_X86_ROOT}/avx256
      ${HARE_APIPKC_ROOT}
    )
    target_compile_definitions(verify_kat_kem_${HI_SAFE_NAME} PRIVATE HARE_INSTANCE_NAME="${HI_NAME}")
    target_link_libraries(verify_kat_kem_${HI_SAFE_NAME} PRIVATE core_${HI_SAFE_NAME})
    hare_apply_instance_compile_options(verify_kat_kem_${HI_SAFE_NAME} ${HI_ROLE_UPPER} ${HI_CORE_KIND_UPPER})

    add_custom_target(verify_kat_${HI_SAFE_NAME}
      COMMAND $<TARGET_FILE:verify_kat_kem_${HI_SAFE_NAME}>
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS verify_kat_kem_${HI_SAFE_NAME}
    )

    if(HI_ROLE_UPPER STREQUAL "REFERENCE")
      set_property(GLOBAL APPEND PROPERTY HARE_REFERENCE_VERIFY_KAT_TARGETS verify_kat_${HI_SAFE_NAME})
    elseif(HI_ROLE_UPPER STREQUAL "OPTIMIZED")
      set_property(GLOBAL APPEND PROPERTY HARE_OPTIMIZED_VERIFY_KAT_TARGETS verify_kat_${HI_SAFE_NAME})
    endif()
  endif()

  add_test(NAME test_gf2x_property_${HI_SAFE_NAME} COMMAND gf2x_property_${HI_SAFE_NAME})
  add_test(NAME test_code_roundtrip_${HI_SAFE_NAME} COMMAND code_roundtrip_${HI_SAFE_NAME})
  add_test(NAME test_api_contract_${HI_SAFE_NAME} COMMAND api_contract_${HI_SAFE_NAME})
  add_test(NAME test_rs_boundary_${HI_SAFE_NAME} COMMAND rs_boundary_${HI_SAFE_NAME})
  if(HI_BACKEND_UPPER STREQUAL "KR")
    add_test(NAME test_kr_table_${HI_SAFE_NAME} COMMAND kr_table_${HI_SAFE_NAME})
    add_test(NAME test_kr_projection_${HI_SAFE_NAME} COMMAND kr_projection_${HI_SAFE_NAME})
    add_test(NAME test_kr_systematic_${HI_SAFE_NAME} COMMAND kr_systematic_${HI_SAFE_NAME})
  endif()
  add_test(NAME test_kem_loop_${HI_SAFE_NAME} COMMAND check_${HI_SAFE_NAME})
  add_test(NAME test_tamper_${HI_SAFE_NAME} COMMAND tamper_${HI_SAFE_NAME})
endfunction()
