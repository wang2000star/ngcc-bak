# API_PKC x86 self-evaluation summary

* Result directory: `x86_Self_Evaluation/results/20260628-132433`
* Runs / warmup: `10` / `2`
* Git commit: `280795f610707bf75060ea56ead1cb47acfcb459`
* CPU model: Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz
* OS: Ubuntu 24.04.4 LTS
* GCC version: gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
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
| Reference | MAMBA-Frost-128 | kem_keygen | 48016058 | 46.11 |
| Reference | MAMBA-Frost-128 | kem_enc | 61825874 | 36.69 |
| Reference | MAMBA-Frost-128 | kem_dec | 66089894 | 34.97 |
| Reference | MAMBA-Frost-192 | kem_keygen | 154248167 | 14.47 |
| Reference | MAMBA-Frost-192 | kem_enc | 171536606 | 13.59 |
| Reference | MAMBA-Frost-192 | kem_dec | 162457653 | 14.18 |
| Reference | MAMBA-Frost-256 | kem_keygen | 321935953 | 7.10 |
| Reference | MAMBA-Frost-256 | kem_enc | 342379418 | 6.76 |
| Reference | MAMBA-Frost-256 | kem_dec | 343881230 | 6.53 |
| Reference | MAMBA-Frost-384 | kem_keygen | 695909644 | 3.29 |
| Reference | MAMBA-Frost-384 | kem_enc | 1093811678 | 2.08 |
| Reference | MAMBA-Frost-384 | kem_dec | 1181436469 | 1.94 |
| Reference | MAMBA-Frost-512 | kem_keygen | 1356211216 | 1.71 |
| Reference | MAMBA-Frost-512 | kem_enc | 6152189364 | 0.37 |
| Reference | MAMBA-Frost-512 | kem_dec | 6572233066 | 0.35 |
| Reference | MAMBA-Frost-CC-128 | kem_keygen | 55765435 | 41.29 |
| Reference | MAMBA-Frost-CC-128 | kem_enc | 63000771 | 36.31 |
| Reference | MAMBA-Frost-CC-128 | kem_dec | 67117575 | 30.34 |
| Reference | MAMBA-Frost-CC-192 | kem_keygen | 151647509 | 14.60 |
| Reference | MAMBA-Frost-CC-192 | kem_enc | 164917271 | 13.31 |
| Reference | MAMBA-Frost-CC-192 | kem_dec | 194987330 | 11.89 |
| Reference | MAMBA-Frost-CC-256 | kem_keygen | 351043514 | 6.53 |
| Reference | MAMBA-Frost-CC-256 | kem_enc | 340856599 | 6.73 |
| Reference | MAMBA-Frost-CC-256 | kem_dec | 349276098 | 6.57 |
| Reference | MAMBA-Frost-CC-384 | kem_keygen | 723820625 | 3.04 |
| Reference | MAMBA-Frost-CC-384 | kem_enc | 1052063963 | 2.12 |
| Reference | MAMBA-Frost-CC-384 | kem_dec | 1055327554 | 2.10 |
| Reference | MAMBA-Frost-CC-512 | kem_keygen | 1469506024 | 1.57 |
| Reference | MAMBA-Frost-CC-512 | kem_enc | 3985078002 | 0.57 |
| Reference | MAMBA-Frost-CC-512 | kem_dec | 3865547152 | 0.57 |
| Optimized | MAMBA-Frost-128 | kem_keygen | 2132945 | 1048.19 |
| Optimized | MAMBA-Frost-128 | kem_enc | 3418378 | 699.28 |
| Optimized | MAMBA-Frost-128 | kem_dec | 3735416 | 624.02 |
| Optimized | MAMBA-Frost-192 | kem_keygen | 4361760 | 515.32 |
| Optimized | MAMBA-Frost-192 | kem_enc | 5372907 | 415.57 |
| Optimized | MAMBA-Frost-192 | kem_dec | 7402547 | 303.83 |
| Optimized | MAMBA-Frost-256 | kem_keygen | 8909438 | 260.19 |
| Optimized | MAMBA-Frost-256 | kem_enc | 11138112 | 207.08 |
| Optimized | MAMBA-Frost-256 | kem_dec | 16897280 | 136.95 |
| Optimized | MAMBA-Frost-384 | kem_keygen | 16979486 | 136.00 |
| Optimized | MAMBA-Frost-384 | kem_enc | 24557054 | 93.33 |
| Optimized | MAMBA-Frost-384 | kem_dec | 30291371 | 74.87 |
| Optimized | MAMBA-Frost-512 | kem_keygen | 43233209 | 50.36 |
| Optimized | MAMBA-Frost-512 | kem_enc | 63008579 | 36.95 |
| Optimized | MAMBA-Frost-512 | kem_dec | 66469430 | 34.37 |
| Optimized | MAMBA-Frost-CC-128 | kem_keygen | 1848893 | 1168.91 |
| Optimized | MAMBA-Frost-CC-128 | kem_enc | 2506014 | 893.17 |
| Optimized | MAMBA-Frost-CC-128 | kem_dec | 3473819 | 655.77 |
| Optimized | MAMBA-Frost-CC-192 | kem_keygen | 5143774 | 450.73 |
| Optimized | MAMBA-Frost-CC-192 | kem_enc | 6676080 | 347.64 |
| Optimized | MAMBA-Frost-CC-192 | kem_dec | 8372584 | 266.43 |
| Optimized | MAMBA-Frost-CC-256 | kem_keygen | 8542864 | 261.96 |
| Optimized | MAMBA-Frost-CC-256 | kem_enc | 10411946 | 220.95 |
| Optimized | MAMBA-Frost-CC-256 | kem_dec | 13764396 | 166.32 |
| Optimized | MAMBA-Frost-CC-384 | kem_keygen | 23226378 | 95.07 |
| Optimized | MAMBA-Frost-CC-384 | kem_enc | 22210232 | 104.42 |
| Optimized | MAMBA-Frost-CC-384 | kem_dec | 29465487 | 76.90 |
| Optimized | MAMBA-Frost-CC-512 | kem_keygen | 53537197 | 44.06 |
| Optimized | MAMBA-Frost-CC-512 | kem_enc | 43614595 | 52.81 |
| Optimized | MAMBA-Frost-CC-512 | kem_dec | 61498173 | 37.06 |

