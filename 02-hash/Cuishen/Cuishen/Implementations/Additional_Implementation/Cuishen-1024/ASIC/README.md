# Cuishen-1024 — ASIC Implementation


## Synthesis Environment

| Item                  | Value                                              |
|------------------------|----------------------------------------------------|
| Tool                   | Synopsys Design Compiler L-2016.03-SP1 (DC2016)    |
| Process / Library      | TSMC 65nm, `tcbn65gplusbwp12tbc_ccs`               |
| Operating condition    | BCCOM, 1.1 V                                       |
| Wire load model        | ZeroWireload (segmented mode)                      |
| Clock uncertainty       | 0.10 ns                                            |
| Top module              | `cuishen` (no external memories / I/O pads modeled) |


## Files

- `cuishen_e_constants.v` — E_CONST round-constant table (64 entries)
- `cuishen_iv_constants.v` — IV constants (IV_1 for t, IV_2 for b)
- `cuishen_key_mem.v` — shared key-schedule sliding window (m, b, cnt)
- `cuishen_core.v` — core
- `cuishen.v` — 32-bit memory-mapped wrapper (top-level for synthesis)
- `tb_cuishen_2_12.v` — self-checking testbench (KAT_2_12 short vectors)
- `tb_cuishen_2_23.v` — self-checking testbench (all-zero / all-one
  vectors)
  
## Running the Testbenches with Icarus Verilog

### KAT_2_12 (short vectors, finalization-only path)

```
iverilog -g2001 -o sim_212 \
    cuishen_e_constants.v cuishen_iv_constants.v cuishen_key_mem.v \
    cuishen_core.v cuishen.v tb_cuishen_2_12.v
vvp sim_212
```


### Long vectors (compression path)

```
iverilog -g2001 -o sim_223 \
    cuishen_e_constants.v cuishen_iv_constants.v cuishen_key_mem.v \
    cuishen_core.v cuishen.v tb_cuishen_2_23.v
vvp sim_223
```

## Reproducing the Reports

```
dc_shell -f synth.tcl   # top design `cuishen`, library
                         # tcbn65gplusbwp12tbc_ccs, BCCOM corner,
                         # clock period 2.00ns, uncertainty 0.10ns
report_area   > area.rpt
report_power  > power.rpt
report_timing -path full -delay max -max_paths 10 > timing.rpt
```
