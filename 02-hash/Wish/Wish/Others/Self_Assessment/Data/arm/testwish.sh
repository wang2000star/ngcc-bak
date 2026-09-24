#!/bin/bash
# Run from this directory (Data/arm/). Paths are relative to it:
#   executable : ../../ngcc_bench/build/ngcc_bench
#   libraries  : ./*.so   (this folder)
#   KAT vectors: ../../../Test_Vector/Wish512 , ../../../Test_Vector/Wish1024
#   reports    : ../../Reports/arm/*.json
BENCH=../../ngcc_bench/build/ngcc_bench
REPORT=../../Reports/arm
mkdir -p "$REPORT"

sudo rm -f "$REPORT"/*.json.en
sudo rm -f "$REPORT"/*.json.zh

#512
sudo $BENCH   --lib ./Wish512_arm_aes.so       --test hash   --mode all   --digest-len-bits 512   --kat ../../../Test_Vector/Wish512   --json-out "$REPORT"/Wish512_arm_aes_report.json
sudo $BENCH   --lib ./Wish512_arm_aes_mem.so   --test hash   --mode all   --digest-len-bits 512   --kat ../../../Test_Vector/Wish512   --json-out "$REPORT"/Wish512_arm_aes_mem_report.json

#1024
sudo $BENCH   --lib ./Wish1024_arm_aes.so      --test hash   --mode all   --digest-len-bits 1024   --kat ../../../Test_Vector/Wish1024   --json-out "$REPORT"/Wish1024_arm_aes_report.json
sudo $BENCH   --lib ./Wish1024_arm_aes_mem.so  --test hash   --mode all   --digest-len-bits 1024   --kat ../../../Test_Vector/Wish1024   --json-out "$REPORT"/Wish1024_arm_aes_mem_report.json

sudo chmod 777 "$REPORT"/*.json.* 2>/dev/null
