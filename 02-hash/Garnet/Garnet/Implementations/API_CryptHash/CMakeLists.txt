# 优化实现使用 GAS/AT&T 语法 + SysV x86-64 ABI 的 .S 汇编，
# 仅能在 Linux GCC/Clang 下编译。Windows (MSVC/MinGW) 下回退到纯 C 参考实现。
if(HASH_OPTIMIZED_IMPL AND NOT WIN32)
    add_subdirectory(Implementations/Optimized_Implementation)
else()
    add_subdirectory(Implementations/Reference_Implementation)
endif()