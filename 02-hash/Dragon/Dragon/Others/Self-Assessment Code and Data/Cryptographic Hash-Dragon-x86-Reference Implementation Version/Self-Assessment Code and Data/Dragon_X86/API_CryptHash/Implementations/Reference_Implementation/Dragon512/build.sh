#!/bin/bash 
rm -rf libDragon512ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libDragon512ref.so  
#cp libHashDragon512ref.so ~/HASHFin/ngcc_bench-main/build
