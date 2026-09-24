#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

CC=${CC:-gcc}
"$CC" ${CFLAGS:--O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wall -Wextra -Wpedantic} \
  -DWCHAIN_NO_MAIN \
  -I. \
  KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c wchain_c.c \
  -o kat_WChain-V2-1024_opt
