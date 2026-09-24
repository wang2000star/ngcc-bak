# ZEN KEM Aligned Minimal Package

这个压缩包目录只保留了三套参数集的必要源码：

- `optimized_implementation_128v3`
- `optimized_implementation_256`
- `optimized_implementation_512`

每个子目录中仅保留：

- `rtl/`
- `constraints/`
- `scripts/`
- `software/ZEN_swift_*` 参考对齐后的软件源码
- `software/scripts/`
- `testdata/` 中 `balanced` 路径 TB 真实使用到的向量
- `zen_pke_keygen_path_tb.sv`
- `zen_pke_enc_path_tb.sv`
- `zen_pke_dec_path_tb.sv`
- `run_xcv80_board_gen_xpr.sh`
- `run_xcv80_board_gui_xpr.sh`

没有保留：

- `docs/`
- `build_*`
- `vivado_projects*`
- `.Xil/`
- `software/build_self_eval/`
- `software/ZEN_swift_*/output/`
- `KAT_KEM` 等编译产物
- 其他非 `balanced` TB

KEM 参考对齐状态：

- `ZEN-128` SHA256: `b14b8a6438818253239bfa38b85c4668ee7c0c54ce1631b062b11cf08966da9e`
- `ZEN-256` SHA256: `df1088014f190a99666958d83b12fbef10706ffc84e0075574cdf3e7eb5fd98e`
- `ZEN-512` SHA256: `943a865566ce087e455bcdef2cab2a9ba1759ec2dd9c31622f7d1206d13e6af8`

以上哈希表示本包中的 `software/ZEN_swift_*` 重新运行 `KAT_KEM` 后，
`Seed / PK / SK / CT / SS` 与参考实现逐字段完全一致。
