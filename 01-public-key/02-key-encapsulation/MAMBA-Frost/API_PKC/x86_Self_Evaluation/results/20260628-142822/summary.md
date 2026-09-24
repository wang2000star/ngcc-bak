# API_PKC x86 self-evaluation summary

* Result directory: `/home/ubuntu/桌面/NGCC/Frost/x86_Self_Evaluation/results/20260628-142822`
* Runs / warmup: `100` / `100`
* Git commit: `37fadadba296f300caed150192c8bcd86d5ba4c0`
* CPU model: unknown
* OS: Ubuntu 22.04.5 LTS
* GCC version: gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0
* AVX2 / AES-NI: yes / yes

## Test status
| item | status |
|---|---|
| Reference build | PASS |
| Reference smoke | PASS |
| Reference KAT | PASS |
| Reference kat-repro | PASS |
| Reference full check | NOT_RUN |
| Optimized build | PASS |
| Optimized smoke | PASS |
| Optimized KAT | PASS |
| Optimized kat-repro | PASS |
| Optimized full check | NOT_RUN |
| Benchmark | PASS |
| Dependency scan | PASS |
| Sizes check | PASS |
| Artifact scan | PASS |

## Sizes table
| implementation | instance | pk_bytes | sk_bytes | ct_bytes | ss_bytes |
|---|---|---|---|---|---|
| Reference | MAMBA-Frost-128 | 5152 | 6736 | 5192 | 16 |
| Reference | MAMBA-Frost-192 | 9712 | 11528 | 9760 | 24 |
| Reference | MAMBA-Frost-256 | 16776 | 19416 | 15552 | 32 |
| Reference | MAMBA-Frost-384 | 25096 | 29032 | 37736 | 48 |
| Reference | MAMBA-Frost-512 | 36432 | 41728 | 72944 | 64 |
| Reference | MAMBA-Frost-CC-128 | 5152 | 6736 | 5192 | 16 |
| Reference | MAMBA-Frost-CC-192 | 9712 | 11528 | 9760 | 24 |
| Reference | MAMBA-Frost-CC-256 | 16776 | 19416 | 15552 | 32 |
| Reference | MAMBA-Frost-CC-384 | 37628 | 43492 | 25204 | 48 |
| Reference | MAMBA-Frost-CC-512 | 72832 | 83328 | 36544 | 64 |
| Optimized | MAMBA-Frost-128 | 5152 | 6736 | 5192 | 16 |
| Optimized | MAMBA-Frost-192 | 9712 | 11528 | 9760 | 24 |
| Optimized | MAMBA-Frost-256 | 16776 | 19416 | 15552 | 32 |
| Optimized | MAMBA-Frost-384 | 25096 | 29032 | 37736 | 48 |
| Optimized | MAMBA-Frost-512 | 36432 | 41728 | 72944 | 64 |
| Optimized | MAMBA-Frost-CC-128 | 5152 | 6736 | 5192 | 16 |
| Optimized | MAMBA-Frost-CC-192 | 9712 | 11528 | 9760 | 24 |
| Optimized | MAMBA-Frost-CC-256 | 16776 | 19416 | 15552 | 32 |
| Optimized | MAMBA-Frost-CC-384 | 37628 | 43492 | 25204 | 48 |
| Optimized | MAMBA-Frost-CC-512 | 72832 | 83328 | 36544 | 64 |

