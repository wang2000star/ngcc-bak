#!/bin/bash 
rm -rf libThunder768Opt.so 
gcc -O3 -march=x86-64 -mavx2 -mtune=native  -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder768.c   --shared -o libThunder768Opt.so  
 
