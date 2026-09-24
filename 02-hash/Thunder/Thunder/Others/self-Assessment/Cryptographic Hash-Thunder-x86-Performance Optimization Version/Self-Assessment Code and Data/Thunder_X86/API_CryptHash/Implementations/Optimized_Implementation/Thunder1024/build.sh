#!/bin/bash 
rm -rf libThunder1024Opt.so 
gcc -O3 -march=x86-64 -mavx2 -mtune=native  -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder1024.c   --shared -o libThunder1024Opt.so  
 