## Benchmark median cycles table
| implementation | instance | operation | median_cycles | ops_per_sec |
|---|---|---|---|---|
| Reference | MAMBA-Frost-128 | kem_keygen | 37424633 | 100.87 |
| Reference | MAMBA-Frost-128 | kem_enc | 38528890 | 97.18 |
| Reference | MAMBA-Frost-128 | kem_dec | 37935343 | 98.58 |
| Reference | MAMBA-Frost-192 | kem_keygen | 104093056 | 36.11 |
| Reference | MAMBA-Frost-192 | kem_enc | 106141212 | 35.46 |
| Reference | MAMBA-Frost-192 | kem_dec | 106790618 | 35.26 |
| Reference | MAMBA-Frost-256 | kem_keygen | 221522683 | 17.12 |
| Reference | MAMBA-Frost-256 | kem_enc | 227578233 | 16.65 |
| Reference | MAMBA-Frost-256 | kem_dec | 228946204 | 16.59 |
| Reference | MAMBA-Frost-384 | kem_keygen | 502378809 | 7.55 |
| Reference | MAMBA-Frost-384 | kem_enc | 550050682 | 6.89 |
| Reference | MAMBA-Frost-384 | kem_dec | 551475270 | 6.88 |
| Reference | MAMBA-Frost-512 | kem_keygen | 916811554 | 4.14 |
| Reference | MAMBA-Frost-512 | kem_enc | 1099076904 | 3.45 |
| Reference | MAMBA-Frost-512 | kem_dec | 1099315920 | 3.44 |
| Reference | MAMBA-Frost-CC-128 | kem_keygen | 35404217 | 105.84 |
| Reference | MAMBA-Frost-CC-128 | kem_enc | 37622988 | 99.89 |
| Reference | MAMBA-Frost-CC-128 | kem_dec | 38173216 | 97.75 |
| Reference | MAMBA-Frost-CC-192 | kem_keygen | 105291930 | 35.49 |
| Reference | MAMBA-Frost-CC-192 | kem_enc | 107180108 | 35.15 |
| Reference | MAMBA-Frost-CC-192 | kem_dec | 107781637 | 34.84 |
| Reference | MAMBA-Frost-CC-256 | kem_keygen | 222748158 | 17.01 |
| Reference | MAMBA-Frost-CC-256 | kem_enc | 228506553 | 16.62 |
| Reference | MAMBA-Frost-CC-256 | kem_dec | 228843987 | 16.52 |
| Reference | MAMBA-Frost-CC-384 | kem_keygen | 516242810 | 7.35 |
| Reference | MAMBA-Frost-CC-384 | kem_enc | 518122629 | 7.33 |
| Reference | MAMBA-Frost-CC-384 | kem_dec | 517927313 | 7.32 |
| Reference | MAMBA-Frost-CC-512 | kem_keygen | 966133731 | 3.92 |
| Reference | MAMBA-Frost-CC-512 | kem_enc | 958927566 | 3.96 |
| Reference | MAMBA-Frost-CC-512 | kem_dec | 961687826 | 3.95 |
| Optimized | MAMBA-Frost-128 | kem_keygen | 935539 | 3883.42 |
| Optimized | MAMBA-Frost-128 | kem_enc | 1305272 | 2747.74 |
| Optimized | MAMBA-Frost-128 | kem_dec | 2107435 | 1985.83 |
| Optimized | MAMBA-Frost-192 | kem_keygen | 2220673 | 1750.64 |
| Optimized | MAMBA-Frost-192 | kem_enc | 2829039 | 1389.12 |
| Optimized | MAMBA-Frost-192 | kem_dec | 3559383 | 1045.11 |
| Optimized | MAMBA-Frost-256 | kem_keygen | 4056032 | 935.33 |
| Optimized | MAMBA-Frost-256 | kem_enc | 5404623 | 713.69 |
| Optimized | MAMBA-Frost-256 | kem_dec | 7157906 | 521.39 |
| Optimized | MAMBA-Frost-384 | kem_keygen | 7474058 | 501.94 |
| Optimized | MAMBA-Frost-384 | kem_enc | 12798884 | 293.76 |
| Optimized | MAMBA-Frost-384 | kem_dec | 15486186 | 244.21 |
| Optimized | MAMBA-Frost-512 | kem_keygen | 13327072 | 285.00 |
| Optimized | MAMBA-Frost-512 | kem_enc | 26749144 | 140.99 |
| Optimized | MAMBA-Frost-512 | kem_dec | 33228383 | 112.39 |
| Optimized | MAMBA-Frost-CC-128 | kem_keygen | 956819 | 3659.57 |
| Optimized | MAMBA-Frost-CC-128 | kem_enc | 1361511 | 2612.45 |
| Optimized | MAMBA-Frost-CC-128 | kem_dec | 2112375 | 1936.12 |
| Optimized | MAMBA-Frost-CC-192 | kem_keygen | 2213073 | 1861.15 |
| Optimized | MAMBA-Frost-CC-192 | kem_enc | 2800540 | 1403.15 |
| Optimized | MAMBA-Frost-CC-192 | kem_dec | 3573062 | 1065.14 |
| Optimized | MAMBA-Frost-CC-256 | kem_keygen | 4432985 | 870.36 |
| Optimized | MAMBA-Frost-CC-256 | kem_enc | 5411083 | 706.90 |
| Optimized | MAMBA-Frost-CC-256 | kem_dec | 7212625 | 518.20 |
| Optimized | MAMBA-Frost-CC-384 | kem_keygen | 11309315 | 336.44 |
| Optimized | MAMBA-Frost-CC-384 | kem_enc | 11222678 | 334.16 |
| Optimized | MAMBA-Frost-CC-384 | kem_dec | 14098076 | 264.75 |
| Optimized | MAMBA-Frost-CC-512 | kem_keygen | 24017003 | 156.70 |
| Optimized | MAMBA-Frost-CC-512 | kem_enc | 21188724 | 177.59 |
| Optimized | MAMBA-Frost-CC-512 | kem_dec | 28379308 | 131.76 |

