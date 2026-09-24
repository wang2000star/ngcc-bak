#!/bin/bash 
rm -rf libDragon1024ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libDragon1024ref.so  
#cp libHashDragon1024ref.so ~/HASHFin/ngcc_bench-main/build
