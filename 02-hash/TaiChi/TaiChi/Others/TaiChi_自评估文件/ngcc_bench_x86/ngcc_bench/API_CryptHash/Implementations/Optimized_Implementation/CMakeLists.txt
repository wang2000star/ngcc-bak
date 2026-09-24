add_library(taichi_512_op_per
    TaiChi-512-op-per/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_512_op_per PRIVATE CryptHash=TaiChi_512_op_per_CryptHash)
target_compile_options(taichi_512_op_per PRIVATE ${TAICHI_OP_PER_FLAGS})
target_link_options(taichi_512_op_per PRIVATE -flto)
target_include_directories(taichi_512_op_per PUBLIC TaiChi-512-op-per/include)

add_library(taichi_768_op_per
    TaiChi-768-op-per/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_768_op_per PRIVATE CryptHash=TaiChi_768_op_per_CryptHash)
target_compile_options(taichi_768_op_per PRIVATE ${TAICHI_OP_PER_FLAGS})
target_link_options(taichi_768_op_per PRIVATE -flto)
target_include_directories(taichi_768_op_per PUBLIC TaiChi-768-op-per/include)

add_library(taichi_1024_op_per
    TaiChi-1024-op-per/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_1024_op_per PRIVATE CryptHash=TaiChi_1024_op_per_CryptHash)
target_compile_options(taichi_1024_op_per PRIVATE ${TAICHI_OP_PER_FLAGS})
target_link_options(taichi_1024_op_per PRIVATE -flto)
target_include_directories(taichi_1024_op_per PUBLIC TaiChi-1024-op-per/include)

add_library(taichi_512_op_res
    TaiChi-512-op-res/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_512_op_res PRIVATE CryptHash=TaiChi_512_op_res_CryptHash)
target_compile_options(taichi_512_op_res PRIVATE ${TAICHI_OP_RES_FLAGS})
target_link_options(taichi_512_op_res PRIVATE -flto)
target_include_directories(taichi_512_op_res PUBLIC TaiChi-512-op-res/include)

add_library(taichi_768_op_res
    TaiChi-768-op-res/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_768_op_res PRIVATE CryptHash=TaiChi_768_op_res_CryptHash)
target_compile_options(taichi_768_op_res PRIVATE ${TAICHI_OP_RES_FLAGS})
target_link_options(taichi_768_op_res PRIVATE -flto)
target_include_directories(taichi_768_op_res PUBLIC TaiChi-768-op-res/include)

add_library(taichi_1024_op_res
    TaiChi-1024-op-res/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_1024_op_res PRIVATE CryptHash=TaiChi_1024_op_res_CryptHash)
target_compile_options(taichi_1024_op_res PRIVATE ${TAICHI_OP_RES_FLAGS})
target_link_options(taichi_1024_op_res PRIVATE -flto)
target_include_directories(taichi_1024_op_res PUBLIC TaiChi-1024-op-res/include)