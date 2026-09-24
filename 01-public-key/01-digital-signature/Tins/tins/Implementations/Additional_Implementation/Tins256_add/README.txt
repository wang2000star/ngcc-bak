*********************************Instructions**********************************

drng.c                      Source file of Deterministic Random Number Generator

drng.h                      Header file of Deterministic Random Number Generator

auxfunc.c                   Source file of auxiliary functions

auxfunc.h                   Header file of auxiliary functions

ff_arith.c                  Source file of low-level finite field arithmetic for digital signatures

ff_arith.h                  Header file of low-level finite field arithmetic for digital signatures

bavc_commit.c       Source file of sub-algorithms associated with core signing computations

bavc_commit.h        Header file of sub-algorithms associated with core signing computations

params.h                 Header file of parameters associated with the algorithm

KAT_SIG.c                Source file for generating test vector files of  Tins scheme

SIG_TINS256.c        Source file of Tins SIG scheme 

SIG_TINS256.h        Header file of Tins SIG scheme 

main.c                     Source file of the test of Tins SIG scheme 


**************************************Use**************************************


To test the efficiency of the Tins signature algorithm, you can compile and run the code using the following command:


>gcc ff_arith.c SIG_TINS256.c drng.c bavc_commit.c auxfunc.c main.c -o main -O3 -fopenmp -ljemalloc

>./main


