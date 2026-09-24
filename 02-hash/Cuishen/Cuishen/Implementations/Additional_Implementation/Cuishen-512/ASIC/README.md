# Cuishen-512 — ASIC Implementation

## Synthesis Environment

| Item                  | Value                                              |
|------------------------|----------------------------------------------------|
| Tool                   | Synopsys Design Compiler L-2016.03-SP1 (DC2016)    |
| Process / Library      | TSMC 65nm, `tcbn65gplusbwp12tbc_ccs`               |
| Operating condition    | BCCOM, 1.1 V                                       |
| Wire load model        | ZeroWireload (segmented mode)                      |
| Clock uncertainty       | 0.11 ns                                            |
| Top module              | `cuishen` (no external memories / I/O pads modeled) |

## Files

- `cuishen_pi_constants.v` — PI round-constant table
- `cuishen_iv_constants.v` — IV constants
- `cuishen_key_mem.v` — shared key-schedule sliding window
- `cuishen_core.v` — core
- `cuishen.v` — 32-bit memory-mapped wrapper (top-level for synthesis)
- `tb_cuishen_2_12.v` — self-checking testbench (KAT_2_12 short vectors)
- `tb_cuishen_2_23.v` — self-checking testbench (KAT_2_23 vectors #1, #2;)

## Running the Testbenches with Icarus Verilog

### KAT_2_12 (short vectors, finalization-only path)

```
iverilog -g2001 -o sim_212 \
    cuishen_pi_constants.v cuishen_iv_constants.v cuishen_key_mem.v \
    cuishen_core.v cuishen.v tb_cuishen_2_12.v
vvp sim_212
```

### KAT_2_23 (long vectors, compression path)

```
iverilog -g2001 -o sim_223 \
    cuishen_pi_constants.v cuishen_iv_constants.v cuishen_key_mem.v \
    cuishen_core.v cuishen.v tb_cuishen_2_23.v
vvp sim_223
```


## Reproducing the Reports

```
dc_shell -f synth.tcl   # top design `cuishen`, library
                         # tcbn65gplusbwp12tbc_ccs, BCCOM corner,
                         # clock period 1.75ns, uncertainty 0.11ns
report_area   > area.rpt
report_power  > power.rpt
report_timing -path full -delay max -max_paths 10 > timing.rpt
```

