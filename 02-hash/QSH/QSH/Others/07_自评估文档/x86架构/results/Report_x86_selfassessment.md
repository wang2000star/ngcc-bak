# QSH x86 Implementation Self-Assessment (NGCC guideline 1-2)

Material naming (see results/submission/): 密码杂凑-QSH-{512,768,1024}-x86-{参考实现版,性能优化版,资源优化版}

## 1. Algorithm basic info
- Category: cryptographic hash;  Name: QuantaSylva Hash (QSH)
- Instances: QSH-512 / QSH-768 / QSH-1024 (digest 512/768/1024 bits)
- Interface: int CryptHash(int digest_len_bits,const unsigned char*msg,unsigned long long msg_len_bits,unsigned char*digest)

## 2. Environment & recordable items
```
date            : Mon Jun 29 15:08:39 UTC 2026
uname           : Linux 6.12.90+deb13.1-cloud-amd64 x86_64
os-release      : Debian GNU/Linux 13 (trixie)
cpu             : Intel(R) Xeon(R) CPU @ 2.80GHz
cpu-MHz(cur)    : 2799.998
gcc             : gcc (Debian 14.2.0-19) 14.2.0
cmake           : cmake version 3.31.6
governor        : 
no_turbo        : 
pinned core     : 0
third-party deps: none (only the official ICCS drng.c / KAT_CryptHash.c, unmodified)
RNG method      : DRNG from API_CryptHash (SM3 Hash-DRBG); KAT messages seeded per official harness
ISA / opt       : x86-64 + AVX2; within-permutation SIMD (perf), SIMD core + O(log Pi) CV-stack at -O3 (resource)
```
Compile flags:
- reference  : -std=c99 -Wpedantic -Wall -Wextra -O2
- performance: -O3 -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
- resource   : -O3 -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

## 3. Functional test (KAT)
KAT_2_12 = known-answer over all 4097 message bit-lengths (0..4096, every
padding/sub-byte edge case), checked for every version against Test_Vectors/.
The full official KAT (2_12/2_23/2_33/Loop, incl. 1 GiB messages) is run on
the optimized build.
Cross-version byte-identity over multi-chunk inputs (0..300 KB) covers the
tree/streaming paths for the reference and resource builds.
```
ref KAT_2_12 QSH-512: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
ref KAT_2_12 QSH-768: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
ref KAT_2_12 QSH-1024: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
ref consistency==reference: PASS
opt KAT_2_12 QSH-512: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
opt KAT_2_12 QSH-768: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
opt KAT_2_12 QSH-1024: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
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
res KAT_2_12 QSH-512: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-512.txt: matched 4097/4097 [PASS]
res KAT_2_12 QSH-768: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-768.txt: matched 4097/4097 [PASS]
res KAT_2_12 QSH-1024: /home/shichangw879/QSH_run/Test_Vectors/KAT_2_12_QSH-1024.txt: matched 4097/4097 [PASS]
res consistency==reference: PASS
```

## 4. Performance (cycles via rdtsc/TSC; throughput MB/s). S1..S8 = 32..65536 B, plus r1 at 256K/1M

### version: ref
```
# QSH-512  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-512,32,7824,86272.5,2696.01,1.0
QSH-512,128,6093,115157.2,899.67,3.1
QSH-512,512,3488,200880.8,392.35,7.1
QSH-512,1024,2215,317123.3,309.69,9.0
QSH-512,4096,627,1116953.2,272.69,10.3
QSH-512,8192,326,2143543.1,261.66,10.7
QSH-512,16384,166,4199908.9,256.34,10.9
QSH-512,65536,100,16509823.2,251.92,11.1
QSH-512,262144,100,65941571.0,251.55,11.1
QSH-512,1048576,100,263234477.9,251.04,11.2
# QSH-768  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-768,32,4124,168981.1,5280.66,0.5
QSH-768,128,4152,169005.3,1320.35,2.1
QSH-768,512,2491,281327.4,549.47,5.1
QSH-768,1024,1735,395177.5,385.92,7.3
QSH-768,4096,593,1179607.0,287.99,9.7
QSH-768,8192,319,2191381.6,267.50,10.5
QSH-768,16384,166,4218027.8,257.45,10.9
QSH-768,65536,100,16323805.1,249.08,11.2
QSH-768,262144,100,64913358.1,247.62,11.3
QSH-768,1048576,100,258960244.9,246.96,11.3
# QSH-1024  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-1024,32,4108,168794.9,5274.84,0.5
QSH-1024,128,4171,167413.4,1307.92,2.1
QSH-1024,512,2505,279270.6,545.45,5.1
QSH-1024,1024,1788,391129.3,381.96,7.3
QSH-1024,4096,596,1169812.0,285.60,9.8
QSH-1024,8192,322,2172069.1,265.15,10.6
QSH-1024,16384,167,4205401.4,256.68,10.9
QSH-1024,65536,100,16207017.2,247.30,11.3
QSH-1024,262144,100,64237782.5,245.05,11.4
QSH-1024,1048576,100,256764036.0,244.87,11.4
```

