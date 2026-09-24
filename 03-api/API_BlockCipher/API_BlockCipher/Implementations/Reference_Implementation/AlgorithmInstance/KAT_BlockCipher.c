/*
The software is provided by the Institute of Commercial Cryptography Standards
(ICCS), and is used for algorithm submissions in the Next-generation Commercial
Cryptographic Algorithms Program (NGCC).

ICCS doesn't represent or warrant that the operation of the software will be
uninterrupted or error-free in all cases. ICCS will take no responsibility for
the use of the software or the results thereof, if the software is used for any
other purposes.
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <ctype.h>
#include <errno.h>
#if defined(_WIN32)
#include <direct.h>
#include <io.h>
#else
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#endif
#include "drng.h"
#include "BlockCipher_AlgorithmInstance.h"

#define SEED_LEN_BYTES 64
#define SUBKEY_LEN_BYTES_MAX (1024 * 1024) // The maximum length of the subkey is 2^20 bytes (1 MB)

#define KAT_SUCCESS 0
#define KAT_FILE_OPERATE_FAILED -1
#define KAT_MEMORY_ALLOCATION_FAILED -2
#define KAT_KEY_EXPANSION_FAILED -3
#define KAT_CRYPTBLOCK_ENC_FAILED -4
#define KAT_CRYPTBLOCK_DEC_FAILED -5
#define KAT_ALGORITHM_INSTANCE_NAME_INVALID -6
#define KAT_DECRYPTION_CORRECTNESS_VERIFY_FAILED -7
#define KAT_BYTE_MULTIPLE_VERIFY_FAILED -8

static int validate_algorithm_instance_name(const char *algorithm_instance_name);
static int create_directory(const char *path);
static int progress_bar(int total, const char *test_name);
static void fprint_normal(FILE *fp, const char *data_name, const unsigned char *data, unsigned long long data_len_bytes);

/// @brief Test API KeyExpansion(), EncryptBlock(), DecryptBlock()
static int gen_KAT_DifKey(const char *algorithm_instance_name, int block_len_bits, int key_len_bits);
/// @brief Test API KeyExpansion(), EncryptBlock(), DecryptBlock()
static int gen_KAT_DifMsg(const char *algorithm_instance_name, int block_len_bits, int key_len_bits);
/// @brief Test API EncryptECB(), DecryptECB()
static int gen_KAT_ECB(const char *algorithm_instance_name, int block_len_bits, int key_len_bits);
/// @brief Test API EncryptCBC(), DecryptCBC()
static int gen_KAT_CBC(const char *algorithm_instance_name, int block_len_bits, int key_len_bits);
/// @brief Test API KeyExpansion(), EncryptBlock(), DecryptBlock()
static int gen_KAT_Loop(const char *algorithm_instance_name, int block_len_bits, int key_len_bits);

int main()
{
    clock_t start_time, end_time;
    double time_elapsed;
    int rt = KAT_SUCCESS;
    start_time = clock();

    if (validate_algorithm_instance_name(ALGORITHM_INSTANCE))
    {
        fprintf(stderr, "ERROR: Invalid algorithm instance name. Only letters, numbers, '-' or '_' are permitted.\n");
        rt = KAT_ALGORITHM_INSTANCE_NAME_INVALID;
        goto end;
    }

    // Generate the ciphertext for variable key
    progress_bar(5, "KAT_DifKey");
    rt = gen_KAT_DifKey(ALGORITHM_INSTANCE, BLOCK_BIT_LENGTH, KEY_BIT_LENGTH);
    if (KAT_SUCCESS != rt)
    {
        goto end;
    }

    // Generate the ciphertext for variable message
    progress_bar(5, "KAT_DifMsg");
    rt = gen_KAT_DifMsg(ALGORITHM_INSTANCE, BLOCK_BIT_LENGTH, KEY_BIT_LENGTH);
    if (KAT_SUCCESS != rt)
    {
        goto end;
    }

    // Generate the ciphertext for ECB mode
    progress_bar(5, "KAT_ECB");
    rt = gen_KAT_ECB(ALGORITHM_INSTANCE, BLOCK_BIT_LENGTH, KEY_BIT_LENGTH);
    if (KAT_SUCCESS != rt)
    {
        goto end;
    }

    // Generate the ciphertext for CBC mode
    progress_bar(5, "KAT_CBC");
    rt = gen_KAT_CBC(ALGORITHM_INSTANCE, BLOCK_BIT_LENGTH, KEY_BIT_LENGTH);
    if (KAT_SUCCESS != rt)
    {
        goto end;
    }

    // Generate the ciphertext by running Loop Test
    //***********************Loop Test***********************//
    // a. pt_0_0 = 0;
    // b. Loop i \in [0:10,000) Step 1
    //        key_i = get_random_number()
    //        subkey_i = KeyExpansion(key_i)
    //        Loop j \in [0:10,000) Step 1
    //                ct_i_j = EncryptBlock(pt_i_j,subkey_i);
    //                pt_i_(j+1) = ct_i_j
    //        pt_(i+1)_0 = ct_i_9999
    // c. Output ct_9999_9999
    //*******************************************************//
    progress_bar(5, "KAT_Loop");
    rt = gen_KAT_Loop(ALGORITHM_INSTANCE, BLOCK_BIT_LENGTH, KEY_BIT_LENGTH);
    if (KAT_SUCCESS != rt)
    {
        goto end;
    }

    end_time = clock();
    time_elapsed = (double)(end_time - start_time) / CLOCKS_PER_SEC;
    progress_bar(5, "");
    printf("\nFiles have been saved in the 'output' folder within the working directory.");
    printf("\nTotal duration: %.0lf s\n", time_elapsed);
