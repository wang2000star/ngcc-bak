/*
The software is provided by the Institute of Commercial Cryptography Standards
(ICCS), and is used for algorithm submissions in the Next-generation Commercial
Cryptographic Algorithms Program (NGCC).

ICCS doesn't represent or warrant that the operation of the software will be
uninterrupted or error-free in all cases. ICCS will take no responsibility for
the use of the software or the results thereof, if the software is used for any
other purposes.
*/

#include "BlockCipher_AlgorithmInstance.h"

int KeyExpansion(const unsigned char *key, int key_len_bytes, unsigned char *subkey, int *subkey_len_bytes)
{
    return 0;
}

int EncryptBlock(int key_len_bytes, const unsigned char *input_block, const unsigned char *subkey, int subkey_len_bytes, unsigned char *output_block)
{
    return 0;
}

int DecryptBlock(int key_len_bytes, const unsigned char *input_block, const unsigned char *subkey, int subkey_len_bytes, unsigned char *output_block)
{
    return 0;
}

int EncryptECB(const unsigned char *pt, unsigned long long pt_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *ct, unsigned long long *ct_len_bytes)
{
    return 0;
}

int DecryptECB(const unsigned char *ct, unsigned long long ct_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *pt, unsigned long long *pt_len_bytes)
{
    return 0;
}

int EncryptCBC(const unsigned char *iv, int iv_len_bytes, const unsigned char *pt, unsigned long long pt_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *ct, unsigned long long *ct_len_bytes)
{
    return 0;
}

int DecryptCBC(const unsigned char *iv, int iv_len_bytes, const unsigned char *ct, unsigned long long ct_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *pt, unsigned long long *pt_len_bytes)
{
    return 0;
}