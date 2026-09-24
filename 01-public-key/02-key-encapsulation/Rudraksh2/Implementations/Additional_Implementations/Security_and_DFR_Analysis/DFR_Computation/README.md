# DFR computation for Rudraksh2 and MORNING-Scabbard using 2D-B2-Minal

Implementation used for computing the decryption failure rate (DFR)
for Rudraksh2 (LWE-KEM) and MORNING-Scabbard (LWR-KEM), when
2D-B2-Minal codes are used.

## Usage

### Compilation

This project is built with cmake. The standard operation of this system is:

```
cmake -B build
make -C build
```

This will create some static libraries and executables in `build`.
Out of them, the most important are:
```
minal2d_dfr_computation_lwr
minal2d_dfr_computation_lwe
```

These can be used to compute the DFR, as explained next.


### DFR computation for Rudraksh2 (LWE-KEM)

Rudraksh2 is based on LWE, so we use `build/minal2d_dfr_computation_lwe`.
This file reads a setup file like `setup/rudraksh_minal_2d_b2_dfr.csv`:
```
$ head setup/rudraksh_minal_2d_b2_dfr.csv
KEM_Q,KEM_LEVEL,KEM_MESSAGE_BIT_LENGTH,KEM_N,KEM_K,KEM_ETA1,KEM_ETA2,KEM_N_BLOCKS_FOR_DU0,KEM_DU0,KEM_DU1,KEM_DV
3329,1,128,64,9,2,2,9,12,0,6
3329,2,256,128,9,1,1,9,11,0,9
7681,3,512,256,8,2,2,8,13,0,7
4001,1,128,64,9,1,1,9,9,0,7
4001,2,256,128,9,1,1,9,11,0,5
4001,3,512,256,9,1,1,9,12,0,8
```

Then, for each configuration, it computes the DFR when 2D-B2-Minal codes are used
for different values of parameter `CODE_BETA`.
To reproduce `results/rudraksh_minal_2d_b2_dfr.csv`, run:
```
$ export OMP_NUM_THREADS=8
$ ./build/dfr_analysis/minal2d_dfr_computation_lwe setup/rudraksh_minal_2d_b2_dfr.csv | tee rudraksh_dfr_results.csv
```


### DFR computation for MORNING-Scabbard (LWR-KEM)

MORNING-Scabbard is based on LWE, so we use `build/minal2d_dfr_computation_lwr`.
This file reads a setup file like `setup/scabbard_minal_2d_b2_dfr.csv`:
```
$ head setup/rudraksh_minal_2d_b2_dfr.csv
KEM_Q,KEM_LEVEL,KEM_MESSAGE_BIT_LENGTH,KEM_N,KEM_K,KEM_ETA1,KEM_ETA2,KEM_N_BLOCKS_FOR_DU0,KEM_DU0,KEM_DU1,KEM_DV
16384,1,128,64,9,2,0,9,10,0,5
8192,2,256,128,9,2,0,9,11,0,4
8192,3,512,256,8,2,0,8,11,0,8
```

Then, for each configuration, it computes the DFR when 2D-B2-Minal codes are used
for different values of parameter `CODE_BETA`.
To reproduce `results/rudraksh_minal_2d_b2_dfr.csv`, run:
```
$ export OMP_NUM_THREADS=8
$ ./build/dfr_analysis/minal2d_dfr_computation_lwr setup/rudraksh_minal_2d_b2_dfr.csv | tee scabbard_dfr_results.csv
```

This will use around 40GB of RAM and should take around 3 hours to complete.


## Results

The raw results of our runs can be seen in `results`:
* `results_rudraksh_minal_2d_b2_dfr.csv`: Raw results for Rudraksh2 DFR
* `rudraksh_selected_parameters.csv`: Results with the selected parameters of Beta to minimize DFR
* `results_scabbard_minal_2d_b2_dfr.csv`: Raw results for Scabbard DFR
* `scabbard_selected_parameters.csv`: Results with the selected parameters of Beta to minimize DFR

