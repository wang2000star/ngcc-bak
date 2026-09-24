#!/bin/bash 
rm -rf libDragon1024s.so 
gcc -Os -march=x86-64 -mavx2  -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Dragon1024.c   --shared -o libDragon1024s.so  
#cp libHashDragon1024s.so ~/HASHFin/ngcc_bench-main/build
