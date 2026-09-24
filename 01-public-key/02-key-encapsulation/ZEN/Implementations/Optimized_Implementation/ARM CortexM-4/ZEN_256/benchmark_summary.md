## crypto_kem
**speed**

| scheme | implementation | metric | count | average | median | min | max |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| ZEN-128 | m4 | keypair | 100 | 355,560 | 329,326 | 329,288 | 531,369 |
| ZEN-128 | m4 | encaps | 100 | 270,406 | 270,406 | 270,349 | 270,446 |
| ZEN-128 | m4 | decaps | 100 | 424,477 | 424,476 | 424,476 | 424,515 |
| ZEN-128 | ref | keypair | 100 | 610,123 | 582,605 | 582,599 | 794,319 |
| ZEN-128 | ref | encaps | 100 | 387,108 | 387,105 | 387,046 | 387,154 |
| ZEN-128 | ref | decaps | 100 | 1,287,817 | 1,287,814 | 1,287,814 | 1,287,854 |
| ZEN-256 | m4 | keypair | 100 | 807,074 | 713,574 | 713,573 | 1,258,230 |
| ZEN-256 | m4 | encaps | 100 | 337,296 | 337,294 | 337,294 | 337,335 |
| ZEN-256 | m4 | decaps | 100 | 688,737 | 688,735 | 688,735 | 688,773 |
| ZEN-256 | ref | keypair | 100 | 1,331,030 | 1,235,305 | 1,235,282 | 1,793,013 |
| ZEN-256 | ref | encaps | 100 | 654,755 | 654,754 | 654,753 | 654,793 |
| ZEN-256 | ref | decaps | 100 | 3,961,513 | 3,961,505 | 3,961,504 | 3,961,545 |
| ZEN-512 | m4 | keypair | 100 | 2,423,348 | 2,235,212 | 2,235,173 | 3,639,374 |
| ZEN-512 | m4 | encaps | 100 | 972,493 | 972,492 | 972,490 | 972,533 |
| ZEN-512 | m4 | decaps | 100 | 1,871,935 | 1,871,934 | 1,871,934 | 1,871,973 |

**stack**

| scheme | implementation | metric | count | average |
| --- | --- | --- | ---: | ---: |
| ZEN-128 | m4 | keypair | 1 | 9,856 |
| ZEN-128 | m4 | encaps | 1 | 12,984 |
| ZEN-128 | m4 | decaps | 1 | 14,056 |
| ZEN-128 | ref | keypair | 1 | 9,984 |
| ZEN-128 | ref | encaps | 1 | 13,000 |
| ZEN-128 | ref | decaps | 1 | 14,072 |
| ZEN-256 | m4 | keypair | 1 | 17,352 |
| ZEN-256 | m4 | encaps | 1 | 13,444 |
| ZEN-256 | m4 | decaps | 1 | 15,572 |
| ZEN-256 | ref | keypair | 1 | 17,608 |
| ZEN-256 | ref | encaps | 1 | 13,460 |
| ZEN-256 | ref | decaps | 1 | 15,588 |
| ZEN-512 | m4 | keypair | 1 | 38,856 |
| ZEN-512 | m4 | encaps | 1 | 33,888 |
| ZEN-512 | m4 | decaps | 1 | 38,176 |
| ZEN-512 | ref | keypair | 1 | 39,376 |
| ZEN-512 | ref | encaps | 1 | 33,904 |
| ZEN-512 | ref | decaps | 1 | 38,192 |

**hashing**

| scheme | implementation | metric | count | percentage |
| --- | --- | --- | ---: | ---: |
| ZEN-128 | m4 | keypair | 100 | 39.33% |
| ZEN-128 | m4 | encaps | 100 | 67.53% |
| ZEN-128 | m4 | decaps | 100 | 40.34% |
| ZEN-128 | ref | keypair | 100 | 22.91% |
| ZEN-128 | ref | encaps | 100 | 47.20% |
| ZEN-128 | ref | decaps | 100 | 13.30% |
| ZEN-256 | m4 | keypair | 100 | 35.33% |
| ZEN-256 | m4 | encaps | 100 | 60.70% |
| ZEN-256 | m4 | decaps | 100 | 27.44% |
| ZEN-256 | ref | keypair | 100 | 21.63% |
| ZEN-256 | ref | encaps | 100 | 31.29% |
| ZEN-256 | ref | decaps | 100 | 4.77% |
| ZEN-512 | m4 | keypair | 100 | 33.84% |
| ZEN-512 | m4 | encaps | 100 | 54.45% |
| ZEN-512 | m4 | decaps | 100 | 25.74% |

**code size (speed)**

| scheme | implementation | .text | .data | .bss | total |
| --- | --- | ---: | ---: | ---: | ---: |
| ZEN-128 | m4 | 48,848 | 1,352 | 548 | 50,748 |
| ZEN-128 | ref | 39,712 | 1,352 | 548 | 41,612 |
| ZEN-256 | m4 | 57,872 | 1,352 | 548 | 59,772 |
| ZEN-256 | ref | 47,548 | 1,352 | 548 | 49,448 |
| ZEN-512 | m4 | 78,924 | 1,352 | 548 | 80,824 |
| ZEN-512 | ref | 67,484 | 1,352 | 548 | 69,384 |