## Speedup table
| instance | operation | reference_median_cycles | optimized_median_cycles | speedup |
|---|---|---|---|---|
| MAMBA-Frost-128 | kem_dec | 66089894 | 3735416 | 17.69 |
| MAMBA-Frost-128 | kem_enc | 61825874 | 3418378 | 18.09 |
| MAMBA-Frost-128 | kem_keygen | 48016058 | 2132945 | 22.51 |
| MAMBA-Frost-192 | kem_dec | 162457653 | 7402547 | 21.95 |
| MAMBA-Frost-192 | kem_enc | 171536606 | 5372907 | 31.93 |
| MAMBA-Frost-192 | kem_keygen | 154248167 | 4361760 | 35.36 |
| MAMBA-Frost-256 | kem_dec | 343881230 | 16897280 | 20.35 |
| MAMBA-Frost-256 | kem_enc | 342379418 | 11138112 | 30.74 |
| MAMBA-Frost-256 | kem_keygen | 321935953 | 8909438 | 36.13 |
| MAMBA-Frost-384 | kem_dec | 1181436469 | 30291371 | 39.00 |
| MAMBA-Frost-384 | kem_enc | 1093811678 | 24557054 | 44.54 |
| MAMBA-Frost-384 | kem_keygen | 695909644 | 16979486 | 40.99 |
| MAMBA-Frost-512 | kem_dec | 6572233066 | 66469430 | 98.88 |
| MAMBA-Frost-512 | kem_enc | 6152189364 | 63008579 | 97.64 |
| MAMBA-Frost-512 | kem_keygen | 1356211216 | 43233209 | 31.37 |
| MAMBA-Frost-CC-128 | kem_dec | 67117575 | 3473819 | 19.32 |
| MAMBA-Frost-CC-128 | kem_enc | 63000771 | 2506014 | 25.14 |
| MAMBA-Frost-CC-128 | kem_keygen | 55765435 | 1848893 | 30.16 |
| MAMBA-Frost-CC-192 | kem_dec | 194987330 | 8372584 | 23.29 |
| MAMBA-Frost-CC-192 | kem_enc | 164917271 | 6676080 | 24.70 |
| MAMBA-Frost-CC-192 | kem_keygen | 151647509 | 5143774 | 29.48 |
| MAMBA-Frost-CC-256 | kem_dec | 349276098 | 13764396 | 25.38 |
| MAMBA-Frost-CC-256 | kem_enc | 340856599 | 10411946 | 32.74 |
| MAMBA-Frost-CC-256 | kem_keygen | 351043514 | 8542864 | 41.09 |
| MAMBA-Frost-CC-384 | kem_dec | 1055327554 | 29465487 | 35.82 |
| MAMBA-Frost-CC-384 | kem_enc | 1052063963 | 22210232 | 47.37 |
| MAMBA-Frost-CC-384 | kem_keygen | 723820625 | 23226378 | 31.16 |
| MAMBA-Frost-CC-512 | kem_dec | 3865547152 | 61498173 | 62.86 |
| MAMBA-Frost-CC-512 | kem_enc | 3985078002 | 43614595 | 91.37 |
| MAMBA-Frost-CC-512 | kem_keygen | 1469506024 | 53537197 | 27.45 |

