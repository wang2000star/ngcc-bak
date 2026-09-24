#!/bin/bash 
rm -rf libDragon512s.so 
gcc  -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra  -fPIC Dragon512.c   --shared -o libDragon512s.so  
#cp libHashDragon512s.so ~/HASHFin/ngcc_bench-main/build
