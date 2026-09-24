# API_PKC x86 self-evaluation summary

* Result directory: `/home/ubuntu/桌面/NGCC/Frost/x86_Self_Evaluation/results/20260628-150128`
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
| Reference full check | PASS |
| Optimized build | PASS |
| Optimized smoke | PASS |
| Optimized KAT | PASS |
| Optimized kat-repro | PASS |
| Optimized full check | PASS |
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
| Reference | MAMBA-Frost-128 | kem_keygen | 37269977 | 100.08 |
| Reference | MAMBA-Frost-128 | kem_enc | 40203893 | 93.90 |
| Reference | MAMBA-Frost-128 | kem_dec | 39020599 | 94.55 |
| Reference | MAMBA-Frost-192 | kem_keygen | 106904615 | 35.18 |
| Reference | MAMBA-Frost-192 | kem_enc | 124595134 | 30.42 |
| Reference | MAMBA-Frost-192 | kem_dec | 110709473 | 34.10 |
| Reference | MAMBA-Frost-256 | kem_keygen | 229887064 | 16.48 |
| Reference | MAMBA-Frost-256 | kem_enc | 234669261 | 16.14 |
| Reference | MAMBA-Frost-256 | kem_dec | 235625700 | 16.03 |
| Reference | MAMBA-Frost-384 | kem_keygen | 515014676 | 7.36 |
| Reference | MAMBA-Frost-384 | kem_enc | 560492856 | 6.77 |
| Reference | MAMBA-Frost-384 | kem_dec | 562001044 | 6.76 |
| Reference | MAMBA-Frost-512 | kem_keygen | 932776910 | 4.07 |
| Reference | MAMBA-Frost-512 | kem_enc | 1111745831 | 3.42 |
| Reference | MAMBA-Frost-512 | kem_dec | 1112164202 | 3.41 |
| Reference | MAMBA-Frost-CC-128 | kem_keygen | 36088203 | 103.66 |
| Reference | MAMBA-Frost-CC-128 | kem_enc | 39578427 | 94.68 |
| Reference | MAMBA-Frost-CC-128 | kem_dec | 44560879 | 84.45 |
| Reference | MAMBA-Frost-CC-192 | kem_keygen | 106905375 | 35.22 |
| Reference | MAMBA-Frost-CC-192 | kem_enc | 107737178 | 34.66 |
| Reference | MAMBA-Frost-CC-192 | kem_dec | 110467799 | 34.29 |
| Reference | MAMBA-Frost-CC-256 | kem_keygen | 228306298 | 16.63 |
| Reference | MAMBA-Frost-CC-256 | kem_enc | 234792378 | 16.13 |
| Reference | MAMBA-Frost-CC-256 | kem_dec | 235609360 | 16.09 |
| Reference | MAMBA-Frost-CC-384 | kem_keygen | 528168093 | 7.18 |
| Reference | MAMBA-Frost-CC-384 | kem_enc | 528999895 | 7.17 |
| Reference | MAMBA-Frost-CC-384 | kem_dec | 528756320 | 7.19 |
| Reference | MAMBA-Frost-CC-512 | kem_keygen | 985683548 | 3.85 |
| Reference | MAMBA-Frost-CC-512 | kem_enc | 976593765 | 3.88 |
| Reference | MAMBA-Frost-CC-512 | kem_dec | 989676503 | 3.83 |
| Optimized | MAMBA-Frost-128 | kem_keygen | 966319 | 3707.11 |
| Optimized | MAMBA-Frost-128 | kem_enc | 1560246 | 2516.83 |
| Optimized | MAMBA-Frost-128 | kem_dec | 2103635 | 1915.79 |
| Optimized | MAMBA-Frost-192 | kem_keygen | 2262091 | 1768.17 |
| Optimized | MAMBA-Frost-192 | kem_enc | 2909597 | 1351.76 |
| Optimized | MAMBA-Frost-192 | kem_dec | 3873637 | 975.54 |
| Optimized | MAMBA-Frost-256 | kem_keygen | 4045773 | 916.11 |
| Optimized | MAMBA-Frost-256 | kem_enc | 5613239 | 672.93 |
| Optimized | MAMBA-Frost-256 | kem_dec | 7390080 | 503.19 |
| Optimized | MAMBA-Frost-384 | kem_keygen | 7887110 | 468.08 |
| Optimized | MAMBA-Frost-384 | kem_enc | 13554688 | 279.43 |
| Optimized | MAMBA-Frost-384 | kem_dec | 16465045 | 227.37 |
| Optimized | MAMBA-Frost-512 | kem_keygen | 13740124 | 267.46 |
| Optimized | MAMBA-Frost-512 | kem_enc | 27943837 | 134.46 |
| Optimized | MAMBA-Frost-512 | kem_dec | 34348219 | 109.71 |
| Optimized | MAMBA-Frost-CC-128 | kem_keygen | 927940 | 3754.99 |
| Optimized | MAMBA-Frost-CC-128 | kem_enc | 1564807 | 2540.92 |
| Optimized | MAMBA-Frost-CC-128 | kem_dec | 2104775 | 1915.78 |
| Optimized | MAMBA-Frost-CC-192 | kem_keygen | 2228652 | 1722.91 |
| Optimized | MAMBA-Frost-CC-192 | kem_enc | 2830940 | 1394.46 |
| Optimized | MAMBA-Frost-CC-192 | kem_dec | 3597763 | 1043.96 |
| Optimized | MAMBA-Frost-CC-256 | kem_keygen | 4049193 | 935.25 |
| Optimized | MAMBA-Frost-CC-256 | kem_enc | 5493542 | 698.90 |
| Optimized | MAMBA-Frost-CC-256 | kem_dec | 7216805 | 505.64 |
| Optimized | MAMBA-Frost-CC-384 | kem_keygen | 10904625 | 336.80 |
| Optimized | MAMBA-Frost-CC-384 | kem_enc | 11365555 | 326.03 |
| Optimized | MAMBA-Frost-CC-384 | kem_dec | 14634245 | 255.71 |
| Optimized | MAMBA-Frost-CC-512 | kem_keygen | 23841446 | 156.39 |
| Optimized | MAMBA-Frost-CC-512 | kem_enc | 21446738 | 174.56 |
| Optimized | MAMBA-Frost-CC-512 | kem_dec | 28721300 | 131.35 |

