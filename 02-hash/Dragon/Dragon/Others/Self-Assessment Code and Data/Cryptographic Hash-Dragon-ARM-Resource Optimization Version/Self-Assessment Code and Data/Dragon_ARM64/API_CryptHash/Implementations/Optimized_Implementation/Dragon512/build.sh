#!/bin/bash 
rm -rf libDragon512Opt.so 
gcc  -O3 -march=armv8.2-a+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra  -fPIC Dragon512.c   --shared -o libDragon512Opt.so  
#cp libHashDragon512.so ~/HASHFin/ngcc_bench-main/build
