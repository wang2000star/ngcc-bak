#!/bin/bash 
rm -rf libThunder512ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libThunder512ref.so   
