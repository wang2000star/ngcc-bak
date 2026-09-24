# QSH AArch64 Implementation Self-Assessment (NGCC guideline 1-1)

Material naming (see results/submission/): 密码杂凑-QSH-{512,768,1024}-arm-{参考实现版,性能优化版,资源优化版}

NEON validation: PASSED -- NEON validated on this CPU

## 1. Algorithm basic info
- Category: cryptographic hash;  Name: QuantaSylva Hash (QSH)
- Instances: QSH-512 / QSH-768 / QSH-1024 (digest 512/768/1024 bits)
- Interface: int CryptHash(int digest_len_bits,const unsigned char*msg,unsigned long long msg_len_bits,unsigned char*digest)

## 2. Environment & recordable items
```
date            : Mon Jun 29 15:09:31 UTC 2026
uname           : Linux 6.1.0-49-cloud-arm64 aarch64
os-release      : Debian GNU/Linux 12 (bookworm)
cpu             : 0
cpu impl/part   : 0x41 / 0xd8e
max freq (kHz)  : 
gcc             : gcc (Debian 12.2.0-14+deb12u1) 12.2.0
cmake           : cmake version 3.25.1
governor        : 
perf_paranoid   : 3 (<=2 lets userspace read CPU cycles)
pinned core     : 0
third-party deps: none (only the official ICCS drng.c / KAT_CryptHash.c, unmodified)
RNG method      : DRNG from API_CryptHash (SM3 Hash-DRBG); KAT messages seeded per official harness
ISA / opt       : AArch64; NEON within-permutation SIMD (perf), -Os CV-stack streaming (resource)
```
Compile flags:
- reference  : -std=c99 -Wpedantic -Wall -Wextra -O2
- performance: -O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
- resource   : -O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

## 3. Functional test (KAT)
KAT_2_12 = known-answer over all 4097 message bit-lengths (0..4096), checked
for every version against Test_Vectors/ -- this is also the NEON validation.
The full official KAT (2_12/2_23/2_33/Loop, incl. 1 GiB messages) is run on
the NEON build.
Cross-version byte-identity over multi-chunk inputs (0..300 KB) is also checked.
```
ref KAT_2_12 QSH-512: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
ref KAT_2_12 QSH-768: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
ref KAT_2_12 QSH-1024: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
ref consistency==reference: PASS
opt KAT_2_12 QSH-512: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
opt KAT_2_12 QSH-768: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
opt KAT_2_12 QSH-1024: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
opt consistency==reference: PASS
opt full-KAT QSH-512 KAT_2_12: PASS
opt full-KAT QSH-512 KAT_2_23: PASS
opt full-KAT QSH-512 KAT_2_33: PASS
opt full-KAT QSH-512 KAT_Loop: PASS
opt full-KAT QSH-768 KAT_2_12: PASS
opt full-KAT QSH-768 KAT_2_23: PASS
opt full-KAT QSH-768 KAT_2_33: PASS
opt full-KAT QSH-768 KAT_Loop: PASS
opt full-KAT QSH-1024 KAT_2_12: PASS
opt full-KAT QSH-1024 KAT_2_23: PASS
opt full-KAT QSH-1024 KAT_2_33: PASS
opt full-KAT QSH-1024 KAT_Loop: PASS
res KAT_2_12 QSH-512: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
res KAT_2_12 QSH-768: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
res KAT_2_12 QSH-1024: /home/shichangw879/QSH_run_arm/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
res consistency==reference: PASS
```

## 4. Performance (CPU cycles via perf_event; throughput MB/s). S1..S8 = 32..65536 B, plus r1 at 256K/1M
(cyc_src column: 'perf_event' = measured cycles; 'derived' = time x frequency.)

