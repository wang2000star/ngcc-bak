#!/bin/bash 
rm -rf libThunder1024ref.so 
gcc  -std=c99 -Wpedantic -Wall -Wextra -O2 -fPIC CryptHash_AlgorithmInstance.c   --shared -o libThunder1024ref.so   