## Speedup table
| instance | operation | reference_median_cycles | optimized_median_cycles | speedup |
|---|---|---|---|---|
| MAMBA-Frost-128 | kem_dec | 37935343 | 2107435 | 18.00 |
| MAMBA-Frost-128 | kem_enc | 38528890 | 1305272 | 29.52 |
| MAMBA-Frost-128 | kem_keygen | 37424633 | 935539 | 40.00 |
| MAMBA-Frost-192 | kem_dec | 106790618 | 3559383 | 30.00 |
| MAMBA-Frost-192 | kem_enc | 106141212 | 2829039 | 37.52 |
| MAMBA-Frost-192 | kem_keygen | 104093056 | 2220673 | 46.87 |
| MAMBA-Frost-256 | kem_dec | 228946204 | 7157906 | 31.99 |
| MAMBA-Frost-256 | kem_enc | 227578233 | 5404623 | 42.11 |
| MAMBA-Frost-256 | kem_keygen | 221522683 | 4056032 | 54.62 |
| MAMBA-Frost-384 | kem_dec | 551475270 | 15486186 | 35.61 |
| MAMBA-Frost-384 | kem_enc | 550050682 | 12798884 | 42.98 |
| MAMBA-Frost-384 | kem_keygen | 502378809 | 7474058 | 67.22 |
| MAMBA-Frost-512 | kem_dec | 1099315920 | 33228383 | 33.08 |
| MAMBA-Frost-512 | kem_enc | 1099076904 | 26749144 | 41.09 |
| MAMBA-Frost-512 | kem_keygen | 916811554 | 13327072 | 68.79 |
| MAMBA-Frost-CC-128 | kem_dec | 38173216 | 2112375 | 18.07 |
| MAMBA-Frost-CC-128 | kem_enc | 37622988 | 1361511 | 27.63 |
| MAMBA-Frost-CC-128 | kem_keygen | 35404217 | 956819 | 37.00 |
| MAMBA-Frost-CC-192 | kem_dec | 107781637 | 3573062 | 30.17 |
| MAMBA-Frost-CC-192 | kem_enc | 107180108 | 2800540 | 38.27 |
| MAMBA-Frost-CC-192 | kem_keygen | 105291930 | 2213073 | 47.58 |
| MAMBA-Frost-CC-256 | kem_dec | 228843987 | 7212625 | 31.73 |
| MAMBA-Frost-CC-256 | kem_enc | 228506553 | 5411083 | 42.23 |
| MAMBA-Frost-CC-256 | kem_keygen | 222748158 | 4432985 | 50.25 |
| MAMBA-Frost-CC-384 | kem_dec | 517927313 | 14098076 | 36.74 |
| MAMBA-Frost-CC-384 | kem_enc | 518122629 | 11222678 | 46.17 |
| MAMBA-Frost-CC-384 | kem_keygen | 516242810 | 11309315 | 45.65 |
| MAMBA-Frost-CC-512 | kem_dec | 961687826 | 28379308 | 33.89 |
| MAMBA-Frost-CC-512 | kem_enc | 958927566 | 21188724 | 45.26 |
| MAMBA-Frost-CC-512 | kem_keygen | 966133731 | 24017003 | 40.23 |

## Resource table
| implementation | instance | text | data | bss | dec | peak_rss_kb | stack_usage_bytes | status | notes |
|---|---|---|---|---|---|---|---|---|---|
| Reference | MAMBA-Frost-128 | 30760 | 752 | 208 | 31720 | 3104 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-192 | 31136 | 752 | 208 | 32096 | 5180 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-256 | 31216 | 752 | 208 | 32176 | 8668 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-384 | 31456 | 752 | 208 | 32416 | 16928 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-512 | 31680 | 752 | 208 | 32640 | 29124 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-128 | 30760 | 752 | 208 | 31720 | 3032 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-192 | 31136 | 752 | 208 | 32096 | 5176 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-256 | 31216 | 752 | 208 | 32176 | 8664 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-384 | 31504 | 752 | 208 | 32464 | 16856 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-512 | 31728 | 752 | 208 | 32688 | 29192 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-128 | 31370 | 744 | 200 | 32314 | 2048 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-192 | 30986 | 744 | 200 | 31930 | 2176 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-256 | 33594 | 744 | 200 | 34538 | 2304 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-384 | 34834 | 744 | 200 | 35778 | 2688 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-512 | 35842 | 744 | 200 | 36786 | 3072 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-128 | 31406 | 744 | 200 | 32350 | 2048 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-192 | 31022 | 744 | 200 | 31966 | 2176 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-256 | 33630 | 744 | 200 | 34574 | 2304 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-384 | 35494 | 744 | 200 | 36438 | 2560 | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-512 | 36054 | 744 | 200 | 36998 | 2944 | NA | PASS | stack_usage_not_measured |

## Dependency and artifact notes
* Dependency scan treats OpenSSL mentions without forbidden RNG calls as documentation-only; runtime forbidden randomness calls are FAIL.
* DRNG and auxfunc scan logs are retained as `drng_scan.log` and `auxfunc_scan.log`.
* `artifact_scan_after_clean.log` must be empty for PASS.

## Remaining limitations
* Full 1000-round correctness checks are marked NOT_RUN unless `--full-check` was supplied.
* Stack usage is currently not measured and is recorded as NA.
* Results are machine-specific and should be copied into the final LaTeX x86 self-evaluation report by the submitter.