### version: ref
```
# QSH-512  cyc_src=derived  freq=3.390GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-512,32,9118,92747.3,2898.35,1.2,derived
QSH-512,128,6846,123691.9,966.34,3.5,derived
QSH-512,512,3917,216278.2,422.42,8.0,derived
QSH-512,1024,2494,339648.8,331.69,10.2,derived
QSH-512,4096,704,1202775.4,293.65,11.5,derived
QSH-512,8192,366,2312245.3,282.26,12.0,derived
QSH-512,16384,186,4546292.1,277.48,12.2,derived
QSH-512,65536,100,17867452.2,272.64,12.4,derived
QSH-512,262144,100,71127315.8,271.33,12.5,derived
QSH-512,1048576,100,284060334.5,270.90,12.5,derived
# QSH-768  cyc_src=derived  freq=3.390GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-768,32,4650,181935.7,5685.49,0.6,derived
QSH-768,128,4657,181869.8,1420.86,2.4,derived
QSH-768,512,2794,303197.8,592.18,5.7,derived
QSH-768,1024,1996,424177.8,414.24,8.2,derived
QSH-768,4096,666,1271664.2,310.46,10.9,derived
QSH-768,8192,358,2361675.5,288.29,11.8,derived
QSH-768,16384,186,4542943.5,277.28,12.2,derived
QSH-768,65536,100,17620863.7,268.87,12.6,derived
QSH-768,262144,100,69933885.7,266.78,12.7,derived
QSH-768,1048576,100,279496039.8,266.55,12.7,derived
# QSH-1024  cyc_src=derived  freq=3.387GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-1024,32,4637,182370.6,5699.08,0.6,derived
QSH-1024,128,4643,182120.8,1422.82,2.4,derived
QSH-1024,512,2787,303913.1,593.58,5.7,derived
QSH-1024,1024,1986,424999.5,415.04,8.2,derived
QSH-1024,4096,665,1272932.9,310.77,10.9,derived
QSH-1024,8192,358,2361746.8,288.30,11.7,derived
QSH-1024,16384,186,4549492.3,277.68,12.2,derived
QSH-1024,65536,100,17598065.9,268.53,12.6,derived
QSH-1024,262144,100,70086290.2,267.36,12.7,derived
QSH-1024,1048576,100,279248829.9,266.31,12.7,derived
```

### version: opt
```
# QSH-512  cyc_src=derived  freq=3.389GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-512,32,141330,5881.9,183.81,18.4,derived
QSH-512,128,96166,8710.9,68.05,49.8,derived
QSH-512,512,49038,17181.0,33.56,101.0,derived
QSH-512,1024,29670,28469.2,27.80,121.9,derived
QSH-512,4096,8322,101797.4,24.85,136.3,derived
QSH-512,8192,4287,197508.4,24.11,140.6,derived
QSH-512,16384,2176,389071.3,23.75,142.7,derived
QSH-512,65536,550,1538183.1,23.47,144.4,derived
QSH-512,262144,138,6137253.1,23.41,144.7,derived
QSH-512,1048576,100,24559942.8,23.42,144.7,derived
# QSH-768  cyc_src=derived  freq=3.386GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-768,32,72885,11519.7,359.99,9.4,derived
QSH-768,128,73325,11469.8,89.61,37.8,derived
QSH-768,512,37263,22602.8,44.15,76.7,derived
QSH-768,1024,25100,33606.5,32.82,103.2,derived
QSH-768,4096,8066,104892.2,25.61,132.2,derived
QSH-768,8192,4269,198145.4,24.19,140.0,derived
QSH-768,16384,2200,384877.7,23.49,144.2,derived
QSH-768,65536,562,1506460.7,22.99,147.3,derived
QSH-768,262144,141,5994990.1,22.87,148.1,derived
QSH-768,1048576,100,23920609.8,22.81,148.4,derived
# QSH-1024  cyc_src=derived  freq=3.388GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-1024,32,72662,11578.0,361.81,9.4,derived
QSH-1024,128,73093,11517.0,89.98,37.7,derived
QSH-1024,512,37198,22637.1,44.21,76.6,derived
QSH-1024,1024,25090,33654.9,32.87,103.1,derived
QSH-1024,4096,8061,104920.2,25.62,132.3,derived
QSH-1024,8192,4271,198250.2,24.20,140.0,derived
QSH-1024,16384,2200,384898.1,23.49,144.2,derived
QSH-1024,65536,562,1505730.3,22.98,147.5,derived
QSH-1024,262144,141,5987749.7,22.84,148.3,derived
QSH-1024,1048576,100,23960551.8,22.85,148.3,derived
```

