# 密码杂凑-Eijen-x86-参考实现版

对应指引中的参考实现版。

实现位置：

- `algorithm_source/include/eijen.h`
- `algorithm_source/src/eijen_internal.h`
- `algorithm_source/src/eijen_ref.c`

构建目标：

- `kat`
- `bench`

编译配置：

```sh
gcc -std=c99 -Wpedantic -Wall -Wextra -O2
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
