# Duet-512 — ASIC Implementation

## Synthesis Environment

| Item                  | Value                                              |
|------------------------|----------------------------------------------------|
| Tool                   | Synopsys Design Compiler L-2016.03-SP1 (DC2016)    |
| Process / Library      | TSMC 65nm, `tcbn65gplusbwp12tbc_ccs`               |
| Operating condition    | BCCOM, 1.1 V                                       |
| Wire load model        | ZeroWireload (segmented mode)                      |
| Clock period (constrained) | **1.00 ns**                                   |
| Clock uncertainty       | 0.10 ns                                            |
| Top module              | `duet` (no external memories / I/O pads modeled) |


## Files

- `duet_pi_constants_512.v` — round-constant ROM 
- `duet_perm_unit_512.v` — 960-bit permutation datapath, one round per
  clock, ROUNDS = 12
- `duet_core_512.v` — core: rate/capacity state, sigma word-permutation, f1/f2
  sequencing FSM, single shared instance of `duet_perm_unit`
- `duet_512.v` — 32-bit memory-mapped wrapper (top-level for synthesis)
- `tb_duet_512_2_12.v` — self-checking testbench (KAT_2_12 short vectors)
- `tb_duet_512_2_23.v` — self-checking testbench (all-zero / all-one
  8388608-bit vectors)

## Running the Testbenches with Icarus Verilog

### KAT_2_12 (short vectors, single padded block)

```
iverilog -g2001 -o sim_212 \
    duet_pi_constants_512.v duet_perm_unit_512.v duet_core_512.v duet_512.v tb_duet_512_2_12.v
vvp sim_212
```


### Long vectors (compression path)

```
iverilog -g2001 -o sim_223 \
    duet_pi_constants_512.v duet_perm_unit_512.v duet_core_512.v duet_512.v tb_duet_512_2_23.v
vvp sim_223
```


## Reproducing the Reports

```
dc_shell -f synth.tcl   # top design `duet`, library
                         # tcbn65gplusbwp12tbc_ccs, BCCOM corner,
                         # clock period 0.75ns, uncertainty 0.10ns
report_area   > area.rpt
report_power  > power.rpt
report_timing -path full -delay max -max_paths 10 > timing.rpt
```
