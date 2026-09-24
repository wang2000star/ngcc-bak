Galas implementation directory

This directory follows the NGCC implementation-code layout:

Reference_Implementation/
  Portable C reference implementation. Each instance folder contains the
  Galas source tree, NGCC SIG API glue, Makefile, and an INSTANCE.txt file.

Optimized_Implementation/
  x86-64 optimized implementation. Each instance folder contains the Meson
  source tree and an INSTANCE.txt file.

API_PKC/Test_Vector/
  Copy of the API_PKC KAT input template used by the reference Makefile.

kat/
  Output directory used by the reference Makefile when regenerating KATs from
  within a packaged instance directory.

The generated KAT files submitted to NGCC are stored in ../Test_Vectors/.

Reference build example:

  cd Reference_Implementation/Galas-256S
  make check
  make kat
  make bench REPS=100

Optimized build example:

  cd Optimized_Implementation/Galas-256S
  meson setup build --buildtype=release -Doptimization=3
  ninja -C build
  ./build/galas_bench Galas-256S 100

The reference implementation uses the C99/O2 reference profile. The optimized
implementation uses the x86-64/AVX2/O3 performance profile. The full
self-evaluation scripts are in ../Self_Evaluation/.
