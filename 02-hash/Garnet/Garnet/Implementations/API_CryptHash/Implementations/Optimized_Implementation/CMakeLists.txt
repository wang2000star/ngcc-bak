# 启用汇编支持
enable_language(ASM)

# 同样命名为 garnet_512 目标，仅包含汇编源码
add_library(garnet_512
    Garnet_512/Garnet_512.S
)

add_library(garnet_768
    Garnet_768/Garnet_768.S
)

add_library(sm3
    ${CMAKE_CURRENT_SOURCE_DIR}/../Reference_Implementation/SM3/sm3.c
)
target_include_directories(sm3 PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/../Reference_Implementation/SM3/include
)