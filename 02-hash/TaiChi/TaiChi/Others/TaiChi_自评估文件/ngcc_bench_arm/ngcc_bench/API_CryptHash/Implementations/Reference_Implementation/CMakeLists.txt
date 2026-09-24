add_library(taichi_512_ref
    TaiChi-512/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_512_ref PRIVATE CryptHash=TaiChi_512_ref_CryptHash)
target_compile_options(taichi_512_ref PRIVATE ${TAICHI_REF_FLAGS})
target_include_directories(taichi_512_ref PUBLIC TaiChi-512/include)

add_library(taichi_768_ref
    TaiChi-768/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_768_ref PRIVATE CryptHash=TaiChi_768_ref_CryptHash)
target_compile_options(taichi_768_ref PRIVATE ${TAICHI_REF_FLAGS})
target_include_directories(taichi_768_ref PUBLIC TaiChi-768/include)

add_library(taichi_1024_ref
    TaiChi-1024/CryptHash_AlgorithmInstance.c
)
target_compile_definitions(taichi_1024_ref PRIVATE CryptHash=TaiChi_1024_ref_CryptHash)
target_compile_options(taichi_1024_ref PRIVATE ${TAICHI_REF_FLAGS})
target_include_directories(taichi_1024_ref PUBLIC TaiChi-1024/include)