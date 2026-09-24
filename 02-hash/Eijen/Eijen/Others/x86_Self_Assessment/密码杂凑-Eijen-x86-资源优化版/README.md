# 密码杂凑-Eijen-x86-资源优化版

对应指引中的资源优化版。当前资源版复用 C99 scalar 实现，并通过
`-Os -flto` 生成尺寸优先的二进制；实现采用流式接口，不需要一次性
加载完整消息。

实现位置：

- `algorithm_source/include/eijen.h`
- `algorithm_source/src/eijen_internal.h`
- `algorithm_source/src/eijen_ref.c`

构建目标：

- `kat`
- `bench`

编译配置：

```sh
gcc -Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
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
