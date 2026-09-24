# AFS-KEX API Speed Report

按 `median cycles/ticks` 计算加速比，`speedup = reference / optimized`。

## AFS_KEX_C128

| Case | Reference Median | Optimized Median | Speedup | Reference Avg | Optimized Avg |
| --- | ---: | ---: | ---: | ---: | ---: |
| gen_matrix | 116780 | 49746 | 2.35x | 117718 | 50104 |
| poly_getnoise_eta1 | 22268 | 15248 | 1.46x | 22378 | 15323 |
| poly_getnoise_eta2 | 18628 | 12972 | 1.44x | 18749 | 13028 |
| poly_ntt | 5608 | 228 | 24.60x | 5581 | 230 |
| poly_invntt_tomont | 8780 | 248 | 35.40x | 8710 | 250 |
| polyvec_basemul_acc_montgomery | 7020 | 222 | 31.62x | 7082 | 224 |
| poly_tomsg | 4256 | 1256 | 3.39x | 4283 | 1277 |
| poly_frommsg | 1040 | 118 | 8.81x | 1042 | 116 |
| poly_tobytes | 396 | 58 | 6.83x | 396 | 57 |
| poly_frombytes | 304 | 46 | 6.61x | 304 | 45 |
| polyvec_compress | 2836 | 1950 | 1.45x | 2851 | 1962 |
| polyvec_decompress | 1628 | 2492 | 0.65x | 1641 | 2504 |
| indcpa_keypair_derand | 223300 | 44090 | 5.06x | 224581 | 44471 |
| indcpa_enc | 260598 | 58574 | 4.45x | 262550 | 59138 |
| indcpa_dec | 35074 | 4664 | 7.52x | 35406 | 4691 |
| crypto_kem_keypair | 228272 | 45380 | 5.03x | 230088 | 46502 |
| crypto_kem_enc | 262062 | 60874 | 4.30x | 264153 | 61488 |
| crypto_kem_dec | 312904 | 80338 | 3.89x | 315161 | 80883 |
| kex_init_a | 471408 | 96286 | 4.90x | 474498 | 98912 |
| kex_init_b | 472170 | 96134 | 4.91x | 475788 | 98937 |
| kex_generate_pass1_msg_a | 267428 | 63798 | 4.19x | 269405 | 64337 |
| kex_generate_pass2_msg_b | 584668 | 146564 | 3.99x | 588357 | 147509 |
| kex_generate_pass3_msg_a | 544334 | 126004 | 4.32x | 547220 | 126832 |
| kex_generate_pass4_msg_b | 225772 | 42860 | 5.27x | 226823 | 43256 |
| kex_derive_ss_a | 8 | 4 | 2.00x | 8 | 5 |
| kex_derive_ss_b | 10 | 4 | 2.50x | 9 | 4 |

## AFS_KEX_C256

| Case | Reference Median | Optimized Median | Speedup | Reference Avg | Optimized Avg |
| --- | ---: | ---: | ---: | ---: | ---: |
| gen_matrix | 355214 | 50270 | 7.07x | 358412 | 50670 |
| poly_getnoise_eta1 | 8964 | 7884 | 1.14x | 9039 | 7927 |
| poly_getnoise_eta2 | 8964 | 7880 | 1.14x | 9060 | 7919 |
| poly_ntt | 5190 | 236 | 21.99x | 5242 | 235 |
| poly_invntt_tomont | 6970 | 252 | 27.66x | 7032 | 254 |
| polyvec_basemul_acc_montgomery | 8932 | 310 | 28.81x | 9102 | 314 |
| poly_tomsg | 24892 | 11688 | 2.13x | 25170 | 11773 |
| poly_frommsg | 1590 | 650 | 2.45x | 1629 | 649 |
| poly_tobytes | 396 | 58 | 6.83x | 397 | 58 |
| poly_frombytes | 302 | 46 | 6.57x | 346 | 46 |
| polyvec_compress | 5440 | 3896 | 1.40x | 5503 | 3909 |
| polyvec_decompress | 2904 | 2074 | 1.40x | 2937 | 2089 |
| encode_bw32 | - | 48 | - | - | 47 |
| decode_bw32 | - | 1468 | - | - | 1489 |
| indcpa_keypair_derand | 525586 | 80186 | 6.55x | 531469 | 80671 |
| indcpa_enc | 548836 | 86832 | 6.32x | 554319 | 87288 |
| indcpa_dec | 67390 | 15600 | 4.32x | 68302 | 15688 |
| crypto_kem_keypair | 554022 | 86834 | 6.38x | 563152 | 91263 |
| crypto_kem_enc | 566292 | 102254 | 5.54x | 571941 | 102825 |
| crypto_kem_dec | 663808 | 142504 | 4.66x | 670226 | 143400 |
| kex_init_a | 1117046 | 164874 | 6.78x | 1123316 | 172834 |
| kex_init_b | 1120878 | 164848 | 6.80x | 1123301 | 173068 |
| kex_generate_pass1_msg_a | 565144 | 100908 | 5.60x | 570492 | 101477 |
| kex_generate_pass2_msg_b | 1278736 | 278498 | 4.59x | 1278853 | 280365 |
| kex_generate_pass3_msg_a | 1235062 | 249824 | 4.94x | 1239930 | 251454 |
| kex_generate_pass4_msg_b | 558394 | 99278 | 5.62x | 562279 | 99925 |
| kex_derive_ss_a | 16 | 6 | 2.67x | 15 | 5 |
| kex_derive_ss_b | 8 | 6 | 1.33x | 8 | 5 |

