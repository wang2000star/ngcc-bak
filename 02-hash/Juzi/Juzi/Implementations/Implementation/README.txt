JuziHash implementation package using the ICCS CryptHash API.

This is the GCC/Linux-only implementation folder.  Windows batch files have been
removed to avoid email attachment blocking.  Build and KAT generation are handled
by Makefiles and shell scripts.

Folders:

  Reference_Implementation/JuziHash-512
  Reference_Implementation/JuziHash-1024
  Optimized_Implementation/JuziHash-512
  Optimized_Implementation/JuziHash-1024
  Additional_Implementation/      Empty placeholder.

Each JuziHash instance folder contains:

  CryptHash_AlgorithmInstance.c    ICCS API wrapper plus JuziHash implementation.
  CryptHash_AlgorithmInstance.h    ICCS-compatible header.
  KAT_CryptHash.c                  ICCS KAT generator.
  drng.c, drng.h                   DRNG files from the ICCS API package.
  Makefile                         GCC build file.
  run_kat_gcc.sh                   Build-and-run helper for KAT generation.
  README.txt                       Folder-specific notes.

From this directory, use:

  make
  make reference
  make optimized
  make kat-reference
  make kat-optimized
  make kat-all
  make clean
