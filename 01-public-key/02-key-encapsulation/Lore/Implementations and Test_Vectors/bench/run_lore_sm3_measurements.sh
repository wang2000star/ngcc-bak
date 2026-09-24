#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-usage}"

# Defaults (override via environment)
LEVELS="${LEVELS:-L1 L2 L3 L4}"
LEVELS="$(echo $LEVELS | tr -d L)"
TRIALS="${TRIALS:-10000}"
ITERS="${ITERS:-10000}"
WARMUP="${WARMUP:-1000}"
CORE="${CORE:-0}"

# Paper params lookup
paper_name() {
    case "$1" in
        1) printf '%s\n' "Lore-128";;
        2) printf '%s\n' "Lore-256";;
        3) printf '%s\n' "Lore-384";;
        4) printf '%s\n' "Lore-512";;
        *) printf '%s\n' "Unknown";;
    esac
}

PDF_PK_L1=545;  PDF_CT_L1=641;  PDF_SK_L1=821
PDF_PK_L2=1058; PDF_CT_L2=1153; PDF_SK_L2=1942
PDF_PK_L3=1763; PDF_CT_L3=1921; PDF_SK_L3=3704
PDF_PK_L4=2626; PDF_CT_L4=2886; PDF_SK_L4=5373

usage() {
    echo "Usage: $0 {size|cycles|all}"
    echo ""
    echo "  size      Measure actual serialized sizes for L1/L2/L3/L4"
    echo "  cycles    Run KEM API benchmark (cycles + time) for L1/L2/L3/L4"
    echo "  all       Run both size and cycles"
    echo ""
    echo "Overrides: TRIALS=$TRIALS ITERS=$ITERS WARMUP=$WARMUP CORE=$CORE"
    exit 1
}

run_size() {
    local RUN_ID="run_size_$(date +%Y%m%d_%H%M%S)"
    local OUTDIR="$REPO/bench/results/$RUN_ID"
    mkdir -p "$OUTDIR"

    local CSV="$OUTDIR/lore_actual_size_statistics.csv"
    echo "level,type,count,min,avg,max,p5,p50,p95,pdf,avg_minus_pdf,source" > "$CSV"

    local PDF_PK PDF_CT PDF_SK
    for L in $LEVELS; do
        case $L in
            1) PDF_PK=$PDF_PK_L1; PDF_CT=$PDF_CT_L1; PDF_SK=$PDF_SK_L1;;
            2) PDF_PK=$PDF_PK_L2; PDF_CT=$PDF_CT_L2; PDF_SK=$PDF_SK_L2;;
            3) PDF_PK=$PDF_PK_L3; PDF_CT=$PDF_CT_L3; PDF_SK=$PDF_SK_L3;;
            4) PDF_PK=$PDF_PK_L4; PDF_CT=$PDF_CT_L4; PDF_SK=$PDF_SK_L4;;
            *) echo "Unsupported SM3 level: L${L}. This package supports L1/L2/L3/L4." >&2; exit 1;;
        esac

        echo "===== L${L} actual sizes  ====="
        :> "$OUTDIR/actual_size_L${L}.txt"  # truncate before appending

        for pair in "pk $PDF_PK" "ct $PDF_CT" "sk $PDF_SK"; do
            local type=$(echo $pair | awk '{print $1}')
            local val=$(echo $pair | awk '{print $2}')
            echo "$type,$val" >> "$OUTDIR/actual_size_L${L}.txt"
            echo "L${L},$type,0,$val,$val,$val,$val,$val,$val,$val,0,PDF/specification" >> "$CSV"
            echo "  L${L} $type=$val "
        done
    done
    echo "Output: $OUTDIR"
}

