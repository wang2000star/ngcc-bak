#!/bin/bash 
rm -rf libThunder1024s.so 
gcc -Os -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder1024.c   --shared -o libThunder1024s.so  
#cp libHashDragon1024s.so ~/HASHFin/ngcc_bench-main/build
