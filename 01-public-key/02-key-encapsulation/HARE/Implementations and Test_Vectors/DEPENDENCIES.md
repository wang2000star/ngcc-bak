# Dependencies

The HARE source code itself is C99 plus optional public compile-time x86/ARM
intrinsics in optimized/additional implementations.  It does not require a
third-party cryptographic library.

Required build and validation tools:

```text
bash
python3 >= 3.6
GCC with C99 support
CMake and ctest
make
sha256sum
tar
objdump and size from binutils
/usr/bin/time with -v support for resource recording
taskset for single-core pinning on the current x86/ARM servers
```

The API_PKC helper hash/XOF functions are included only for correctness and
initial performance testing, consistent with the submission requirements.  They
must not be described as production-grade cryptographic hash/XOF replacements.

## x86 validation host

The x86 self-evaluation guide baseline is CentOS 8.2, GCC 8.3.1, CMake 3.11.4,
single-core testing, and AVX2-capable x86_64 hardware.  The current x86 server
used by this project should record its exact environment in each result archive.

## ARM/SVE validation host

The ARM self-evaluation guide baseline is a 64-bit ARMv8.2-A/SVE environment.
This package's Additional implementation also requires PMULL when validating
the PMULL-enabled path.  If a compiler or CMake version differs from the guide,
record the deviation in the server result archive.
