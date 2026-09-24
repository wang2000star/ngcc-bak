#!/bin/sh
set -e
gcc -O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra \
    drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen
echo "built ./katgen"
