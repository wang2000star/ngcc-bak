# Iphe-768 Reference Implementation

- Instance: `Iphe-768`
- Digest length: 768 bits
- State: 2048 bits
- Rate: 1216 bits, 19 words
- Capacity: 832 bits, 13 words

This directory is the C99 reference implementation. It is written for clarity and correctness, without performance optimization, resource optimization, SIMD, AVX2, inline assembly, or x86-specific instructions.

Build:

```sh
gcc -std=c99 -Wpedantic -Wall -Wextra -O2 CryptHash_AlgorithmInstance.c -c -o CryptHash_AlgorithmInstance.o
```

Generate KAT:

```sh
gcc -std=c99 -Wpedantic -Wall -Wextra -O2 KAT_CryptHash.c CryptHash_AlgorithmInstance.c drng.c -o KAT_CryptHash
./KAT_CryptHash
```

Run selftest:

```sh
gcc -std=c99 -Wpedantic -Wall -Wextra -O2 iphe_selftest.c CryptHash_AlgorithmInstance.c -o iphe_selftest
./iphe_selftest
```
