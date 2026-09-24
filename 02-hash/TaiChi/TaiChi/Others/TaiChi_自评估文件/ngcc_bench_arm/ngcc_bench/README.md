# NGCC Test Framework

一种与算法具体实现解耦的算法测试框架，按照算法的类别设计并实现测试流程，目前已支持的算法类别包括：
- 分组密码
- 哈希函数
- PKC（密钥封装算法、密钥协商算法、公钥加密算法）

## 使用方法

编译

```
mkdir build && cd build
cmake ..
make -j`nproc`
```

运行

```
Usage: ngcc_bench [options]
Options:
  -a <algorithm>      Specify algorithm to benchmark. Separeted by ','
  -t <times>          Number of times to run in performance benchmark
  -l <len>            Length of the payload in performance benchmark. Valid only for block ciphers and hash.
  -h                  Show this help message
```

例如，运行mlkem-768的测试用例：

```
./ngcc_bench -a mlkem-768
```

运行该命令后将会在reports目录下生成测试报告，并且将运行日志保存到logs目录下。

### 优化实现

如果使用者提供了优化版的算法实现，可以将优化版实现放在API_XXX/Implementations/Optimized_Implementation/目录下，并在编译时通过下列命令使测试框架使用该目录下的代码进行编译：

```
# use the PKC optimized implmentation
cmake -DPKC_OPTIMIZED_IMPL=on
# use the cipher optimized implementation
cmake -DCIPHER_OPTIMIZED_IMPL=on
# use the hash optimized implementation
cmake -DHASH_OPTIMIZED_IMPL=on
```

## 测试框架

框架的整体架构如下图所示：

```
|---------------------------|
|          API_***          |   /* 算法实现层 */
|---------------------------|
            |
|---------------------------|
|          adapter          |   /* 统一接口封装层 */
|---------------------------|
            |
|---------------------------|
|          bench            |   /* 按类实现的测试层 */
|---------------------------|
            |
|---------------------------|
|        src/main           |   /* 测试程序入口 */
|---------------------------|
```

为了将测试流程与算法具体实现进行解耦，在算法实现的基础上封装了一层adpater层，该层次抽象的作用主要是将算法按照算法类型进行统一接口封装，比如对于密钥封装算法，为了能够进行统一测试，该算法的统一接口层必须提供以下接口：

- 公钥长度、私钥长度、共享密钥长度、密文长度
- 密钥封装接口
- 密钥解封装接口

然后在KEM功能测试用例中，按照预设的接口设计测试流程：获取需要分配的空间-->调用密钥封装接口生成随机密钥与密文-->调用解封装接口进行解封装-->对比两个接口输出的共享密钥是否一致？

而算法在完成统一接口封装后，只需要通过src/registry.c中的接口向测试程序注册该算法，测试程序识别该算法后，根据命令行参数决定是否执行该算法的相关测试。

### 整合新的算法

如果用户需要将自己的算法实现整合到该框架中运行测试，则需要将算法实现的代码放入到对应的API_XXX目录下，并且确保能够编译生成一个独立的库文件。

随后在adapter目录下对应的子目录下新增算法对应的adapter实现，在实现算法adapter时需要参考adapter/include目录下不同类别算法的adapter层抽象定义进行接口实现。

完成adapter实现后，调用定义在src/registry.c文件中的算法注册接口实现算法注册函数，在算法注册函数中为该算法指定算法ID、算法类型、以及算法的统一接口，并将该函数声明暴露在adapter/include/下的头文件中，由主函数调用该函数完成算法注册。