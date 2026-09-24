\Implementations
	\Additional_Implementation
	\Optimized_Implementation
		\TaiChi-512-op-per
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-512-op-per instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-512-op-per instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-512-op-per
		\TaiChi-768-op-per
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-768-op-per instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-768-op-per instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-768-op-per		
		\TaiChi-1024-op-per
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-1024-op-per instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-1024-op-per instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-1024-op-per
		\TaiChi-512-op-res
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-512-op-res instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-512-op-res instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-512-op-res
		\TaiChi-768-op-res
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-768-op-res instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-768-op-res instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-768-op-res		
		\TaiChi-1024-op-res
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-1024-op-res instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-1024-op-res instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-1024-op-res

	\Reference_Implementation
		\TaiChi-512
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-512 instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-512 instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-512
		\TaiChi-768
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-768 instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-768 instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-768			
		\TaiChi-1024
			\drng.h 								Header file of Deterministic Random Number Generator
			\drng.c								Source file of Deterministic Random Number Generator
			\CryptHash_AlgorithmInstance.h		Header file of TaiChi-1024 instance (programming interface)
			\CryptHash_AlgorithmInstance.c		Source file of TaiChi-1024 instance (programming interface)
			\KAT_CryptHash.c					Source file for generating test vector files of TaiChi-1024
		\README.txt								This file
\Test_Vector
	\KAT_2_12_TaiChi-512.txt						Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-512 hash values
	\KAT_2_23_TaiChi-512.txt						Messages with a length of 2^23 bits and their corresponding TaiChi-512 hash value
	\KAT_2_33_TaiChi-512.txt						Messages with a length of 2^33 bits and their corresponding TaiChi-512 hash value
	\KAT_Loop_TaiChi-512.txt						Messages with a length of 2^13 bits and their corresponding TaiChi-512 hash value
	\KAT_2_12_TaiChi-768.txt						Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-768 hash values
	\KAT_2_23_TaiChi-768.txt						Messages with a length of 2^23 bits and their corresponding TaiChi-768 hash value
	\KAT_2_33_TaiChi-768.txt						Messages with a length of 2^33 bits and their corresponding TaiChi-768 hash value
	\KAT_Loop_TaiChi-768.txt						Messages with a length of 2^13 bits and their corresponding TaiChi-768 hash value
	\KAT_2_12_TaiChi-1024.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-1024 hash values
	\KAT_2_23_TaiChi-1024.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-1024 hash value
	\KAT_2_33_TaiChi-1024.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-1024 hash value
	\KAT_Loop_TaiChi-1024.txt					Messages with a length of 2^13 bits and their corresponding TaiChi-1024 hash value
	\KAT_2_12_TaiChi-512-op-per.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-512-op-per hash values
	\KAT_2_23_TaiChi-512-op-per.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-512-op-per hash value
	\KAT_2_33_TaiChi-512-op-per.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-512-op-per hash value
	\KAT_Loop_TaiChi-512-op-per.txt					Messages with a length of 2^13 bits and their corresponding TaiChi-512-op-per hash value
	\KAT_2_12_TaiChi-768-op-per.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-768-op-per hash values
	\KAT_2_23_TaiChi-768-op-per.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-768-op-per hash value
	\KAT_2_33_TaiChi-768-op-per.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-768-op-per hash value
	\KAT_Loop_TaiChi-768-op-per.txt					Messages with a length of 2^13 bits and their corresponding TaiChi-768-op-per hash value
	\KAT_2_12_TaiChi-1024-op-per.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-1024 hash values
	\KAT_2_23_TaiChi-1024-op-per.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-1024-op-per hash value
	\KAT_2_33_TaiChi-1024-op-per.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-1024-op-per hash value
	\KAT_Loop_TaiChi-1024-op-per.txt				Messages with a length of 2^13 bits and their corresponding TaiChi-1024-op-per hash value
	\KAT_2_12_TaiChi-512-op-res.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-512-op-res hash values
	\KAT_2_23_TaiChi-512-op-res.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-512-op-res hash value
	\KAT_2_33_TaiChi-512-op-res.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-512-op-res hash value
	\KAT_Loop_TaiChi-512-op-res.txt					Messages with a length of 2^13 bits and their corresponding TaiChi-512-op-res hash value
	\KAT_2_12_TaiChi-768-op-res.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-768-op-res hash values
	\KAT_2_23_TaiChi-768-op-res.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-768-op-res hash value
	\KAT_2_33_TaiChi-768-op-res.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-768-op-res hash value
	\KAT_Loop_TaiChi-768-op-res.txt					Messages with a length of 2^13 bits and their corresponding TaiChi-768-op-res hash value
	\KAT_2_12_TaiChi-1024-op-res.txt					Messages with lengths ranging from 0 to 2^12 bits and their corresponding TaiChi-1024 hash values
	\KAT_2_23_TaiChi-1024-op-res.txt					Messages with a length of 2^23 bits and their corresponding TaiChi-1024-op-res hash value
	\KAT_2_33_TaiChi-1024-op-res.txt					Messages with a length of 2^33 bits and their corresponding TaiChi-1024-op-res hash value
	\KAT_Loop_TaiChi-1024-op-res.txt				Messages with a length of 2^13 bits and their corresponding TaiChi-1024-op-res hash value