## Speedup table
| instance | operation | reference_median_cycles | optimized_median_cycles | speedup |
|---|---|---|---|---|
| MAMBA-Frost-128 | kem_dec | 39020599 | 2103635 | 18.55 |
| MAMBA-Frost-128 | kem_enc | 40203893 | 1560246 | 25.77 |
| MAMBA-Frost-128 | kem_keygen | 37269977 | 966319 | 38.57 |
| MAMBA-Frost-192 | kem_dec | 110709473 | 3873637 | 28.58 |
| MAMBA-Frost-192 | kem_enc | 124595134 | 2909597 | 42.82 |
| MAMBA-Frost-192 | kem_keygen | 106904615 | 2262091 | 47.26 |
| MAMBA-Frost-256 | kem_dec | 235625700 | 7390080 | 31.88 |
| MAMBA-Frost-256 | kem_enc | 234669261 | 5613239 | 41.81 |
| MAMBA-Frost-256 | kem_keygen | 229887064 | 4045773 | 56.82 |
| MAMBA-Frost-384 | kem_dec | 562001044 | 16465045 | 34.13 |
| MAMBA-Frost-384 | kem_enc | 560492856 | 13554688 | 41.35 |
| MAMBA-Frost-384 | kem_keygen | 515014676 | 7887110 | 65.30 |
| MAMBA-Frost-512 | kem_dec | 1112164202 | 34348219 | 32.38 |
| MAMBA-Frost-512 | kem_enc | 1111745831 | 27943837 | 39.79 |
| MAMBA-Frost-512 | kem_keygen | 932776910 | 13740124 | 67.89 |
| MAMBA-Frost-CC-128 | kem_dec | 44560879 | 2104775 | 21.17 |
| MAMBA-Frost-CC-128 | kem_enc | 39578427 | 1564807 | 25.29 |
| MAMBA-Frost-CC-128 | kem_keygen | 36088203 | 927940 | 38.89 |
| MAMBA-Frost-CC-192 | kem_dec | 110467799 | 3597763 | 30.70 |
| MAMBA-Frost-CC-192 | kem_enc | 107737178 | 2830940 | 38.06 |
| MAMBA-Frost-CC-192 | kem_keygen | 106905375 | 2228652 | 47.97 |
| MAMBA-Frost-CC-256 | kem_dec | 235609360 | 7216805 | 32.65 |
| MAMBA-Frost-CC-256 | kem_enc | 234792378 | 5493542 | 42.74 |
| MAMBA-Frost-CC-256 | kem_keygen | 228306298 | 4049193 | 56.38 |
| MAMBA-Frost-CC-384 | kem_dec | 528756320 | 14634245 | 36.13 |
| MAMBA-Frost-CC-384 | kem_enc | 528999895 | 11365555 | 46.54 |
| MAMBA-Frost-CC-384 | kem_keygen | 528168093 | 10904625 | 48.44 |
| MAMBA-Frost-CC-512 | kem_dec | 989676503 | 28721300 | 34.46 |
| MAMBA-Frost-CC-512 | kem_enc | 976593765 | 21446738 | 45.54 |
| MAMBA-Frost-CC-512 | kem_keygen | 985683548 | 23841446 | 41.34 |

## Resource table
| implementation | instance | text | data | bss | dec | peak_rss_kb | stack_usage_bytes | status | notes |
|---|---|---|---|---|---|---|---|---|---|
| Reference | MAMBA-Frost-128 | 30760 | 752 | 208 | 31720 | 3104 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-192 | 31136 | 752 | 208 | 32096 | 5184 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-256 | 31216 | 752 | 208 | 32176 | 8668 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-384 | 31456 | 752 | 208 | 32416 | 17036 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-512 | 31680 | 752 | 208 | 32640 | 29248 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-128 | 30760 | 752 | 208 | 31720 | 3104 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-192 | 31136 | 752 | 208 | 32096 | 5184 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-256 | 31216 | 752 | 208 | 32176 | 8668 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-384 | 31504 | 752 | 208 | 32464 | 16980 | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-512 | 31728 | 752 | 208 | 32688 | 29196 | NA | PASS | stack_usage_not_measured |
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
