# Overview

The sub-directory `Amoeba-X` contains algorithm instances corresponding to different parameter sets, which meet the security levels of 128, 192, 256, 384, and 512 classical bits respectively.
Except for `Amoeba-X/CMakeLists.txt`, all other directories and files are fully reused. Considering the operating system compatibility, we use copying instead of soft-links.

`Amoeba-X/src` contains the following sub-directories:
* `symmetric`: Symmetric primitive plugins
* `backend`: Reference implementation, with compilation depending on `symmetric`
* `api`: Interface encapsulation for `backend`
* `tests`: Functional and performance tests
* `KAT`: Used to generate KAT files

# Usage
Enter the `Implementations/Reference_Implementation` directory and execute `bash ./build.sh`, which will automatically complete the compilation of all `Amoeba-X`.
The dynamic library products are stored in `Amoeba-X/libs`, and the executable file products are stored in `Amoeba-X/bin`.

Execute `bash ./build.sh clean` to clean up all compilation products.