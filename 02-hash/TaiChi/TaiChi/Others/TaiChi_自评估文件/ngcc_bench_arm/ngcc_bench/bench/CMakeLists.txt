add_library(benchlib
    hash_bench.c
    ${PROJECT_SOURCE_DIR}/src/generate_json_report.c
    ${PROJECT_SOURCE_DIR}/src/get_timestamp.c
    ${PROJECT_SOURCE_DIR}/src/runtime_mem_measure.c
    ${PROJECT_SOURCE_DIR}/src/static_mem_parse.c
)

target_include_directories(benchlib PUBLIC
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/bench/include
    ${PROJECT_SOURCE_DIR}/adapter/include
)

target_link_libraries(benchlib
    elf
    cjson
)

add_executable(bench_worker
    bench_worker.c
    ${PROJECT_SOURCE_DIR}/src/registry.c
)

target_include_directories(bench_worker PUBLIC
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/bench/include
    ${PROJECT_SOURCE_DIR}/adapter/include
)

target_link_libraries(bench_worker
    adapter
)

function(add_taichi_single_worker target digest_bits hash_func lib)
    add_executable(${target}
        bench_worker.c
    )

    target_compile_definitions(${target} PRIVATE
        SINGLE_WORKER_HASH_FUNC=${hash_func}
        SINGLE_WORKER_DIGEST_BITS=${digest_bits}
    )

    target_include_directories(${target} PUBLIC
        ${PROJECT_SOURCE_DIR}/include
        ${PROJECT_SOURCE_DIR}/bench/include
        ${PROJECT_SOURCE_DIR}/adapter/include
    )

    target_link_libraries(${target}
        ${lib}
    )
endfunction()

add_taichi_single_worker(
    bench_worker_taichi_512_ref
    512
    TaiChi_512_ref_CryptHash
    taichi_512_ref
)

add_taichi_single_worker(
    bench_worker_taichi_768_ref
    768
    TaiChi_768_ref_CryptHash
    taichi_768_ref
)

add_taichi_single_worker(
    bench_worker_taichi_1024_ref
    1024
    TaiChi_1024_ref_CryptHash
    taichi_1024_ref
)

add_taichi_single_worker(
    bench_worker_taichi_512_op_per
    512
    TaiChi_512_op_per_CryptHash
    taichi_512_op_per
)

add_taichi_single_worker(
    bench_worker_taichi_768_op_per
    768
    TaiChi_768_op_per_CryptHash
    taichi_768_op_per
)

add_taichi_single_worker(
    bench_worker_taichi_1024_op_per
    1024
    TaiChi_1024_op_per_CryptHash
    taichi_1024_op_per
)

add_taichi_single_worker(
    bench_worker_taichi_512_op_res
    512
    TaiChi_512_op_res_CryptHash
    taichi_512_op_res
)

add_taichi_single_worker(
    bench_worker_taichi_768_op_res
    768
    TaiChi_768_op_res_CryptHash
    taichi_768_op_res
)

add_taichi_single_worker(
    bench_worker_taichi_1024_op_res
    1024
    TaiChi_1024_op_res_CryptHash
    taichi_1024_op_res
)