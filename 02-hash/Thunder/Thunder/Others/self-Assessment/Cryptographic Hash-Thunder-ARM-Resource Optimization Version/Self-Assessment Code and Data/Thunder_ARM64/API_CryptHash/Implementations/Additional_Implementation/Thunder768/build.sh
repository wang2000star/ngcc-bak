#!/bin/bash 
rm -rf libThunder768s.so 
gcc -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder768.c   --shared -o libThunder768s.so  
#cp libHashDragon768s.so ~/HASHFin/ngcc_bench-main/build