### version: res
```
# QSH-512  cyc_src=derived  freq=3.389GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-512,32,142975,5852.7,182.90,18.5,derived
QSH-512,128,96563,8669.5,67.73,50.0,derived
QSH-512,512,49052,17182.9,33.56,101.0,derived
QSH-512,1024,29687,28458.3,27.79,122.0,derived
QSH-512,4096,8315,101606.8,24.81,136.6,derived
QSH-512,8192,4294,197161.4,24.07,140.8,derived
QSH-512,16384,2179,388769.1,23.73,142.8,derived
QSH-512,65536,551,1540155.6,23.50,144.2,derived
QSH-512,262144,138,6128863.8,23.38,145.0,derived
QSH-512,1048576,100,24497347.2,23.36,145.1,derived
# QSH-768  cyc_src=derived  freq=3.390GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-768,32,73107,11492.5,359.14,9.4,derived
QSH-768,128,73519,11423.6,89.25,38.0,derived
QSH-768,512,37383,22582.7,44.11,76.9,derived
QSH-768,1024,25135,33640.8,32.85,103.2,derived
QSH-768,4096,8044,105299.7,25.71,131.9,derived
QSH-768,8192,4259,198869.7,24.28,139.6,derived
QSH-768,16384,2193,386962.2,23.62,143.5,derived
QSH-768,65536,560,1514023.3,23.10,146.7,derived
QSH-768,262144,140,6011471.0,22.93,147.8,derived
QSH-768,1048576,100,24005333.1,22.89,148.1,derived
# QSH-1024  cyc_src=derived  freq=3.390GHz (self-calibrated)
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps,cyc_src
QSH-1024,32,72725,11551.8,360.99,9.4,derived
QSH-1024,128,73085,11494.6,89.80,37.8,derived
QSH-1024,512,37251,22673.5,44.28,76.6,derived
QSH-1024,1024,25079,33712.2,32.92,103.0,derived
QSH-1024,4096,8059,105036.1,25.64,132.2,derived
QSH-1024,8192,4263,198579.3,24.24,139.9,derived
QSH-1024,16384,2196,385646.1,23.54,144.0,derived
QSH-1024,65536,562,1507478.7,23.00,147.4,derived
QSH-1024,262144,141,5997788.6,22.88,148.2,derived
QSH-1024,1048576,100,23961120.7,22.85,148.4,derived
```

## 5. Resource consumption
static = text+data+bss of the algorithm object; peak RSS via /usr/bin/time -v.
1 MiB x100 = steady working set (>=100 iters); 64 MiB = chaining-value
memory: reference/NEON allocate an O(Pi) flat CV array, the resource build uses
an O(log2 Pi) CV-stack (e.g. 1 GiB -> ~128 MB vs a few KB of CVs).

### version: ref
```
   text	   data	    bss	    dec	    hex	filename
   3700	      0	      0	   3700	    e74	/home/shichangw879/QSH_run_arm/SelfAssessment/results/impl_ref.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2088
peak RSS 64MiB x1: Maximum resident set size (kbytes): 70524
```

### version: opt
```
   text	   data	    bss	    dec	    hex	filename
  11080	      0	      0	  11080	   2b48	/home/shichangw879/QSH_run_arm/SelfAssessment/results/impl_opt.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2044
peak RSS 64MiB x1: Maximum resident set size (kbytes): 68484
```

### version: res
```
   text	   data	    bss	    dec	    hex	filename
  11844	      0	      0	  11844	   2e44	/home/shichangw879/QSH_run_arm/SelfAssessment/results/impl_res.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2000
peak RSS 64MiB x1: Maximum resident set size (kbytes): 66520
```

## 6. Transmission/storage overhead: N/A (hash function)

## 7. Raw-evidence index
- environment: results/environment_arm.txt
- functional : results/functional_arm.txt ; Test_Vectors/
- performance: results/perf_{ref,opt,res}.csv
- resource   : results/static_*.txt , results/peak_*_{small,big}.txt
- build logs : results/warn_*.txt
- named material: results/submission/ (per guideline 1-4)
