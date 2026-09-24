LLH算法ASIC实现自评估测试提交内容说明

本目录包含API_CryptHash文件夹和build文件夹，其中
API_CryptHash文件夹中包含verilog源码及测试向量，build文件夹
中包含log、网表及报告文件等。
上述目录结构符合《新一代商用密码算法ASIC实现自评估指引》中的
结构要求。

具体目录结构如下：
├── 低延迟杂凑算法LLH ASIC设计说明.docx
├── API_CryptHash
│   ├── Constraints
│   │   └── hash_algorithm.sdc
│   ├── Implementations
│   │   ├── Basic_Implementation
│   │   │   ├── llh_axi.v
│   │   │   ├── llh_core.v
│   │   │   ├── llh_padding.v
│   │   │   ├── llh_rc.v
│   │   │   ├── llh_shift.v
│   │   │   └── llh_top.v
│   │   ├── HighPerformance_Implementation
│   │   │   ├── llh_axi.v
│   │   │   ├── llh_core.v
│   │   │   ├── llh_padding.v
│   │   │   ├── llh_rc.v
│   │   │   ├── llh_shift.v
│   │   │   └── llh_top.v
│   │   └── LowSize_Implementation
│   │       ├── llh_axi.v
│   │       ├── llh_core.v
│   │       ├── llh_padding.v
│   │       ├── llh_shift_1024.v
│   │       ├── llh_shift_256.v
│   │       ├── llh_shift_512.v
│   │       ├── llh_shift_768.v
│   │       └── llh_top.v
│   ├── Normalized
│   │   ├── normalize.py
│   │   ├── norm_calc.tcl
│   │   └── norm_param.txt
│   ├── Scripts
│   │   └── run_dc.tcl
│   └── Test_Vector
│       ├── KAT_Incremental.txt
│       ├── KAT_LongMsg.txt
│       └── KAT_ShortMsg.txt
├── build
│   ├── log
│   │   └── result_293_1794_5986_7874_22089_0197_28389_9990.log
│   ├── netlist
│   │   ├── hash_top_HighPerformance.v
│   │   └── hash_top_LowSize.v
│   ├── report
│   │   ├── dc
│   │   │   ├── hash_top_HighPerformance.qor
│   │   │   └── hash_top_LowSize.qor
│   │   └── normalized
│   │       ├── 归一化指标计算报告-性能优化版.docx
│   │       └── 归一化指标计算报告-资源优化版.docx
│   └── result
│       ├── 低延迟杂凑算法LLH自评估测试报告-性能优化版.docx
│       └── 低延迟杂凑算法LLH自评估测试报告-资源优化版.docx
└── README.txt

优化手段：通过常数赋值优化面积资源
复现步骤：1）功能测试：
a．vcs -debug_all -full64 -l comp.log -debug_access +mda -sverilog -timescale=1ns/1ps -f file.f
b．./simv
2）面积测试：见API_CryptHash/ Scripts/run_dc.tcl
3）功耗测试：pa_shell -tcl run.tcl
4）归一化计算：tclsh run_normalize.tcl

