#!/bin/bash 
rm -rf libThunder512Opt.so 
gcc -O3 -march=armv8.2-a+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder512.c   --shared -o libThunder512Opt.so  
#cp libHashDragon512s.so ~/HASHFin/ngcc_bench-main/build