## Resource table
| implementation | instance | text | data | bss | dec | peak_rss_kb | stack_usage_bytes | status | notes |
|---|---|---|---|---|---|---|---|---|---|
| Reference | MAMBA-Frost-128 | 36007 | 760 | 208 | 36975 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-192 | 36943 | 760 | 208 | 37911 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-256 | 37015 | 760 | 208 | 37983 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-384 | 37279 | 760 | 208 | 38247 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-512 | 37519 | 760 | 208 | 38487 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-128 | 36007 | 760 | 208 | 36975 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-192 | 36943 | 760 | 208 | 37911 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-256 | 37015 | 760 | 208 | 37983 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-384 | 37535 | 760 | 208 | 38503 | NA | NA | PASS | stack_usage_not_measured |
| Reference | MAMBA-Frost-CC-512 | 37647 | 760 | 208 | 38615 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-128 | 30653 | 752 | 200 | 31605 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-192 | 30189 | 752 | 200 | 31141 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-256 | 32645 | 752 | 200 | 33597 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-384 | 33653 | 752 | 200 | 34605 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-512 | 34533 | 752 | 200 | 35485 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-128 | 30683 | 752 | 200 | 31635 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-192 | 30219 | 752 | 200 | 31171 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-256 | 32675 | 752 | 200 | 33627 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-384 | 34339 | 752 | 200 | 35291 | NA | NA | PASS | stack_usage_not_measured |
| Optimized | MAMBA-Frost-CC-512 | 34771 | 752 | 200 | 35723 | NA | NA | PASS | stack_usage_not_measured |

## Dependency and artifact notes
* Dependency scan treats OpenSSL mentions without forbidden RNG calls as documentation-only; runtime forbidden randomness calls are FAIL.
* DRNG and auxfunc scan logs are retained as `drng_scan.log` and `auxfunc_scan.log`.
* `artifact_scan_after_clean.log` must be empty for PASS.

## Remaining limitations
* Full 1000-round correctness checks are marked NOT_RUN unless `--full-check` was supplied.
* Stack usage is currently not measured and is recorded as NA.
* Results are machine-specific and should be copied into the final LaTeX x86 self-evaluation report by the submitter.