end:
    return rt;
}

static int validate_algorithm_instance_name(const char *algorithm_instance_name)
{
    int rt = EXIT_SUCCESS;
    const int MAX_LENGTH = 64;
    char c = '\0';

    if (strlen(algorithm_instance_name) > MAX_LENGTH)
    {
        rt = KAT_ALGORITHM_INSTANCE_NAME_INVALID;
        goto end;
    }

    for (int i = 0; algorithm_instance_name[i] != '\0'; i++)
    {
        c = algorithm_instance_name[i];
        if (!(isalnum(c) || '-' == c || '_' == c))
        {
            rt = KAT_ALGORITHM_INSTANCE_NAME_INVALID;
            break;
        }
    }
end:
    return rt;
}

static int create_directory(const char *path)
{
#if defined(_WIN32)
    if (0 == _mkdir(path))
        return EXIT_SUCCESS;
#else
    if (0 == mkdir(path, 0755))
        return EXIT_SUCCESS;
#endif

    if (errno == EEXIST)
    {
#if defined(_WIN32)
        if (0 == _access(path, 0))
            return EXIT_SUCCESS;
#else
        if (0 == access(path, F_OK))
            return EXIT_SUCCESS;
#endif
    }

    return EXIT_FAILURE;
}

static int progress_bar(int total, const char *test_name)
{
    static int number = 0;
    if (total <= 0 || number > total)
        return EXIT_FAILURE;
    const int rate = number * 100 / total;
    static char ProgressBar[50 + 1];

    memset(ProgressBar, 0, sizeof(ProgressBar));
    memset(ProgressBar, '#', rate / 2);
    printf("[%-50s] [%3d%%]  ", ProgressBar, rate);
    if (number <= (total - 1))
    {
        printf("Doing:\"%s\"   \r", test_name);
    }
    else
    {
        printf("SUCCESS!           \r");
    }
    number++;
    fflush(stdout);
    return EXIT_SUCCESS;
}

static void fprint_normal(FILE *fp, const char *data_name, const unsigned char *data, unsigned long long data_len_bytes)
{
    fprintf(fp, "%s_Len = %llu\n", data_name, data_len_bytes);
    fprintf(fp, "%s = ", data_name);
    if (NULL != data)
    {
        for (unsigned long long i = 0ULL; i < data_len_bytes; i++)
        {
            fprintf(fp, "%02X", data[i]);
        }
    }
    fprintf(fp, "\n");
}

