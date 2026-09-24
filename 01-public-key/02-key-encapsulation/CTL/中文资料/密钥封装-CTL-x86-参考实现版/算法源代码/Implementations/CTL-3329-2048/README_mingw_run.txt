CTL KEM 自评估代码使用说明（MinGW/Windows）
================================================================================

相关文件
--------------------------------------------------------------------------------
  - test_kem_correctness_ctl.c : 正确性自检
  - benchmark_selfeval_ctl.c   : 性能、资源消耗、传输与存储开销测试
  - KEM_AlgorithmInstance.c/.h : KEM 对外接口封装

推荐使用 Makefile 编译
--------------------------------------------------------------------------------
    make test_kem_correctness_ctl
    make benchmark_selfeval_ctl

手工编译时，请将 CTL_SOURCE_FILES 替换为本目录实际源文件列表，并使用新的统一文件名：

    KEM_AlgorithmInstance.c api_3329_2048.c codec.c fft.c fnr.c kem257.c kem769.c kem3329.c keygen.c ntru_solver.c ntru_utils.c ng_fxp.c ng_mp31.c ng_ntru.c ng_poly.c ng_zint31.c sha3.c modqp.c prng.c auxfunc.c drng.c

示例
--------------------------------------------------------------------------------
    gcc -std=c99 -O2 -Wall -Wextra -Wpedantic test_kem_correctness_ctl.c CTL_SOURCE_FILES -o test_kem.exe
    gcc -std=c99 -O2 -Wall -Wextra -Wpedantic benchmark_selfeval_ctl.c CTL_SOURCE_FILES -o benchmark.exe -lpsapi

运行
--------------------------------------------------------------------------------
    test_kem.exe
    benchmark.exe 10000

说明
--------------------------------------------------------------------------------
  - benchmark.exe 后面的数字是测试次数，建议不低于 100。
  - 在 MinGW/Windows 下，资源消耗测试使用 GetProcessMemoryInfo，因此需要链接 -lpsapi。