cmake_minimum_required(VERSION 3.21)
include(CTest)

file(GLOB API_TEST_SRCS
        "${CMAKE_CURRENT_SOURCE_DIR}/test_*.c"
)

set(API_MAIN_SRC "${CMAKE_CURRENT_SOURCE_DIR}/tests_main.c")

foreach(variant IN LISTS VARIANTS)
    string(REPLACE "-" "_" safe_var_tmp ${variant})
    string(TOUPPER ${safe_var_tmp} safe_var)
    set(exe "TEST_API_${safe_var}")

    add_executable(${exe}
            ${API_MAIN_SRC}
            ${API_TEST_SRCS}
    )

    target_link_libraries(${exe} PRIVATE
            munit
            ${safe_var}_${HEP_QC_ARCH}
            drng
            auxfunc
    )

    target_compile_definitions(${exe} PRIVATE
            REF_MODE
    )

    target_include_directories(${exe} PRIVATE
            ${CMAKE_SOURCE_DIR}/Implementations/common
            ${CMAKE_SOURCE_DIR}/Implementations/${HEP_QC_ARCH}/${variant}
            ${CMAKE_SOURCE_DIR}/Lib/drng
            ${CMAKE_SOURCE_DIR}/Lib/auxfunc
            ${CMAKE_CURRENT_SOURCE_DIR}
            ${CMAKE_SOURCE_DIR}/Tests
            ${CMAKE_SOURCE_DIR}/Tests/external/munit
    )

    add_test(NAME ${exe} COMMAND ${exe})
    set_tests_properties(${exe} PROPERTIES LABELS "api")
endforeach()
