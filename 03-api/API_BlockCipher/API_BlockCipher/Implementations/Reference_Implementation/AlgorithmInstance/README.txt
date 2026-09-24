*********************************Instructions**********************************

The following files SHALL NOT be modified:

drng.c                              Source file of Deterministic Random Number 
                                    Generator

drng.h                              Header file of Deterministic Random Number 
                                    Generator

KAT_BlockCipher.c                   Source file for generating test vector files
                                    of block encryption algorithm

The following files NEED to be modified:

BlockCipher_AlgorithmInstance.c     Source file of block encryption algorithm 
                                    instance (demo)

BlockCipher_AlgorithmInstance.h     Header file of block encryption algorithm 
                                    instance (programming interface)

**************************************Use**************************************

1.  Modify the provided file "BlockCipher_AlgorithmInstance.h":
    a.  Set the macro "OUTPUT_BLANK_TEST_VECTORS" as 0 to set generating mode.
    b.  Set the macro "ALGORITHM_INSTANCE" as the submitted algorithm instance
        name.
    c.  Set the macro "BLOCK_BIT_LENGTH" as the block bit length of your 
        algorithm instance.
    d.  Set the macro "KEY_BIT_LENGTH" as the key bit length of your algorithm 
        instance.

2.  Modify the provided file "BlockCipher_AlgorithmInstance.c" to implement the 
    functions of the submitted algorithm.

3.  Compile and execute to generate test vector files.

*************************************Notes*************************************

1.  The submitted algorithm shall use the provided programming interface in 
    "BlockCipher_AlgorithmInstance.h".
2.  This program assumes a little-endian byte order for multi-byte values. 
    Behavior is undefined on systems with a different byte order.
3.  This program requires compilation with compilers supporting the 
    ISO/IEC 9899:1999 (C99) standard or later.
4.  For non-byte-aligned data operations (e.g., DRNG outputs), the most 
    significant bit (MSB) first convention applies to partial-byte read/write 
    operations.
    Example: the 11-bit non-byte-aligned output "10101100001"(bin) is stored 
    in memory as "AC 20"(hex):
                     MSB     ------->     LSB         
        Address+0  :  1  0  1  0  1  1  0  0  (0xAC)
        Address+1  :  0  0  1  0  0  0  0  0  (0x20, with only 3 valid bits)