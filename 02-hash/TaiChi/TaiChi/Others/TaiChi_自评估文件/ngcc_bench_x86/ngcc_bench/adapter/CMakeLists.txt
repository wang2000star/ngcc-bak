add_library(adapter
    crypthash/taichi_adapter.c
    ${PROJECT_SOURCE_DIR}/src/registry.c
)

target_include_directories(adapter PUBLIC
    ${PROJECT_SOURCE_DIR}/adapter/include
)

target_link_libraries(adapter
    taichi_512_ref
    taichi_768_ref
    taichi_1024_ref
    taichi_512_op_per
    taichi_768_op_per
    taichi_1024_op_per
    taichi_512_op_res
    taichi_768_op_res
    taichi_1024_op_res
)