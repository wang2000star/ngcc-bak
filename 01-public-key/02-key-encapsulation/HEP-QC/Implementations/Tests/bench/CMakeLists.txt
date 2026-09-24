cmake_minimum_required(VERSION 3.21)
include(CTest)

file(GLOB BENCH_SRCS
        "${CMAKE_CURRENT_SOURCE_DIR}/benchmark_*.c"
)

foreach(variant IN LISTS VARIANTS)
    string(REPLACE "-" "_" safe_var_tmp ${variant})
    string(TOUPPER ${safe_var_tmp} safe_var)

    foreach(src IN LISTS BENCH_SRCS)
        get_filename_component(name ${src} NAME_WE)
        set(exe "${name}_${safe_var}")

        add_executable(${exe} ${src})
        target_link_libraries(${exe} PRIVATE
                ${safe_var}_${HEP_QC_ARCH}
                drng
                auxfunc
        )
        target_compile_definitions(${exe} PRIVATE
            REF_MODE
        )
        target_include_directories(${exe} PRIVATE
                ${CMAKE_SOURCE_DIR}/Tests/bench
                ${CMAKE_SOURCE_DIR}/Implementations/common
                ${CMAKE_SOURCE_DIR}/Implementations/${HEP_QC_ARCH}/${variant}
                ${CMAKE_SOURCE_DIR}/Lib/drng
                ${CMAKE_SOURCE_DIR}/Lib/auxfunc
        )
       # add_test(NAME ${exe} COMMAND ${exe})
       # set_tests_properties(${exe} PROPERTIES LABELS "benchmark")
    endforeach()
endforeach()
