# Dependencies

The x86 self-assessment code has no third-party library dependency.

Required build tools:

- GNU GCC 8.5.0 or newer
- CMake 3.11.4 or newer
- POSIX shell for `self_assessment/run_self_assessment.sh`

Optional measurement tools used by the script when available:

- `ctest`
- `size`
- `/usr/bin/time`
- `taskset`

The reference implementation is C99 only. The performance and resource builds
use x86-64 and AVX2 compiler options as specified by the x86 self-assessment
guide.
