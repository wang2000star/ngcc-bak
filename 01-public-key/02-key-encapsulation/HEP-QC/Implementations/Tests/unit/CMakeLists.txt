cmake_minimum_required(VERSION 3.21)
project(hep_qc_unit_tests C CXX)

enable_testing()

if(NOT DEFINED HEP_QC_ARCH)
    message(FATAL_ERROR "HEP_QC_ARCH must be set (ref or x86_64)")
endif()
if(NOT DEFINED VARIANTS)
    message(FATAL_ERROR "VARIANTS (e.g. \"hep-qc-1;hep-qc-3;hep-qc-5;hep-qc-7\") must be set by tests/CMakeLists.txt")
endif()

set(TESTS_DIR     ${CMAKE_SOURCE_DIR}/Tests/unit)
set(GF_TEST_SRC   ${TESTS_DIR}/test_gf.c)
set(RS_TEST_SRC   ${TESTS_DIR}/test_reed_solomon.c)
set(VEC_TEST_SRC  ${TESTS_DIR}/test_vector.c)
set(MAIN_TEST_SRC ${TESTS_DIR}/tests_main.c)

set(COMMON_INCLUDES
        ${CMAKE_SOURCE_DIR}/Implementations/common
        ${CMAKE_SOURCE_DIR}/Lib/drng
        ${CMAKE_SOURCE_DIR}/Lib/auxfunc
        ${CMAKE_SOURCE_DIR}/Tests/external/munit
        ${CMAKE_SOURCE_DIR}/Tests
)

foreach(param_variant IN LISTS VARIANTS)
    string(REPLACE "-" "_" safe_param_tmp ${param_variant})
    string(TOUPPER ${safe_param_tmp} safe_param)

    set(lib_target    ${safe_param}_${HEP_QC_ARCH})
    set(exe_name      TEST_UNIT_${safe_param}_${HEP_QC_ARCH})
    set(PARAM_INCLUDES
            ${CMAKE_SOURCE_DIR}/Implementations/common/${param_variant}
            ${CMAKE_SOURCE_DIR}/Implementations/${HEP_QC_ARCH}
            ${CMAKE_SOURCE_DIR}/Implementations/${HEP_QC_ARCH}/${param_variant}
    )

    set(unit_sources
            ${GF_TEST_SRC}
            ${RS_TEST_SRC}
            ${VEC_TEST_SRC}
            ${MAIN_TEST_SRC}
    )

    add_executable(${exe_name} ${unit_sources})

    target_link_libraries(${exe_name} PRIVATE
            munit
            ${lib_target}
            drng
            auxfunc
    )

    target_compile_definitions(${exe_name} PRIVATE
        REF_MODE
    )

    target_include_directories(${exe_name} PRIVATE
            ${COMMON_INCLUDES}
            ${PARAM_INCLUDES}
    )

    add_test(NAME ${exe_name} COMMAND ${exe_name})
    set_tests_properties(${exe_name} PROPERTIES LABELS "unit")
endforeach()
