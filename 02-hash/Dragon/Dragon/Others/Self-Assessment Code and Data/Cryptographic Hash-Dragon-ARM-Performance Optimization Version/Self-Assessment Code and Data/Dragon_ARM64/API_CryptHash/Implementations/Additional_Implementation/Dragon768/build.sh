#!/bin/bash 
rm -rf libDragon768s.so 
gcc  -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra  -fPIC Dragon768.c   --shared -o libDragon768s.so  
#cp libHashDragon768s.so ~/HASHFin/ngcc_bench-main/build
