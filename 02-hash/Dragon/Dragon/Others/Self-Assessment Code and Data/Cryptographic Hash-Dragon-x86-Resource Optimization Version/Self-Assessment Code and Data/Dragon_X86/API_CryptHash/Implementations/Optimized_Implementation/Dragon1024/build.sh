#!/bin/bash 
rm -rf libDragon1024Opt.so 
gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Dragon1024.c   --shared -o libDragon1024Opt.so  
#cp libHashDragon1024.so ~/HASHFin/ngcc_bench-main/build
