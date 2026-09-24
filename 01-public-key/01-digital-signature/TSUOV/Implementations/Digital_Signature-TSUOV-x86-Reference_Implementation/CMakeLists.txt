PROJECT(PQC_BENCH DESCRIPTION "NGCC digital-signature self-assessment framework")

cmake_minimum_required(VERSION 3.16)

set(CMAKE_C_STANDARD 11)

option(PKC_OPTIMIZED_IMPL "Use the optimized PKC implementation when ON." ON)

if(PKC_OPTIMIZED_IMPL)
    set(CMAKE_C_FLAGS "-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    enable_language(ASM)
    set(CMAKE_ASM_FLAGS "-O3 -march=x86-64 -mavx2 -mtune=native -fomit-frame-pointer")
else()
    set(CMAKE_C_FLAGS "-std=c99 -Wpedantic -Wall -Wextra -O2")
endif()

include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/adapter/include
)

include(${CMAKE_SOURCE_DIR}/cmake/SigAlgorithmDiscovery.cmake)

add_subdirectory(API_PKC)
add_subdirectory(bench)

set(NGCC_COMMON_SRCS
    src/main.c
    src/parse_option.c
    src/print_banner.c
    src/registry.c
)

set(NGCC_BENCH_TARGETS "")
set(_alg_id 0)

foreach(FOLDER ${SIG_ALG_FOLDERS})
    sig_parse_folder_name(${FOLDER} FAMILY LEVEL)
    string(TOLOWER "${FAMILY}" FAMILY_LC)
    set(ALG_DIR
        ${PROJECT_SOURCE_DIR}/API_PKC/Implementations/${SIG_IMPL_DIR_NAME}/${FOLDER})
    set(SIG_LIB_REL_PATH
        "API_PKC/Implementations/${SIG_IMPL_DIR_NAME}/libsigalg_${FOLDER}.a")

    add_executable(ngcc_bench_${FOLDER}
        ${NGCC_COMMON_SRCS}
        adapter/sig/sig_adapter.c
    )
    target_include_directories(ngcc_bench_${FOLDER} PRIVATE
        ${PROJECT_SOURCE_DIR}/bench/include
        ${ALG_DIR}
    )
    target_compile_definitions(ngcc_bench_${FOLDER} PRIVATE
        ALG_FAMILY="${FAMILY}"
        ALG_LEVEL=${LEVEL}
        ALG_FOLDER="${FOLDER}"
        ALG_ID=${_alg_id}
        ALG_CLI_HYPHEN="${FAMILY_LC}-${LEVEL}"
        ALG_CLI_UNDER="${FAMILY_LC}_${LEVEL}"
        SIG_LIB_REL_PATH="${SIG_LIB_REL_PATH}"
    )
    if(PKC_OPTIMIZED_IMPL)
        target_compile_definitions(ngcc_bench_${FOLDER} PRIVATE PKC_OPTIMIZED_IMPL)
    endif()
    target_compile_options(ngcc_bench_${FOLDER} PRIVATE -std=gnu99 -O2 -Wall -Wextra -fno-pie -Wno-pedantic)
    set_target_properties(ngcc_bench_${FOLDER} PROPERTIES LINK_FLAGS "-no-pie")
    target_link_libraries(ngcc_bench_${FOLDER} benchlib sigalg_${FOLDER})

    list(APPEND NGCC_BENCH_TARGETS ngcc_bench_${FOLDER})
    math(EXPR _alg_id "${_alg_id} + 1")
endforeach()

add_custom_target(ngcc_bench DEPENDS ${NGCC_BENCH_TARGETS})
