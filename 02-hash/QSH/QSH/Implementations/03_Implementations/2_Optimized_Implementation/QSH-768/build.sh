#!/bin/sh
set -e
gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer \
    -std=c99 -Wpedantic -Wall -Wextra \
    drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen
echo "built ./katgen"
