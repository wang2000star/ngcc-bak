add_library(benchlib
    sig_bench.c
    ${PROJECT_SOURCE_DIR}/src/generate_json_report.c
    ${PROJECT_SOURCE_DIR}/src/get_timestamp.c
    ${PROJECT_SOURCE_DIR}/src/static_mem_parse.c
    ${PROJECT_SOURCE_DIR}/src/randombytes.c
    ${PROJECT_SOURCE_DIR}/src/print_banner.c
)

target_include_directories(benchlib PUBLIC
    ${PROJECT_SOURCE_DIR}/bench/include
    ${PROJECT_SOURCE_DIR}/adapter/include
    ${PROJECT_SOURCE_DIR}/include
)


if(PKC_OPTIMIZED_IMPL)
    target_compile_definitions(benchlib PRIVATE PKC_OPTIMIZED_IMPL)
endif()