## AFS_KEX_C512

| Case | Reference Median | Optimized Median | Speedup | Reference Avg | Optimized Avg |
| --- | ---: | ---: | ---: | ---: | ---: |
| gen_matrix | 1327922 | 167062 | 7.95x | 1327724 | 168092 |
| poly_getnoise_eta1 | 21810 | 19530 | 1.12x | 21935 | 19629 |
| poly_getnoise_eta2 | 21782 | 19540 | 1.11x | 21912 | 19641 |
| poly_ntt | 21718 | 686 | 31.66x | 21695 | 686 |
| poly_invntt_tomont | 13512 | 746 | 18.11x | 13572 | 767 |
| polyvec_basemul_acc_montgomery | 44650 | 2524 | 17.69x | 44933 | 2546 |
| poly_tomsg | 49764 | 23266 | 2.14x | 50077 | 23410 |
| poly_frommsg | 3112 | 1278 | 2.44x | 3130 | 1278 |
| poly_tobytes | 810 | 162 | 5.00x | 827 | 163 |
| poly_frombytes | 620 | 142 | 4.37x | 621 | 141 |
| polyvec_compress | 10820 | 7762 | 1.39x | 10865 | 7795 |
| polyvec_decompress | 5804 | 4162 | 1.39x | 5845 | 4182 |
| encode_bw32 | - | 46 | - | - | 46 |
| decode_bw32 | - | 1470 | - | - | 1472 |
| indcpa_keypair_derand | 1920612 | 258094 | 7.44x | 1919477 | 259456 |
| indcpa_enc | 1938552 | 257468 | 7.53x | 1937956 | 258849 |
| indcpa_dec | 204380 | 36908 | 5.54x | 205845 | 37153 |
| crypto_kem_keypair | 1970066 | 267848 | 7.36x | 1969665 | 270063 |
| crypto_kem_enc | 1978932 | 295844 | 6.69x | 1978502 | 297405 |
| crypto_kem_dec | 2301364 | 439662 | 5.23x | 2301073 | 443186 |
| kex_init_a | 3932522 | 501320 | 7.84x | 3934228 | 506231 |
| kex_init_b | 3931420 | 501132 | 7.85x | 3931931 | 504907 |
| kex_generate_pass1_msg_a | 1980508 | 296656 | 6.68x | 1979848 | 298276 |
| kex_generate_pass2_msg_b | 4322200 | 758500 | 5.70x | 4326859 | 763366 |
| kex_generate_pass3_msg_a | 4259612 | 689752 | 6.18x | 4259868 | 694029 |
| kex_generate_pass4_msg_b | 1900964 | 227792 | 8.35x | 1900195 | 229082 |
| kex_derive_ss_a | 10 | 6 | 1.67x | 10 | 6 |
| kex_derive_ss_b | 10 | 6 | 1.67x | 10 | 6 |

