#!/bin/bash 
rm -rf libDragon768s.so 
gcc -Os -march=x86-64 -mavx2   -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Dragon768.c   --shared -o libDragon768s.so  
#cp libHashDragon768s.so ~/HASHFin/ngcc_bench-main/build
