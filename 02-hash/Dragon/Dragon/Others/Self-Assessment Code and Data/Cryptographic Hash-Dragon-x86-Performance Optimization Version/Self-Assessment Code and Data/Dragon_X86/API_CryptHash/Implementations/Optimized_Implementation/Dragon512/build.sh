#!/bin/bash 
rm -rf libDragon512Opt.so 
gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Dragon512.c   --shared -o libDragon512Opt.so  
#cp libHashDragon512.so ~/HASHFin/ngcc_bench-main/build
