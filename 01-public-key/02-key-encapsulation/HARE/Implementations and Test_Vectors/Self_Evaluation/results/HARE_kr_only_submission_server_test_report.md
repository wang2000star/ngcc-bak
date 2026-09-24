# HARE KR-only Server Self-Evaluation Report

Report date: 2026-06-29

## 1. Test Object and Evidence Boundary

This report covers the active KR line in the HARE KR-only code package:

```text
HARE-128-KR / HARE-256-KR / HARE-384-KR / HARE-512-KR
```

HARE-128/256/384/512 correspond to HARE-2/5/7/9 in the algorithm specification. This KR-only package does not include historical hamming regression instances, and this report does not use hamming results.

The server tests were completed before this report and the top-level README structure clarification were added to the package. Subsequent package changes only add or update documentation, this report, and `MANIFEST.tsv` / `MANIFEST.sha256`; they do not modify implementation source code, parameters, KAT files, CMake targets, test scripts, `SERVER_TEST.md`, the server runner, x86/ARM optimized kernels, or the benchmark harness. The final outer zip SHA256 is provided by the accompanying `.sha256` file rather than embedded here, avoiding a self-referential package hash.

| Platform | Server result archive | SHA256 | Evidence boundary |
|---|---|---|---|
| x86 | `server_x86_20260627_171249.tar.gz` | `a07a8ab3c62259f4f251bfe401c437aa038e5a45165cfbefb0f32b1031597de5` | KR-only x86 server run; runner status 0 |
| ARM/SVE | `server_arm_20260627_183210.tar.gz` | `fb7afc14bd20cfbf80d1f7257a2d3f4c4b05bcb1d0b2923893835861f1561e36` | KR-only ARM/SVE server run; runner status 0 |

## 2. Test Environment

| Platform | OS / toolchain | CPU / instruction features | Test settings |
|---|---|---|---|
| x86 | CentOS Linux 8, GCC 8.3.1, CMake/CTest 3.20.2 | Intel Xeon Platinum 8269CY @ 2.50GHz, AVX2/PCLMULQDQ available | `HARE_SERVER_MODE=x86`, 10 instances x 100 repeats, warmup 10 |
| ARM/SVE | Ubuntu 22.04.4 LTS, GCC 11.4.0, CMake/CTest 3.22.1 | AArch64 HiSilicon, SVE/PMULL available, SVE vector length 256-bit | `HARE_SERVER_MODE=arm`, 10 instances x 100 repeats, warmup 10 |

The x86 benchmark records both `clock_process_cpu_time` microseconds and `x86_rdtsc_lfence` cycles, so this report gives both microseconds and kiloCycles. The ARM/SVE benchmark logs `cycles_source=unavailable_non_x86`, so ARM/SVE performance is reported in microseconds per operation.

## 3. Test Method

The tests were run according to `SERVER_TEST.md`:

1. Upload the package zip and `.sha256` file, then verify SHA256.
2. Extract the package into a fresh run directory.
3. Run the manifest and generated-artifact gates.
4. Build the package with CMake Release configuration.
5. Run CTest functional tests.
6. Generate KAT files, then replay KAT files with Reference and Optimized / Additional implementations.
7. Run the x86 PCLMUL objdump audit and ARM/SVE PMULL-on / PMULL-off objdump audits.
8. Run KR benchmarks and collect average keygen, encaps, and decaps timings.
9. Collect static size, stack usage, and peak RSS data.
10. Run the HARE-256-KR sanitizer subset on x86.

## 4. Gates and Functional Test Results

| Platform | Runner status | manifest / generated | CTest | KAT | objdump audit | sanitizer |
|---|---:|---|---|---|---|---|
| x86 | 0 | PASS; 4 instances | 72/72 PASS | ref + x86 optimized PASS | PCLMUL present, 4 objects, PASS | HARE-256-KR 18/18 PASS |
| ARM/SVE | 0 | PASS; 4 instances | PMULL-on 72/72 PASS; PMULL-off 72/72 PASS | ref + arm-sve PASS | PMULL-on present; PMULL-off absent; both PASS | not run |

The local SHA256 values of both server result archives matched their `.sha256` files, and both platform runs ended with `RUNNER_EXIT_STATUS=0`. Component hotspot profiling was marked `SKIPPED_RUN_COMPONENT_PROFILE_0` for this evidence run; this does not affect the functional, KAT, benchmark, resource, or objdump-audit conclusions.

## 5. Performance Results

Each entry is the average over 1000 timed samples.

### 5.1 x86: Reference vs x86 Optimized

`us / kcy` denotes microseconds per operation and kiloCycles per operation.

