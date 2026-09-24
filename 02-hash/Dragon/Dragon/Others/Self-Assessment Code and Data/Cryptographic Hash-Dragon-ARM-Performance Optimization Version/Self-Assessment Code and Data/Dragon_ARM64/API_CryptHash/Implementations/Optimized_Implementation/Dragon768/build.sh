#!/bin/bash 
rm -rf libDragon768Opt.so 
gcc  -O3 -march=armv8.2-a+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra  -fPIC Dragon768.c   --shared -o libDragon768Opt.so  
#cp libHashDragon768.so ~/HASHFin/ngcc_bench-main/build
