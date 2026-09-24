#!/bin/bash 
rm -rf libThunder768ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libThunder768ref.so   
