/*
The software is provided by the Institute of Commercial Cryptography Standards
(ICCS), and is used for algorithm submissions in the Next-generation Commercial
Cryptographic Algorithms Program (NGCC).

ICCS doesn't represent or warrant that the operation of the software will be
uninterrupted or error-free in all cases. ICCS will take no responsibility for
the use of the software or the results thereof, if the software is used for any
other purposes.
*/

#ifndef BLOCKCIPHER_ALGORITHM_INSTANCE_H
#define BLOCKCIPHER_ALGORITHM_INSTANCE_H

// Set "OUTPUT_BLANK_TEST_VECTORS" as 0 to generate test vector files
// Set "OUTPUT_BLANK_TEST_VECTORS" as 1 to generate blank template (default)
#define OUTPUT_BLANK_TEST_VECTORS 1

// Set "ALGORITHM_INSTANCE" as your algorithm instance name (no more than 64 bytes)
// Only letters, numbers, '-' or '_' are permitted
// Example: XXAlgorithm-256-512
#define ALGORITHM_INSTANCE "AlgorithmInstance"

// Set "BLOCK_BIT_LENGTH" as the block bit length of your algorithm instance
#define BLOCK_BIT_LENGTH 256

// Set "BLOCK_BIT_LENGTH" as the key bit length of your algorithm instance
#define KEY_BIT_LENGTH 256

#ifdef __cplusplus
extern "C"
{
#endif

    /// @brief Calculates all the round keys from the key
    /// @param[in] key The base address of cipher key
    /// @param[in] key_len_bytes The total BYTES of key
    /// @param[out] subkey The base address of round keys
    /// @param[out] subkey_len_bytes The total BYTES of subkey
    /// @return 0 for success, others for error
    int KeyExpansion(const unsigned char *key, int key_len_bytes, unsigned char *subkey, int *subkey_len_bytes);

    /// @brief Perform encryption operations on a single data block by the round keys
    /// @param[in] key_len_bytes The total BYTES of cipher key
    /// @param[in] input_block The base address of input data (plaintext usually)
    /// @param[in] subkey The base address of round keys for encryption
    /// @param[in] subkey_len_bytes The total BYTES of subkey
    /// @param[out] output_block The base address of output data (ciphertext usually)
    /// @return 0 for success, others for error
    int EncryptBlock(int key_len_bytes, const unsigned char *input_block, const unsigned char *subkey, int subkey_len_bytes, unsigned char *output_block);

    /// @brief Perform decryption operations on a single data block by the round keys
    /// @param[in] key_len_bytes The total BYTES of cipher key
    /// @param[in] input_block The base address of input data (ciphertext usually)
    /// @param[in] subkey The base address of round keys for decryption
    /// @param[in] subkey_len_bytes The total BYTES of subkey
    /// @param[out] output_block The base address of output data (plaintext usually)
    /// @return 0 for success, others for error
    int DecryptBlock(int key_len_bytes, const unsigned char *input_block, const unsigned char *subkey, int subkey_len_bytes, unsigned char *output_block);

    /// @brief Perform encryption operations on multiple-block by the cipher key in ECB mode
    /// @note It is recommended to call the KeyExpansion() only once within the function.
    /// @param[in] pt The base address of plaintext
    /// @param[in] pt_len_bytes The total BYTES of plaintext
    /// @param[in] key The base address of cipher key
    /// @param[in] key_len_bytes The total BYTES of key
    /// @param[out] ct The base address of ciphertext
    /// @param[out] ct_len_bytes The total BYTES of ciphertext
    /// @return 0 for success, others for error
    int EncryptECB(const unsigned char *pt, unsigned long long pt_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *ct, unsigned long long *ct_len_bytes);

    /// @brief Perform decryption operations on multiple-block by the cipher key in ECB mode
    /// @note It is recommended to call the KeyExpansion() only once within the function.
    /// @param[in] ct The base address of ciphertext
    /// @param[in] ct_len_bytes The total BYTES of ciphertext
    /// @param[in] key The base address of cipher key
    /// @param[in] key_len_bytes The total BYTES of key
    /// @param[out] pt The base address of plaintext
    /// @param[out] pt_len_bytes The total BYTES of plaintext
    /// @return 0 for success, others for error
    int DecryptECB(const unsigned char *ct, unsigned long long ct_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *pt, unsigned long long *pt_len_bytes);

    /// @brief Perform encryption operations on multiple-block by the cipher key in CBC mode
    /// @note It is recommended to call the KeyExpansion() only once within the function.
    /// @param[in] iv The base address of IV
    /// @param[in] iv_len_bytes The total BYTES of IV should be equal to (BLOCK_BIT_LENGTH / 8)
    /// @param[in] pt The base address of plaintext
    /// @param[in] pt_len_bytes The total BYTES of plaintext
    /// @param[in] key The base address of cipher key
    /// @param[in] key_len_bytes The total BYTES of key
    /// @param[out] ct The base address of ciphertext
    /// @param[out] ct_len_bytes The total BYTES of ciphertext
    /// @return 0 for success, others for error
    int EncryptCBC(const unsigned char *iv, int iv_len_bytes, const unsigned char *pt, unsigned long long pt_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *ct, unsigned long long *ct_len_bytes);

    /// @brief Perform decryption operations on multiple-block by the cipher key in CBC mode
    /// @note It is recommended to call the KeyExpansion() only once within the function.
    /// @param[in] iv The base address of IV
    /// @param[in] iv_len_bytes The total BYTES of IV should be equal to (BLOCK_BIT_LENGTH / 8)
    /// @param[in] ct The base address of ciphertext
    /// @param[in] ct_len_bytes The total BYTES of ciphertext
    /// @param[in] key The base address of cipher key
    /// @param[in] key_len_bytes The total BYTES of key
    /// @param[out] pt The base address of plaintext
    /// @param[out] pt_len_bytes The total BYTES of plaintext
    /// @return 0 for success, others for error
    int DecryptCBC(const unsigned char *iv, int iv_len_bytes, const unsigned char *ct, unsigned long long ct_len_bytes, const unsigned char *key, int key_len_bytes, unsigned char *pt, unsigned long long *pt_len_bytes);

#ifdef __cplusplus
}
#endif
#endif