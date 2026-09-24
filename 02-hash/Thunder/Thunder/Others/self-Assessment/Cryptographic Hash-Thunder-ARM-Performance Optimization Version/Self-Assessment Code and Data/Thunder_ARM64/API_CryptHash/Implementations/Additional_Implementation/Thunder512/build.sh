#!/bin/bash 
rm -rf libThunder512s.so 
gcc -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder512.c   --shared -o libThunder512s.so  
#cp libHashDragon512s.so ~/HASHFin/ngcc_bench-main/build
