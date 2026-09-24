#!/bin/bash
# Run from this directory (Data/x86/). Paths are relative to it:
#   executable : ../../ngcc_bench/build/ngcc_bench
#   libraries  : ./*.so   (this folder)
#   KAT vectors: ../../../Test_Vector/Wish512 , ../../../Test_Vector/Wish1024
#   reports    : ../../Reports/x86/*.json
BENCH=../../ngcc_bench/build/ngcc_bench
REPORT=../../Reports/x86
mkdir -p "$REPORT"

rm -f "$REPORT"/*.json.en
rm -f "$REPORT"/*.json.zh

#512
$BENCH   --lib ./Wish512_x86_aes.so        --test hash   --mode all   --digest-len-bits 512   --kat ../../../Test_Vector/Wish512   --json-out "$REPORT"/Wish512_x86_aes_report.json
$BENCH   --lib ./Wish512_x86_aes_mem.so    --test hash   --mode all   --digest-len-bits 512   --kat ../../../Test_Vector/Wish512   --json-out "$REPORT"/Wish512_x86_aes_mem_report.json
$BENCH   --lib ./Wish512_x86_aes_avx2.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../../Test_Vector/Wish512   --json-out "$REPORT"/Wish512_x86_aes_avx2_report.json

#1024
$BENCH   --lib ./Wish1024_x86_aes.so       --test hash   --mode all   --digest-len-bits 1024   --kat ../../../Test_Vector/Wish1024   --json-out "$REPORT"/Wish1024_x86_aes_report.json
$BENCH   --lib ./Wish1024_x86_aes_mem.so   --test hash   --mode all   --digest-len-bits 1024   --kat ../../../Test_Vector/Wish1024   --json-out "$REPORT"/Wish1024_x86_aes_mem_report.json
$BENCH   --lib ./Wish1024_x86_aes_avx2.so  --test hash   --mode all   --digest-len-bits 1024   --kat ../../../Test_Vector/Wish1024   --json-out "$REPORT"/Wish1024_x86_aes_avx2_report.json