static int gen_KAT_DifKey(const char *algorithm_instance_name, int block_len_bits, int key_len_bits)
{
    unsigned char *input_block, *input_block_decrypted, *key, *output_block, *subkey;
    int *subkey_len_bytes;
    char filename[96] = "KAT_DifKey_";
    const char *dir_name = "output";
    char file_path[128] = "";
    int rt = KAT_SUCCESS;
    FILE *fp = NULL;

    if ((0 != block_len_bits % 8) || (0 != key_len_bits % 8))
    {
        fprintf(stderr, "\nERROR: The bit length of block/key should be integer multiple of 8. \n");
        rt = KAT_BYTE_MULTIPLE_VERIFY_FAILED;
        goto end;
    }
    strcat(filename, algorithm_instance_name);
    strcat(filename, ".txt");
    sprintf(file_path, "%s/%s", dir_name, filename);
    if (0 != create_directory(dir_name))
    {
        fprintf(stderr, "\nERROR: Generate folder \"%s\" failed at %s, line %d. \n", dir_name, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
    fp = fopen(file_path, "wb");
    if (NULL == fp)
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }

    input_block = (unsigned char *)malloc(block_len_bits / 8);
    input_block_decrypted = (unsigned char *)malloc(block_len_bits / 8);
    key = (unsigned char *)malloc(key_len_bits / 8);
    output_block = (unsigned char *)malloc(block_len_bits / 8);
    subkey = (unsigned char *)malloc(SUBKEY_LEN_BYTES_MAX);
    subkey_len_bytes = (int *)malloc(sizeof(int));
    if (NULL == input_block || NULL == input_block_decrypted || NULL == key || NULL == output_block || NULL == subkey || NULL == subkey_len_bytes)
    {
        fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
        rt = KAT_MEMORY_ALLOCATION_FAILED;
        goto cleanup;
    }
    *subkey_len_bytes = SUBKEY_LEN_BYTES_MAX;
    memset(input_block, 0, block_len_bits / 8);
    memset(input_block_decrypted, 0, block_len_bits / 8);
    memset(key, 0, key_len_bits / 8);
    memset(output_block, 0, block_len_bits / 8);
    memset(subkey, 0, *subkey_len_bytes);

    for (int i = 0; i < key_len_bits; i++)
    {
        memset(subkey, 0, *subkey_len_bytes);
        fprint_normal(fp, "Input_Block", input_block, block_len_bits / 8);
        memset(key, 0, key_len_bits / 8);
        key[i / 8] = 1 << (7 - (i % 8));
        fprint_normal(fp, "Key", key, key_len_bits / 8);
        if (KeyExpansion(key, key_len_bits / 8, subkey, subkey_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_KEY_EXPANSION_FAILED;
            goto cleanup;
        }
        if (EncryptBlock(key_len_bits / 8, input_block, subkey, *subkey_len_bytes, output_block))
        {
            fprintf(stderr, "\nERROR: \"EncryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_ENC_FAILED;
            goto cleanup;
        }
        else
        {
            fprint_normal(fp, "Output_Block", OUTPUT_BLANK_TEST_VECTORS ? NULL : output_block, block_len_bits / 8);
        }
        fprintf(fp, "\n");

#if OUTPUT_BLANK_TEST_VECTORS == 0
        memset(subkey, 0, *subkey_len_bytes);
        if (KeyExpansion(key, key_len_bits / 8, subkey, subkey_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_KEY_EXPANSION_FAILED;
            goto cleanup;
        }
        if (DecryptBlock(key_len_bits / 8, output_block, subkey, *subkey_len_bytes, input_block_decrypted))
        {
            fprintf(stderr, "\nERROR: \"DecryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_DEC_FAILED;
            goto cleanup;
        }
        else
        {
            if (memcmp(input_block, input_block_decrypted, block_len_bits / 8))
            {
                fprintf(stderr, "\nERROR: Correctness verification failed when generating \"%s\"\n", filename);
                rt = KAT_DECRYPTION_CORRECTNESS_VERIFY_FAILED;
                goto cleanup;
            }
        }
#endif
    }
cleanup:
    free(subkey_len_bytes);
    free(subkey);
    free(output_block);
    free(key);
    free(input_block_decrypted);
    free(input_block);
    if (0 != fclose(fp))
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
end:
    return rt;
}

static int gen_KAT_DifMsg(const char *algorithm_instance_name, int block_len_bits, int key_len_bits)
{
    unsigned char *input_block, *input_block_decrypted, *key, *output_block, *subkey_enc, *subkey_dec;
    int *subkey_len_bytes;
    char filename[96] = "KAT_DifMsg_";
    const char *dir_name = "output";
    char file_path[128] = "";
    int rt = KAT_SUCCESS;
    FILE *fp = NULL;

    if ((0 != block_len_bits % 8) || (0 != key_len_bits % 8))
    {
        fprintf(stderr, "\nERROR: The bit length of block/key should be integer multiple of 8. \n");
        rt = KAT_BYTE_MULTIPLE_VERIFY_FAILED;
        goto end;
    }
    strcat(filename, algorithm_instance_name);
    strcat(filename, ".txt");
    sprintf(file_path, "%s/%s", dir_name, filename);
    if (0 != create_directory(dir_name))
    {
        fprintf(stderr, "\nERROR: Generate folder \"%s\" failed at %s, line %d. \n", dir_name, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
    fp = fopen(file_path, "wb");
    if (NULL == fp)
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }

    input_block = (unsigned char *)malloc(block_len_bits / 8);
    input_block_decrypted = (unsigned char *)malloc(block_len_bits / 8);
    key = (unsigned char *)malloc(key_len_bits / 8);
    output_block = (unsigned char *)malloc(block_len_bits / 8);
    subkey_enc = (unsigned char *)malloc(SUBKEY_LEN_BYTES_MAX);
    subkey_dec = (unsigned char *)malloc(SUBKEY_LEN_BYTES_MAX);
    subkey_len_bytes = (int *)malloc(sizeof(int));
    if (NULL == input_block || NULL == input_block_decrypted || NULL == key || NULL == output_block || NULL == subkey_enc || NULL == subkey_dec || NULL == subkey_len_bytes)
    {
        fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
        rt = KAT_MEMORY_ALLOCATION_FAILED;
        goto cleanup;
    }
    *subkey_len_bytes = SUBKEY_LEN_BYTES_MAX;
    memset(input_block, 0, block_len_bits / 8);
    memset(input_block_decrypted, 0, block_len_bits / 8);
    memset(key, 0, key_len_bits / 8);
    memset(output_block, 0, block_len_bits / 8);
    memset(subkey_enc, 0, *subkey_len_bytes);
    memset(subkey_dec, 0, *subkey_len_bytes);

    if (KeyExpansion(key, key_len_bits / 8, subkey_enc, subkey_len_bytes))
    {
        fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_KEY_EXPANSION_FAILED;
        goto cleanup;
    }

#if OUTPUT_BLANK_TEST_VECTORS == 0
    if (KeyExpansion(key, key_len_bits / 8, subkey_dec, subkey_len_bytes))
    {
        fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_KEY_EXPANSION_FAILED;
        goto cleanup;
    }
#endif

    for (int i = 0; i < block_len_bits; i++)
    {
        memset(input_block, 0, block_len_bits / 8);
        input_block[i / 8] = 1 << (7 - (i % 8));
        fprint_normal(fp, "Input_Block", input_block, block_len_bits / 8);
        fprint_normal(fp, "Key", key, key_len_bits / 8);
        if (EncryptBlock(key_len_bits / 8, input_block, subkey_enc, *subkey_len_bytes, output_block))
        {
            fprintf(stderr, "\nERROR: \"EncryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_ENC_FAILED;
            goto cleanup;
        }
        else
        {
            fprint_normal(fp, "Output_Block", OUTPUT_BLANK_TEST_VECTORS ? NULL : output_block, block_len_bits / 8);
        }
        fprintf(fp, "\n");

#if OUTPUT_BLANK_TEST_VECTORS == 0
        if (DecryptBlock(key_len_bits / 8, output_block, subkey_dec, *subkey_len_bytes, input_block_decrypted))
        {
            fprintf(stderr, "\nERROR: \"DecryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_DEC_FAILED;
            goto cleanup;
        }
        else
        {
            if (memcmp(input_block, input_block_decrypted, block_len_bits / 8))
            {
                fprintf(stderr, "\nERROR: Correctness verification failed when generating \"%s\" \n", filename);
                rt = KAT_DECRYPTION_CORRECTNESS_VERIFY_FAILED;
                goto cleanup;
            }
        }
#endif
    }
cleanup:
    free(subkey_len_bytes);
    free(subkey_dec);
    free(subkey_enc);
    free(output_block);
    free(key);
    free(input_block_decrypted);
    free(input_block);
    if (0 != fclose(fp))
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
end:
    return rt;
}

static int gen_KAT_ECB(const char *algorithm_instance_name, int block_len_bits, int key_len_bits)
{
    unsigned char *pt, *pt_decrypted, *key, *ct;
    unsigned long long *output_len_bytes;
    unsigned long long pt_len_bytes, ct_len_bytes;
    char filename[96] = "KAT_ECB_";
    const char *dir_name = "output";
    char file_path[128] = "";
    int rt = KAT_SUCCESS;
    FILE *fp = NULL;
    DRNG_ctx drng_ecb;
    unsigned char seed[SEED_LEN_BYTES];

    if ((0 != block_len_bits % 8) || (0 != key_len_bits % 8))
    {
        fprintf(stderr, "\nERROR: The bit length of block/key should be integer multiple of 8. \n");
        rt = KAT_BYTE_MULTIPLE_VERIFY_FAILED;
        goto end;
    }
    strcat(filename, algorithm_instance_name);
    strcat(filename, ".txt");
    sprintf(file_path, "%s/%s", dir_name, filename);
    if (0 != create_directory(dir_name))
    {
        fprintf(stderr, "\nERROR: Generate folder \"%s\" failed at %s, line %d. \n", dir_name, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
    fp = fopen(file_path, "wb");
    if (NULL == fp)
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }

    // "KAT_ECB_" repeats 8 times as seed
    for (unsigned long long i = 0; i < sizeof(seed) / 8; i++)
    {
        memcpy(seed + 8 * i, filename, 8);
    }
    pt_len_bytes = 256;
    pt = (unsigned char *)malloc(pt_len_bytes);
    pt_decrypted = (unsigned char *)malloc(pt_len_bytes);
    key = (unsigned char *)malloc(key_len_bits / 8);
    ct_len_bytes = pt_len_bytes;
    ct = (unsigned char *)malloc(ct_len_bytes);
    output_len_bytes = (unsigned long long *)malloc(sizeof(unsigned long long));
    if (NULL == pt || NULL == pt_decrypted || NULL == key || NULL == ct || NULL == output_len_bytes)
    {
        fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
        rt = KAT_MEMORY_ALLOCATION_FAILED;
        goto cleanup;
    }

    for (int i = 0; i < 3; i++)
    {
        memset(pt, 0, pt_len_bytes);
        memset(pt_decrypted, 0, pt_len_bytes);
        memset(key, 0, key_len_bits / 8);
        memset(ct, 0, ct_len_bytes);
        *output_len_bytes = 0;
        init_random_number(&drng_ecb, seed, sizeof(seed));
        switch (i)
        {
        case 0: // 0 for plaintext , random key
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            get_random_number(&drng_ecb, key, key_len_bits);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        case 1: // 0 for key , random plaintext
            get_random_number(&drng_ecb, pt, pt_len_bytes * 8);
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        case 2: // random plaintext, random key
            get_random_number(&drng_ecb, pt, pt_len_bytes * 8);
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            get_random_number(&drng_ecb, key, key_len_bits);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        }

        if (EncryptECB(pt, pt_len_bytes, key, key_len_bits / 8, ct, output_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"EncryptECB()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_ENC_FAILED;
            goto cleanup;
        }
        else
        {
            if ((*output_len_bytes != ct_len_bytes) && !OUTPUT_BLANK_TEST_VECTORS)
            {
                fprintf(stderr, "\nERROR: \"EncryptECB()\" actual output length is [%llu] bytes ,which is not equal to the expected ciphertext length [%llu] bytes, when generating \"%s\" at %s, line %d. \n", *output_len_bytes, ct_len_bytes, filename, __FILE__, __LINE__);
                rt = KAT_CRYPTBLOCK_ENC_FAILED;
                goto cleanup;
            }
            fprint_normal(fp, "Ct", OUTPUT_BLANK_TEST_VECTORS ? NULL : ct, ct_len_bytes);
        }
        fprintf(fp, "\n");

#if OUTPUT_BLANK_TEST_VECTORS == 0
        if (DecryptECB(ct, ct_len_bytes, key, key_len_bits / 8, pt_decrypted, output_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"DecryptECB()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_DEC_FAILED;
            goto cleanup;
        }
        else
        {
            if ((*output_len_bytes != pt_len_bytes))
            {
                fprintf(stderr, "\nERROR: \"DecryptECB()\" actual output length is [%llu] bytes ,which is not equal to the expected decrypted plaintext length [%llu] bytes, when generating \"%s\" at %s, line %d. \n", *output_len_bytes, pt_len_bytes, filename, __FILE__, __LINE__);
                rt = KAT_CRYPTBLOCK_DEC_FAILED;
                goto cleanup;
            }
            if (memcmp(pt, pt_decrypted, pt_len_bytes) != 0)
            {
                fprintf(stderr, "\nERROR: Correctness verification failed when generating \"%s\" \n", filename);
                rt = KAT_DECRYPTION_CORRECTNESS_VERIFY_FAILED;
                goto cleanup;
            }
        }
#endif
    }
cleanup:
    free(output_len_bytes);
    free(ct);
    free(key);
    free(pt_decrypted);
    free(pt);
    if (0 != fclose(fp))
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
end:
    return rt;
}

static int gen_KAT_CBC(const char *algorithm_instance_name, int block_len_bits, int key_len_bits)
{
    unsigned char *iv, *pt, *pt_decrypted, *key, *ct;
    unsigned long long *output_len_bytes;
    int iv_len_bytes;
    unsigned long long pt_len_bytes, ct_len_bytes;
    char filename[96] = "KAT_CBC_";
    const char *dir_name = "output";
    char file_path[128] = "";
    int rt = KAT_SUCCESS;
    FILE *fp = NULL;
    DRNG_ctx drng_cbc;
    unsigned char seed[SEED_LEN_BYTES];

    if ((0 != block_len_bits % 8) || (0 != key_len_bits % 8))
    {
        fprintf(stderr, "\nERROR: The bit length of block/key should be integer multiple of 8. \n");
        rt = KAT_BYTE_MULTIPLE_VERIFY_FAILED;
        goto end;
    }
    strcat(filename, algorithm_instance_name);
    strcat(filename, ".txt");
    sprintf(file_path, "%s/%s", dir_name, filename);
    if (0 != create_directory(dir_name))
    {
        fprintf(stderr, "\nERROR: Generate folder \"%s\" failed at %s, line %d. \n", dir_name, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
    fp = fopen(file_path, "wb");
    if (NULL == fp)
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }

    // "KAT_CBC_" repeats 8 times as seed
    for (unsigned long long i = 0; i < sizeof(seed) / 8; i++)
    {
        memcpy(seed + 8 * i, filename, 8);
    }
    iv_len_bytes = block_len_bits / 8;
    iv = (unsigned char *)malloc(iv_len_bytes);
    pt_len_bytes = 256;
    pt = (unsigned char *)malloc(pt_len_bytes);
    pt_decrypted = (unsigned char *)malloc(pt_len_bytes);
    key = (unsigned char *)malloc(key_len_bits / 8);
    ct_len_bytes = pt_len_bytes;
    ct = (unsigned char *)malloc(ct_len_bytes);
    output_len_bytes = (unsigned long long *)malloc(sizeof(unsigned long long));
    if (NULL == iv || NULL == pt || NULL == pt_decrypted || NULL == key || NULL == ct || NULL == output_len_bytes)
    {
        fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
        rt = KAT_MEMORY_ALLOCATION_FAILED;
        goto cleanup;
    }

    for (int i = 0; i < 3; i++)
    {
        memset(iv, 0, iv_len_bytes);
        memset(pt, 0, pt_len_bytes);
        memset(pt_decrypted, 0, pt_len_bytes);
        memset(key, 0, key_len_bits / 8);
        memset(ct, 0, ct_len_bytes);
        *output_len_bytes = 0;
        init_random_number(&drng_cbc, seed, sizeof(seed));
        switch (i)
        {
        case 0: // 0 for plaintext , random key,iv
            get_random_number(&drng_cbc, iv, iv_len_bytes * 8);
            fprint_normal(fp, "IV", iv, iv_len_bytes);
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            get_random_number(&drng_cbc, key, key_len_bits);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        case 1: // 0 for key , random plaintext,iv
            get_random_number(&drng_cbc, iv, iv_len_bytes * 8);
            fprint_normal(fp, "IV", iv, iv_len_bytes);
            get_random_number(&drng_cbc, pt, pt_len_bytes * 8);
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        case 2: // 0 for iv , random plaintext,key
            fprint_normal(fp, "IV", iv, iv_len_bytes);
            get_random_number(&drng_cbc, pt, pt_len_bytes * 8);
            fprint_normal(fp, "Pt", pt, pt_len_bytes);
            get_random_number(&drng_cbc, key, key_len_bits);
            fprint_normal(fp, "Key", key, key_len_bits / 8);
            break;
        }

        if (EncryptCBC(iv, iv_len_bytes, pt, pt_len_bytes, key, key_len_bits / 8, ct, output_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"EncryptCBC()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_ENC_FAILED;
            goto cleanup;
        }
        else
        {
            if ((*output_len_bytes != ct_len_bytes) && !OUTPUT_BLANK_TEST_VECTORS)
            {
                fprintf(stderr, "\nERROR: \"EncryptCBC()\" actual output length is [%llu] bytes ,which is not equal to the expected ciphertext length [%llu] bytes, when generating \"%s\" at %s, line %d. \n", *output_len_bytes, ct_len_bytes, filename, __FILE__, __LINE__);
                rt = KAT_CRYPTBLOCK_ENC_FAILED;
                goto cleanup;
            }
            fprint_normal(fp, "Ct", OUTPUT_BLANK_TEST_VECTORS ? NULL : ct, ct_len_bytes);
        }
        fprintf(fp, "\n");

#if OUTPUT_BLANK_TEST_VECTORS == 0
        if (DecryptCBC(iv, iv_len_bytes, ct, ct_len_bytes, key, key_len_bits / 8, pt_decrypted, output_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"DecryptCBC()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            rt = KAT_CRYPTBLOCK_DEC_FAILED;
            goto cleanup;
        }
        else
        {
            if ((*output_len_bytes != pt_len_bytes))
            {
                fprintf(stderr, "\nERROR: \"DecryptCBC()\" actual output length is [%llu] bytes ,which is not equal to the expected decrypted plaintext length [%llu] bytes, when generating \"%s\" at %s, line %d. \n", *output_len_bytes, pt_len_bytes, filename, __FILE__, __LINE__);
                rt = KAT_CRYPTBLOCK_DEC_FAILED;
                goto cleanup;
            }
            if (memcmp(pt, pt_decrypted, pt_len_bytes) != 0)
            {
                fprintf(stderr, "\nERROR: Correctness verification failed when generating \"%s\" \n", filename);
                rt = KAT_DECRYPTION_CORRECTNESS_VERIFY_FAILED;
                goto cleanup;
            }
        }
#endif
    }
cleanup:
    free(output_len_bytes);
    free(ct);
    free(key);
    free(pt_decrypted);
    free(pt);
    free(iv);
    if (0 != fclose(fp))
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
end:
    return rt;
}

static int gen_KAT_Loop(const char *algorithm_instance_name, int block_len_bits, int key_len_bits)
{
    unsigned char *input_block, *input_block_decrypted, **key, *output_block, *subkey;
    int *subkey_len_bytes;
    char filename[96] = "KAT_Loop_";
    const char *dir_name = "output";
    char file_path[128] = "";
    int rt = KAT_SUCCESS;
    FILE *fp = NULL;
    DRNG_ctx drng_loop;
    unsigned char seed[SEED_LEN_BYTES];
    const int key_update_times = 10000;
    const int single_key_encrypt_times = 10000;

    if ((0 != block_len_bits % 8) || (0 != key_len_bits % 8))
    {
        fprintf(stderr, "\nERROR: The bit length of block/key should be integer multiple of 8. \n");
        rt = KAT_BYTE_MULTIPLE_VERIFY_FAILED;
        goto end;
    }
    strcat(filename, algorithm_instance_name);
    strcat(filename, ".txt");
    sprintf(file_path, "%s/%s", dir_name, filename);
    if (0 != create_directory(dir_name))
    {
        fprintf(stderr, "\nERROR: Generate folder \"%s\" failed at %s, line %d. \n", dir_name, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
    fp = fopen(file_path, "wb");
    if (NULL == fp)
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }

    // "KAT_Loop" repeats 8 times as seed
    for (unsigned long long i = 0; i < sizeof(seed) / 8; i++)
    {
        memcpy(seed + 8 * i, filename, 8);
    }
    input_block = (unsigned char *)malloc(block_len_bits / 8);
    input_block_decrypted = (unsigned char *)malloc(block_len_bits / 8);
    key = (unsigned char **)malloc(sizeof(unsigned char *) * key_update_times);
    output_block = (unsigned char *)malloc(block_len_bits / 8);
    subkey = (unsigned char *)malloc(SUBKEY_LEN_BYTES_MAX);
    subkey_len_bytes = (int *)malloc(sizeof(int));

    init_random_number(&drng_loop, seed, sizeof(seed));
    for (int i = 0; i < key_update_times; i++)
    {
        key[i] = (unsigned char *)malloc(key_len_bits / 8);
        if (NULL == key[i])
        {
            fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
            for (int j = 0; j < i; j++)
            {
                free(key[j]);
            }
            rt = KAT_MEMORY_ALLOCATION_FAILED;
            goto cleanup;
        }
        get_random_number(&drng_loop, key[i], key_len_bits);
    }

    if (NULL == input_block || NULL == input_block_decrypted || NULL == key || NULL == output_block || NULL == subkey || NULL == subkey_len_bytes)
    {
        fprintf(stderr, "\nERROR: Memory allocation failed at %s, line %d. \n", __FILE__, __LINE__);
        for (int i = 0; i < key_update_times; i++)
        {
            free(key[i]);
        }
        rt = KAT_MEMORY_ALLOCATION_FAILED;
        goto cleanup;
    }

    *subkey_len_bytes = SUBKEY_LEN_BYTES_MAX;
    memset(input_block, 0, block_len_bits / 8);
    memset(input_block_decrypted, 0, block_len_bits / 8);
    memset(output_block, 0, block_len_bits / 8);
    memset(subkey, 0, *subkey_len_bytes);

    fprint_normal(fp, "Pt", input_block, block_len_bits / 8);
    for (int i = 0; i < key_update_times; i++)
    {
        if (!i)
        {
            fprint_normal(fp, "Key", key[i], key_len_bits / 8);
        }
        if (KeyExpansion(key[i], key_len_bits / 8, subkey, subkey_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            for (int j = 0; j < key_update_times; j++)
            {
                free(key[j]);
            }
            rt = KAT_KEY_EXPANSION_FAILED;
            goto cleanup;
        }
        for (int j = 0; j < single_key_encrypt_times; j++)
        {
            if (EncryptBlock(key_len_bits / 8, input_block, subkey, *subkey_len_bytes, output_block))
            {
                fprintf(stderr, "\nERROR: \"EncryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
                for (int k = 0; k < key_update_times; k++)
                {
                    free(key[k]);
                }
                rt = KAT_CRYPTBLOCK_ENC_FAILED;
                goto cleanup;
            }
            memcpy(input_block, output_block, block_len_bits / 8);
        }
    }
    fprint_normal(fp, "Ct", OUTPUT_BLANK_TEST_VECTORS ? NULL : output_block, block_len_bits / 8);
    fprintf(fp, "\n");

#if OUTPUT_BLANK_TEST_VECTORS == 0
    memset(subkey, 0, *subkey_len_bytes);
    for (int i = 0; i < key_update_times; i++)
    {
        if (KeyExpansion(key[i], key_len_bits / 8, subkey, subkey_len_bytes))
        {
            fprintf(stderr, "\nERROR: \"KeyExpansion()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
            for (int j = 0; j < key_update_times; j++)
            {
                free(key[j]);
            }
            rt = KAT_KEY_EXPANSION_FAILED;
            goto cleanup;
        }
        for (int j = 0; j < single_key_encrypt_times; j++)
        {
            if (DecryptBlock(key_len_bits / 8, output_block, subkey, *subkey_len_bytes, input_block_decrypted))
            {
                fprintf(stderr, "\nERROR: \"EncryptBlock()\" returns a non-zero value when generating \"%s\" at %s, line %d. \n", filename, __FILE__, __LINE__);
                for (int k = 0; k < key_update_times; k++)
                {
                    free(key[k]);
                }
                rt = KAT_CRYPTBLOCK_ENC_FAILED;
                goto cleanup;
            }
            memcpy(output_block, input_block_decrypted, block_len_bits / 8);
        }
    }
#endif

    for (int i = 0; i < key_update_times; i++)
    {
        free(key[i]);
    }
cleanup:
    free(subkey_len_bytes);
    free(subkey);
    free(output_block);
    free(key);
    free(input_block_decrypted);
    free(input_block);
    if (0 != fclose(fp))
    {
        fprintf(stderr, "\nERROR: Generate \"%s\" failed at %s, line %d. \n", filename, __FILE__, __LINE__);
        rt = KAT_FILE_OPERATE_FAILED;
        goto end;
    }
end:
    return rt;
}