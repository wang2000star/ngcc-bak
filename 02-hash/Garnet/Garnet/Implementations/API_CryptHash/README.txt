运行方法：
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512_512.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 1024即生成Garnet-1024a（4x4状态的SPONGE-DM）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512_512.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 512即生成Garnet-512 （512容量）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512_768.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 512即生成Garnet-512 （768容量）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 512即生成Garnet-512 （1024容量）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512_896.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 512即生成Garnet-512 （896容量）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512_640.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 512即生成Garnet-512 （640容量）
gcc ./CryptHash_Garnet.c ./KAT_CryptHash.c ./Garnet_1024.c ./Garnet_512.c ./Garnet_768.c drng.c
修改#define DIGEST_BIT_LENGTH 768即生成Garnet-768