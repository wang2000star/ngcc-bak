#!/usr/bin/env bash
set -euo pipefail

echo "### uname"
uname -a || true
uname -m || true

echo
echo "### compiler"
gcc --version | head -5 || true
clang --version | head -5 || true
cmake --version | head -3 || true
make --version | head -3 || true

echo
echo "### /proc/cpuinfo Features"
grep -m1 '^Features' /proc/cpuinfo || true

echo
echo "### selected feature tokens"
grep -m1 '^Features' /proc/cpuinfo | tr ' ' '\n' | egrep '^(asimd|aes|pmull|sha1|sha2|sha3|sm3|sm4|sve|sve2|sveaes|svepmull|svesha3|i8mm|bf16)$' || true

echo
echo "### CNTFRQ_EL0"
cat > /tmp/hare_read_cntfrq.c <<'SRC'
#include <stdint.h>
#include <stdio.h>
int main(void) {
#if defined(__aarch64__)
    uint64_t v = 0;
    __asm__ volatile("mrs %0, cntfrq_el0" : "=r"(v));
    printf("CNTFRQ_EL0=%llu\n", (unsigned long long)v);
#else
    printf("not aarch64\n");
#endif
    return 0;
}
SRC
gcc -O2 /tmp/hare_read_cntfrq.c -o /tmp/hare_read_cntfrq
/tmp/hare_read_cntfrq || true

echo
echo "### SVE vector length"
cat > /tmp/hare_sve_probe.c <<'SRC'
#include <stdio.h>
#include <arm_sve.h>
int main(void) {
    printf("svcntb=%lu\n", (unsigned long)svcntb());
    printf("svcnth=%lu\n", (unsigned long)svcnth());
    printf("svcntw=%lu\n", (unsigned long)svcntw());
    printf("svcntd=%lu\n", (unsigned long)svcntd());
    return 0;
}
SRC
gcc -O2 -march=armv8.2-a+sve /tmp/hare_sve_probe.c -o /tmp/hare_sve_probe
/tmp/hare_sve_probe

echo
echo "### compiler target macros"
echo | gcc -dM -E -x c - -march=native | egrep '__ARM_FEATURE|__ARM_NEON|__ARM_ARCH|__ARM_FP|__ARM_PCS' | sort || true

echo
echo "### PMULL compile probe"
cat > /tmp/hare_pmull_probe.c <<'SRC'
#include <arm_neon.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
    poly64_t a = (poly64_t)0x123456789abcdef0ULL;
    poly64_t b = (poly64_t)0xfedcba9876543210ULL;
    poly128_t c = vmull_p64(a, b);
    uint64_t out[2];
    vst1q_u64(out, vreinterpretq_u64_p128(c));
    printf("pmull_compile_ok %016llx %016llx\n", (unsigned long long)out[1], (unsigned long long)out[0]);
    return 0;
}
SRC
if gcc -O2 -march=armv8-a+crypto /tmp/hare_pmull_probe.c -o /tmp/hare_pmull_probe 2>/tmp/hare_pmull_build.log; then
    /tmp/hare_pmull_probe || true
else
    echo "pmull compile failed"
    cat /tmp/hare_pmull_build.log
fi
