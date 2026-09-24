#!/bin/bash 
rm -rf libThunder768Opt.so 
gcc -O3 -march=armv8.2-a+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -fPIC Thunder768.c   --shared -o libThunder768Opt.so  
 
