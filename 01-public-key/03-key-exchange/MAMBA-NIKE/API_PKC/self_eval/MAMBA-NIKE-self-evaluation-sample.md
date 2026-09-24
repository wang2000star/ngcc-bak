# MAMBA-NIKE x86 Self-Evaluation Results

**Overall status:** PASS

## Environment

- Timestamp (UTC): `2026-06-30T14:42:47.061864+00:00`
- Mode: `quick`
- Platform: `Linux-4.4.0-x86_64-with-glibc2.41`
- Compiler: `x86_64-linux-gnu-gcc-14 (Debian 14.2.0-19) 14.2.0`
- Python: `3.13.5`
- AVX2 available: `True`
- ASan/UBSan available: `True`
- parameters.json SHA-256: `a34156a3dcc6c80328e5bf8814d7c1aa4764dd1ac8e257c455000e124194ffdd`

## Profiles

| Profile | n | (eta_s, eta_r; t_pk, t_u, t_v) | pk | sk_API | M1 | ss |
|---|---:|---|---:|---:|---:|---:|
| MAMBA-NIKE-128 | 1024 | (2, 2; 9, 10, 6) | 1184 | 3232 | 1568 | 32 |
| MAMBA-NIKE-192 | 1024 | (3, 3; 10, 10, 6) | 1312 | 3360 | 1568 | 32 |
| MAMBA-NIKE-256 | 1024 | (7, 7; 10, 10, 6) | 1312 | 3360 | 1568 | 32 |
| MAMBA-NIKE-384 | 2048 | (2, 2; 11, 11, 6) | 2848 | 6944 | 3360 | 48 |
| MAMBA-NIKE-512 | 2048 | (5, 5; 11, 11, 6) | 2848 | 6944 | 3360 | 64 |

## Test Results

| Test | Status | Required | Time (s) | Details |
|---|---|:---:|---:|---|
| Dependencies | PASS | yes | 0.007 | compiler=x86_64-linux-gnu-gcc-14 (Debian 14.2.0-19) 14.2.0; make=/usr/bin/make; bash=/usr/bin/bash; AVX2=True; ASan/UBSan=True; NumPy=installed |
| x86-only package layout | PASS | yes | 0.001 | only the Reference and Optimized x86 tracks are present with all five profiles |
| Frozen parameter alignment | PASS | yes | 0.001 | parameters.json and 10 submitted headers are aligned |
| Reference implementation boundary | PASS | yes | 0.012 | Reference is portable coefficient-domain C and uses Toom-Cook-4 only |
| Optimized implementation boundary | PASS | yes | 0.001 | Optimized profiles contain AVX2 small-CBD multiplication and portable Toom fallback |
| Canonical KAT manifest integrity | PASS | yes | 0.003 | 15 canonical KAT files match their recorded sizes and SHA-256 digests |
| Security-estimator record alignment | PASS | yes | 0.001 | recorded MATZOV classical/quantum values match the code-aligned report |
| Quick clean-build smoke test | PASS | yes | 6.746 | 3 clean profile builds completed across 3 implementation modes |
| Quick NGCC API smoke test | PASS | yes | 5.550 | 3 NGCC API normal/negative test executions passed |
| Protected-file immutability | PASS | yes | 0.005 | 27 protected files remained byte-for-byte unchanged |

## Interpretation

A PASS means every required test completed successfully within the selected mode. A SKIP is used only for optional host capabilities such as AVX2, sanitizers, or NumPy. The runner does not claim a finite rejection bound when the repository tool reports `TBD(double_floor)`.
