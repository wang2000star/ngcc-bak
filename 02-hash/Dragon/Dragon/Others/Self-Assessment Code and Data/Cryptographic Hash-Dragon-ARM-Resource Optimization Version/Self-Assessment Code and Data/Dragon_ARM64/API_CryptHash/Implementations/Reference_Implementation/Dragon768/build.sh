#!/bin/bash 
rm -rf libDragon768ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libDragon768ref.so  
#cp libHashDragon768ref.so ~/HASHFin/ngcc_bench-main/build
