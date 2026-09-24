#!/bin/bash 
rm -rf libDragon1024Opt.so 
gcc  -O3 -march=armv8.2-a+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra  -fPIC Dragon1024.c   --shared -o libDragon1024Opt.so  
#cp libHashDragon1024.so ~/HASHFin/ngcc_bench-main/build