| Instance | keygen ref | keygen x86 | Speedup | encaps ref | encaps x86 | Speedup | decaps ref | decaps x86 | Speedup |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| HARE-128-KR | 3293.843 / 8258.9 | 91.261 / 230.7 | 36.09x | 7144.339 / 17908.5 | 373.368 / 937.6 | 19.13x | 10707.657 / 26841.0 | 600.557 / 1506.9 | 17.83x |
| HARE-256-KR | 14196.214 / 35579.4 | 297.962 / 748.7 | 47.64x | 29828.906 / 74753.8 | 1077.281 / 2702.0 | 27.69x | 45510.400 / 114053.8 | 1886.004 / 4729.3 | 24.13x |
| HARE-384-KR | 42475.982 / 106450.7 | 788.792 / 1979.5 | 53.85x | 87864.324 / 220198.8 | 2580.035 / 6468.5 | 34.06x | 131969.781 / 330734.3 | 4219.143 / 10576.7 | 31.28x |
| HARE-512-KR | 90552.299 / 226932.0 | 1840.834 / 4616.2 | 49.19x | 185469.476 / 464810.5 | 5215.508 / 13074.0 | 35.56x | 280170.502 / 702153.9 | 8566.785 / 21472.9 | 32.70x |

### 5.2 ARM/SVE: Reference vs PMULL-on Additional

The unit is microseconds per operation. PMULL-on is the primary ARM/SVE additional implementation performance line.

| Instance | keygen ref / SVE | Speedup | encaps ref / SVE | Speedup | decaps ref / SVE | Speedup |
|---|---:|---:|---:|---:|---:|---:|
| HARE-128-KR | 2042.901 / 129.266 | 15.80x | 4696.984 / 623.549 | 7.53x | 6994.636 / 940.663 | 7.44x |
| HARE-256-KR | 9190.431 / 434.687 | 21.14x | 19940.100 / 1803.076 | 11.06x | 30385.648 / 2830.633 | 10.73x |
| HARE-384-KR | 27479.664 / 1108.696 | 24.79x | 58122.522 / 4195.769 | 13.85x | 86985.274 / 6306.306 | 13.79x |
| HARE-512-KR | 61313.086 / 2730.310 | 22.46x | 127556.901 / 8173.983 | 15.61x | 192371.184 / 12167.172 | 15.81x |

### 5.3 ARM/SVE: PMULL-off Control

PMULL-off uses the same ARM/SVE additional implementation source path but disables PMULL for GF2X base multiplication. It is a fallback/control build and is not the primary performance claim.

| Instance | keygen off / on | Speedup | encaps off / on | Speedup | decaps off / on | Speedup |
|---|---:|---:|---:|---:|---:|---:|
| HARE-128-KR | 2076.654 / 129.266 | 16.06x | 4519.645 / 623.549 | 7.25x | 6802.971 / 940.663 | 7.23x |
| HARE-256-KR | 7408.683 / 434.687 | 17.04x | 15744.275 / 1803.076 | 8.73x | 23744.744 / 2830.633 | 8.39x |
| HARE-384-KR | 22039.046 / 1108.696 | 19.88x | 46024.219 / 4195.769 | 10.97x | 69066.738 / 6306.306 | 10.95x |
| HARE-512-KR | 58847.053 / 2730.310 | 21.55x | 120361.753 / 8173.983 | 14.72x | 180589.587 / 12167.172 | 14.84x |

## 6. Resource Results

### 6.1 Runtime Resources

| Platform | Maximum benchmark peak RSS | Maximum stack usage |
|---|---:|---:|
| x86 | 7,081,984 bytes | 391,552 bytes, `ref/gf2x.c:vect_mul` |
| ARM/SVE | 6,311,936 bytes | 391,584 bytes, `ref/gf2x.c:vect_mul` |

### 6.2 Static Benchmark Executable Size

The table reports `dec` bytes.

| Platform / build | HARE-128-KR ref | HARE-128-KR opt | HARE-256-KR ref | HARE-256-KR opt | HARE-384-KR ref | HARE-384-KR opt | HARE-512-KR ref | HARE-512-KR opt |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| x86 | 49,555 | 86,391 | 50,579 | 82,819 | 51,011 | 82,379 | 51,923 | 83,371 |
| ARM/SVE PMULL-on | 50,106 | 70,906 | 50,442 | 70,946 | 50,842 | 72,354 | 51,250 | 72,498 |
| ARM/SVE PMULL-off | 50,106 | 70,498 | 50,442 | 70,714 | 50,842 | 72,074 | 51,250 | 72,026 |

## 7. Conclusion

The x86 and ARM/SVE server results show that the active KR line passes the manifest gate, generated-artifact gate, build, CTest, KAT generation/replay, benchmark shared-secret match checks, resource collection, and objdump instruction audits on both platforms, with runner status 0. The x86 run also passes the HARE-256-KR sanitizer subset. The x86 optimized path and the ARM/SVE PMULL-on additional path are substantially faster than the reference path. The ARM/SVE PMULL-off result is retained as fallback/control evidence and is not the primary ARM performance line.