run_cycles() {
    local RUN_ID="run_cycles_$(date +%Y%m%d_%H%M%S)"
    local OUTDIR="$REPO/bench/results/$RUN_ID"
    mkdir -p "$OUTDIR"

    local CSV="$OUTDIR/lore_sm3_kem_api_cycles.csv"
    echo "scheme,level,paper_name,classical_security,operation,iterations,warmup,avg_cycles,median_cycles,avg_us,median_us,pk_bytes,ct_bytes,sk_bytes,ss_bytes,kappa,n,k,t,backend,opt_status,failures" > "$CSV"

    # Generate architecture-aware benchmark source (always regenerate)
    local BENCH_SRC="$REPO/bench/.bench_kem_cycles_time.c"
    rm -f "$BENCH_SRC"
    cat > "$BENCH_SRC" << 'BENCHSRC'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "api.h"

/* ================================================================
 * Architecture-aware CPU cycle counter.
 * x86_64: rdtsc/rdtscp  (no perf_event_open, no root needed)
 * aarch64: perf_event_open  (requires perf_event_paranoid <= 2 or root)
 * ================================================================ */

static const char *cycle_method = "unknown";

#if defined(__x86_64__) || defined(__i386__)
/* ---- x86_64 / i386: rdtsc (inline asm, no intrinsics needed) ---- */
static void cyc_init(void) { cycle_method = "rdtsc_x86"; }
static inline unsigned long long cyc_rd(void) {
    unsigned int lo, hi;
    __asm__ volatile("rdtsc" : "=a"(lo), "=d"(hi));
    return ((unsigned long long)hi << 32) | lo;
}
static void cyc_close(void) {}
#elif defined(__aarch64__)
/* ---- aarch64: perf_event_open ---- */
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <linux/perf_event.h>
static int perf_fd = -1;
static void cyc_init(void) {
    cycle_method = "perf_event_open_aarch64";
    struct perf_event_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.type = PERF_TYPE_HARDWARE;
    attr.config = PERF_COUNT_HW_CPU_CYCLES;
    attr.size = sizeof(attr);
    attr.disabled = 1;
    attr.exclude_kernel = 1;
    attr.exclude_hv = 1;
    perf_fd = syscall(__NR_perf_event_open, &attr, 0, -1, -1, 0);
    if (perf_fd < 0) {
        fprintf(stderr, "[ERROR] perf_event_open failed on aarch64 (errno=%d). "
                "Check perf_event_paranoid or run as root.\n", errno);
        exit(1);
    }
    ioctl(perf_fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(perf_fd, PERF_EVENT_IOC_ENABLE, 0);
}
static inline unsigned long long cyc_rd(void) {
    unsigned long long v = 0;
    read(perf_fd, &v, sizeof(v));
    return v;
}
static void cyc_close(void) { if (perf_fd >= 0) close(perf_fd); }
#else
#error "Unsupported architecture for cycle counter. Only x86_64 and aarch64 are supported."
#endif

static long long ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

static int u64cmp(const void *a, const void *b) {
    unsigned long long x = *(const unsigned long long*)a, y = *(const unsigned long long*)b;
    return (x > y) ? 1 : (x < y) ? -1 : 0;
}
static int s64cmp(const void *a, const void *b) {
    long long x = *(const long long*)a, y = *(const long long*)b;
    return (x > y) ? 1 : (x < y) ? -1 : 0;
}

int main(void) {
    cyc_init();
    fprintf(stderr, "arch=%s cycle_counter=%s\n",
#if defined(__x86_64__)
        "x86_64",
#elif defined(__i386__)
        "i386",
#elif defined(__aarch64__)
        "aarch64",
#else
        "unknown",
#endif
        cycle_method);

    unsigned char pk[CRYPTO_PUBLICKEYBYTES], sk[CRYPTO_SECRETKEYBYTES];
    unsigned char ct[CRYPTO_CIPHERTEXTBYTES], ss[CRYPTO_BYTES], ss2[CRYPTO_BYTES];
    int fail = 0, W = WARMUP_VAL, N = ITERS_VAL;

    unsigned long long *cb = malloc(N * sizeof(unsigned long long));
    long long *tb = malloc(N * sizeof(long long));
    if (!cb || !tb) { fprintf(stderr, "malloc failed\n"); exit(1); }

    for (int i = 0; i < W; i++) {
        crypto_kem_keypair(pk, sk);
        crypto_kem_enc(ct, ss, pk);
        crypto_kem_dec(ss2, ct, sk);
        if (memcmp(ss, ss2, CRYPTO_BYTES)) fail++;
    }

    /* keygen */
    {
        unsigned long long ac = 0; long long an = 0;
        for (int i = 0; i < N; i++) {
            long long t0 = ns(); unsigned long long c0 = cyc_rd();
            crypto_kem_keypair(pk, sk);
            unsigned long long c1 = cyc_rd(); long long t1 = ns();
            cb[i] = c1 - c0; tb[i] = t1 - t0;
            ac += cb[i]; an += tb[i];
        }
        qsort(cb, N, sizeof(unsigned long long), u64cmp);
        qsort(tb, N, sizeof(long long), s64cmp);
        ac /= N; an /= N;
        printf("Lore-SM3,L%d,Lore-%d,%d-bit,kem_keygen,%d,%d,%llu,%llu,%.2f,%.2f,%zu,%zu,%zu,%zu,%d,%d,%d,%d,SM3,AB_inline,%d\n",
            LORE_LEVEL, LORE_KAPPA, LORE_KAPPA, N, W, ac, cb[N/2],
            an / 1000.0, tb[N/2] / 1000.0,
            (size_t)CRYPTO_PUBLICKEYBYTES, (size_t)CRYPTO_CIPHERTEXTBYTES,
            (size_t)CRYPTO_SECRETKEYBYTES, (size_t)CRYPTO_BYTES,
            LORE_KAPPA, LORE_N, LORE_K, LORE_T, fail);
    }

    /* encaps */
    {
        crypto_kem_keypair(pk, sk);
        unsigned long long ac = 0; long long an = 0;
        for (int i = 0; i < N; i++) {
            long long t0 = ns(); unsigned long long c0 = cyc_rd();
            crypto_kem_enc(ct, ss, pk);
            unsigned long long c1 = cyc_rd(); long long t1 = ns();
            cb[i] = c1 - c0; tb[i] = t1 - t0;
            ac += cb[i]; an += tb[i];
        }
        qsort(cb, N, sizeof(unsigned long long), u64cmp);
        qsort(tb, N, sizeof(long long), s64cmp);
        ac /= N; an /= N;
        printf("Lore-SM3,L%d,Lore-%d,%d-bit,kem_encaps,%d,%d,%llu,%llu,%.2f,%.2f,%zu,%zu,%zu,%zu,%d,%d,%d,%d,SM3,AB_inline,%d\n",
            LORE_LEVEL, LORE_KAPPA, LORE_KAPPA, N, W, ac, cb[N/2],
            an / 1000.0, tb[N/2] / 1000.0,
            (size_t)CRYPTO_PUBLICKEYBYTES, (size_t)CRYPTO_CIPHERTEXTBYTES,
            (size_t)CRYPTO_SECRETKEYBYTES, (size_t)CRYPTO_BYTES,
            LORE_KAPPA, LORE_N, LORE_K, LORE_T, fail);
    }

    /* decaps */
    {
        crypto_kem_keypair(pk, sk);
        crypto_kem_enc(ct, ss, pk);
        unsigned long long ac = 0; long long an = 0;
        for (int i = 0; i < N; i++) {
            long long t0 = ns(); unsigned long long c0 = cyc_rd();
            crypto_kem_dec(ss2, ct, sk);
            unsigned long long c1 = cyc_rd(); long long t1 = ns();
            cb[i] = c1 - c0; tb[i] = t1 - t0;
            if (memcmp(ss, ss2, CRYPTO_BYTES)) fail++;
            ac += cb[i]; an += tb[i];
        }
        qsort(cb, N, sizeof(unsigned long long), u64cmp);
        qsort(tb, N, sizeof(long long), s64cmp);
        ac /= N; an /= N;
        printf("Lore-SM3,L%d,Lore-%d,%d-bit,kem_decaps,%d,%d,%llu,%llu,%.2f,%.2f,%zu,%zu,%zu,%zu,%d,%d,%d,%d,SM3,AB_inline,%d\n",
            LORE_LEVEL, LORE_KAPPA, LORE_KAPPA, N, W, ac, cb[N/2],
            an / 1000.0, tb[N/2] / 1000.0,
            (size_t)CRYPTO_PUBLICKEYBYTES, (size_t)CRYPTO_CIPHERTEXTBYTES,
            (size_t)CRYPTO_SECRETKEYBYTES, (size_t)CRYPTO_BYTES,
            LORE_KAPPA, LORE_N, LORE_K, LORE_T, fail);
    }

    cyc_close();
    free(cb); free(tb);
    return fail ? 1 : 0;
}
BENCHSRC

    # KEM API source files only (no KAT/DRNG wrapper)
    local SRC="kem.c pke.c indcpa.c polyvec.c poly.c ntt.c sampler.c reduce.c symmetric-sm3.c sm3_xof.c sm3.c auxfunc.c toomcook.c verify.c bch_codec.c randombytes.c"

    for L in $LEVELS; do
        case "$L" in
            1|2|3|4) ;;
            *) echo "Unsupported SM3 level: L${L}. This package supports L1/L2/L3/L4." >&2; exit 1;;
        esac

        local D="$REPO/Implementations/Reference_Implementation/Lore-SM3/Lore-L${L}"
        echo "===== Benchmark L${L} ($(paper_name "$L")) ====="
        cd "$D"

        local BIN="/tmp/bench_run_L${L}"
        if gcc -O3 -DNDEBUG -std=gnu11 -D_POSIX_C_SOURCE=199309L \
            -DWARMUP_VAL=${WARMUP} -DITERS_VAL=${ITERS} \
            -I. -DLORE_LEVEL=${L} \
            "$BENCH_SRC" $SRC -o "$BIN" -lm 2>"$OUTDIR/bench_L${L}.log"; then
            local RUN="$BIN"
            [ -n "$CORE" ] && [ "$CORE" != "0" ] && RUN="taskset -c $CORE $BIN"

            local RAW="$OUTDIR/bench_L${L}.txt"
            if $RUN > "$RAW" 2>> "$RAW"; then
                cat "$RAW"                    # terminal display
                grep "^Lore-SM3" "$RAW" >> "$CSV"
                echo "  Done."
            else
                cat "$RAW" || true
                echo "  [ERROR] benchmark failed for L${L}. See $RAW"
            fi
        else
            echo "  [ERROR] compile failed for L${L}. See $OUTDIR/bench_L${L}.log"
        fi
    done
    echo "Output: $OUTDIR"
}

case "$MODE" in
    size)   run_size;;
    cycles) run_cycles;;
    all)    run_size; run_cycles;;
    *)      usage;;
esac
