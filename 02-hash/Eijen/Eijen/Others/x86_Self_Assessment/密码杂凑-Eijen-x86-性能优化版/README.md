# 密码杂凑-Eijen-x86-性能优化版

对应指引中的性能优化版。单消息接口使用 x86-64 scalar/O3 路径；
四路等长短消息接口 `eijen_hash4_same` 使用 AVX2 intrinsic 进行
4-way permutation。

实现位置：

- `algorithm_source/include/eijen.h`
- `algorithm_source/src/eijen_internal.h`
- `algorithm_source/src/eijen_avx2.c`

构建目标：

- `kat`
- `bench`

编译配置：

```sh
gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
```

自评估代码和数据：

- `self_assessment/tests/eijen_kat.c`
- `self_assessment/tools/eijen_bench.c`
- `self_assessment/data/eijen_kat.tsv`
- `self_assessment/run_self_assessment.sh`
- `self_assessment/results/`

依赖说明：

- `docs/dependencies.md`

自评估报告：

- `自评估报告.md`

单独构建：

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j 1
ctest --test-dir build --output-on-failure
```

完整自评估复现：

```sh
self_assessment/run_self_assessment.sh
```