### version: opt
```
# QSH-512  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-512,32,296490,2303.9,72.00,38.9
QSH-512,128,205705,3343.1,26.12,107.2
QSH-512,512,107827,6445.2,12.59,222.4
QSH-512,1024,65887,10562.3,10.31,271.5
QSH-512,4096,18820,37151.9,9.07,308.7
QSH-512,8192,9715,71964.4,8.78,318.7
QSH-512,16384,4938,141565.4,8.64,324.1
QSH-512,65536,1250,559342.6,8.53,328.1
QSH-512,262144,313,2231773.5,8.51,328.9
QSH-512,1048576,100,8931363.1,8.52,328.7
# QSH-768  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-768,32,112101,6190.3,193.45,14.5
QSH-768,128,112878,6148.0,48.03,58.3
QSH-768,512,57656,12065.5,23.57,118.8
QSH-768,1024,38868,17912.7,17.49,160.1
QSH-768,4096,12532,56083.7,13.69,204.5
QSH-768,8192,6636,105416.0,12.87,217.6
QSH-768,16384,3405,204834.4,12.50,224.0
QSH-768,65536,869,799987.9,12.21,229.4
QSH-768,262144,220,3191828.8,12.18,230.0
QSH-768,1048576,100,12700045.0,12.11,231.2
# QSH-1024  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-1024,32,110599,6218.4,194.33,14.4
QSH-1024,128,112337,6176.9,48.26,58.0
QSH-1024,512,57646,12082.8,23.60,118.6
QSH-1024,1024,38896,17948.1,17.53,159.7
QSH-1024,4096,12530,55869.0,13.64,205.3
QSH-1024,8192,6644,105576.2,12.89,217.3
QSH-1024,16384,3376,205022.2,12.51,223.8
QSH-1024,65536,876,800052.8,12.21,229.4
QSH-1024,262144,220,3179081.5,12.13,230.9
QSH-1024,1048576,100,12714643.6,12.13,230.9
```

### version: res
```
# QSH-512  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-512,32,296154,2308.6,72.14,38.8
QSH-512,128,205556,3361.6,26.26,106.6
QSH-512,512,107819,6477.1,12.65,221.3
QSH-512,1024,65627,10576.7,10.33,271.1
QSH-512,4096,18801,37159.0,9.07,308.6
QSH-512,8192,9710,72164.0,8.81,317.8
QSH-512,16384,4924,142022.9,8.67,323.0
QSH-512,65536,1249,559736.1,8.54,327.8
QSH-512,262144,313,2235948.8,8.53,328.3
QSH-512,1048576,100,8931688.7,8.52,328.7
# QSH-768  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-768,32,111565,6228.8,194.65,14.4
QSH-768,128,110777,6173.8,48.23,58.1
QSH-768,512,57561,12075.6,23.59,118.7
QSH-768,1024,38796,17928.5,17.51,159.9
QSH-768,4096,12524,56034.8,13.68,204.7
QSH-768,8192,6618,105404.4,12.87,217.6
QSH-768,16384,3419,204564.6,12.49,224.3
QSH-768,65536,874,801223.4,12.23,229.0
QSH-768,262144,219,3187709.8,12.16,230.3
QSH-768,1048576,100,12728407.5,12.14,230.7
# QSH-1024  TSC_GHz=2.7999
variant,size_bytes,iters,avg_cycles,cyc_per_byte,throughput_MBps
QSH-1024,32,107855,6238.6,194.96,14.4
QSH-1024,128,111894,6197.0,48.41,57.8
QSH-1024,512,57437,12123.7,23.68,118.2
QSH-1024,1024,38813,18037.9,17.62,159.0
QSH-1024,4096,12507,55865.8,13.64,205.3
QSH-1024,8192,6621,105389.8,12.86,217.6
QSH-1024,16384,3360,204980.1,12.51,223.8
QSH-1024,65536,875,800327.4,12.21,229.3
QSH-1024,262144,220,3184039.1,12.15,230.5
QSH-1024,1048576,100,12728388.6,12.14,230.7
```

## 5. Resource consumption
static = text+data+bss of the algorithm object; peak RSS measured with
/usr/bin/time -v.  The 1 MiB x100 figure is the steady working set (>=100
iterations); the 64 MiB figure exposes chaining-value memory:
reference/optimized allocate an O(Pi) flat CV array (~Pi*256 B), the resource
build uses an O(log2 Pi) CV-stack (e.g. 1 GiB -> ~128 MB vs a few KB of CVs).

### version: ref
```
   text	   data	    bss	    dec	    hex	filename
   4369	      0	      0	   4369	   1111	/home/shichangw879/QSH_run/SelfAssessment/results/impl_ref.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2352
peak RSS 64MiB x1: Maximum resident set size (kbytes): 70956
```

### version: opt
```
   text	   data	    bss	    dec	    hex	filename
  15524	      0	      0	  15524	   3ca4	/home/shichangw879/QSH_run/SelfAssessment/results/impl_opt.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2352
peak RSS 64MiB x1: Maximum resident set size (kbytes): 66892
```

### version: res
```
   text	   data	    bss	    dec	    hex	filename
  15524	      0	      0	  15524	   3ca4	/home/shichangw879/QSH_run/SelfAssessment/results/impl_res.o
peak RSS 1MiB x100 : Maximum resident set size (kbytes): 2312
peak RSS 64MiB x1: Maximum resident set size (kbytes): 66820
```

## 6. Transmission/storage overhead: N/A (hash function)

## 7. Raw-evidence index
- environment: results/environment.txt
- functional : results/functional.txt ; Test_Vectors/ (KAT_2_12/2_23/2_33/Loop x QSH-512/768/1024)
- performance: results/perf_{ref,opt,res}.csv
- resource   : results/static_*.txt , results/peak_*_{small,big}.txt
- build logs : results/warn_*.txt
- named material: results/submission/ (per guideline 1-4)
