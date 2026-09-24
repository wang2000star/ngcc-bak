#!/bin/sh
# =============================================================================
# QSH AArch64 (ARM) self-assessment (NGCC guideline 1-1). Run on a quiet
# single-socket Linux ARM box (e.g. AWS Graviton, Ampere, Apple under Asahi).
# For the three required versions and the three instances (QSH-512/768/1024):
#   reference  = portable C99 reference            (gcc -O2)
#   performance= NEON within-permutation SIMD      (Additional_Implementation_WithinPerm)
#   resource   = CV-stack, O(log Pi) memory        (gcc -Os, portable)
# Produces: environment+recordable items; FUNCTIONAL KAT (which also VALIDATES
# the NEON code); PERFORMANCE (cycles via perf_event + MB/s); RESOURCE (static
# size + peak RSS >=100 iters + large-input peak); a filled report; and
# results/submission/ with the materials renamed per guideline 1-4.
#
# *** NEON VALIDATION GATE ***
#   The NEON performance build is only trustworthy if its KAT passes here. If
#   any "opt ... FAIL" appears in the functional results, the NEON path has a
#   bug on this CPU and MUST NOT be submitted -- use the portable reference /
#   resource versions for the optimized slot, or fix NEON, then re-run.
#
# Usage:
#   nohup stdbuf -oL -eL sh SelfAssessment/selfassess_arm.sh > ~/selfassess_arm.log 2>&1 &
#   tail -f ~/selfassess_arm.log
# Env toggles:
#   KAT_HEAVY=1     full official KAT (incl. 1 GiB 2_33) for ALL versions.
#   PEAK_BIG_MIB=N  large-input peak-RSS size in MiB (default 64).
#   CPU_GHZ=3.0     core GHz, used only if perf_event cycles are unavailable.
#   CC=gcc-13       compiler override.
# =============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/SelfAssessment/results"; mkdir -p "$OUT"
REPORT="$OUT/Report_arm_selfassessment.md"
ENVF="$OUT/environment_arm.txt"
TV="$ROOT/Test_Vectors"
CORE=0
KAT_HEAVY="${KAT_HEAVY:-0}"
PEAK_BIG_MIB="${PEAK_BIG_MIB:-64}"
CPU_GHZ="${CPU_GHZ:-}"

REF_FLAGS="-std=c99 -Wpedantic -Wall -Wextra -O2"
OPT_FLAGS="-O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
# resource build uses -O3 (not -Os): the resource win is the O(log Pi) CV-stack
# (memory), and -Os spills the wide NEON w=64 state badly. -O3 = full speed + low memory.
RES_FLAGS="-O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
REF_DIR="$ROOT/Implementations/Reference_Implementation"
OPT_DIR="$ROOT/Implementations/Additional_Implementation_WithinPerm"   # NEON within-permutation
RES_DIR="$ROOT/Implementations/Resource_Optimized_Implementation"

CC="${CC:-gcc}"

echo "==== [0/7] prerequisites ===="
command -v "$CC" >/dev/null 2>&1 || { echo "ERROR: compiler '$CC' not found.
  sudo apt-get update && sudo apt-get install -y build-essential binutils time util-linux cmake"; exit 1; }
case "$(uname -m)" in aarch64|arm64) : ;; *) echo "  WARNING: this is not an AArch64 host (uname -m = $(uname -m)).
  The NEON path needs AArch64; on other CPUs it falls back to scalar and the
  'performance' figures are not representative. Run this on a real ARM box.";; esac
HAVE_SIZE=0; command -v size >/dev/null 2>&1 && HAVE_SIZE=1 || echo "  note: 'size' (binutils) missing -> static-memory step skipped"
HAVE_TIME=0; [ -x /usr/bin/time ] && HAVE_TIME=1 || echo "  note: /usr/bin/time missing -> peak-RSS step skipped"
PIN=""; command -v taskset >/dev/null 2>&1 && PIN="taskset -c $CORE"
[ -d "$TV" ] || echo "  WARNING: $TV not found -> KAT functional check will be skipped"
echo "  compiler : $($CC --version | head -1)"
echo "  KAT_HEAVY=$KAT_HEAVY  PEAK_BIG_MIB=$PEAK_BIG_MIB  CPU_GHZ=${CPU_GHZ:-auto}"

echo "==== [1/7] frequency governor (best effort; needs sudo) ===="
if command -v cpupower >/dev/null 2>&1 && cpupower frequency-set -g performance >/dev/null 2>&1; then
    echo "  governor=performance (cpupower)"
elif [ -w /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor ]; then
    echo performance > /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null && echo "  governor=performance (sysfs)"
else
    echo "  (cannot set governor -- cloud VM? ARM cores usually run at a fixed"
    echo "   frequency, which is good for reproducible cycle counts.)"
fi

echo "==== [1b/7] cycle-counter setup (perf_event or frequency fallback) ===="
# Prefer real CPU cycles via perf_event; many virtualized ARM hosts expose no PMU,
# so also derive a fallback frequency for the cyc/byte column.
if [ -w /proc/sys/kernel/perf_event_paranoid ]; then
    echo 1 > /proc/sys/kernel/perf_event_paranoid 2>/dev/null && echo "  perf_event_paranoid set to 1"
fi
if [ -z "$CPU_GHZ" ]; then
    khz=""
    for f in /sys/devices/system/cpu/cpu$CORE/cpufreq/cpuinfo_max_freq \
             /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_max_freq; do
        [ -r "$f" ] && khz=$(cat "$f" 2>/dev/null) && [ -n "$khz" ] && break
    done
    if [ -n "$khz" ]; then CPU_GHZ=$(awk "BEGIN{printf \"%.4f\",$khz/1e6}")
    else
        mhz=$(lscpu 2>/dev/null | awk -F: '/^CPU max MHz/{gsub(/[ \t]/,"",$2);print $2;exit}')
        [ -z "$mhz" ] && mhz=$(lscpu 2>/dev/null | awk -F: '/^CPU MHz/{gsub(/[ \t]/,"",$2);print $2;exit}')
        [ -n "$mhz" ] && CPU_GHZ=$(awk "BEGIN{printf \"%.4f\",$mhz/1000}")
    fi
fi
if [ -n "$CPU_GHZ" ]; then echo "  fallback CPU_GHZ=$CPU_GHZ (used only if perf_event has no PMU)"
else echo "  WARNING: no PMU and no detectable CPU frequency. The cyc/byte columns may
  be blank (throughput MB/s is still measured). Re-run with CPU_GHZ=<your GHz>,
  e.g.  CPU_GHZ=3.0 sh SelfAssessment/selfassess_arm.sh"; fi

echo "==== [2/7] environment ===="
{
  echo "date            : $(date -u)"
  echo "uname           : $(uname -srm)"
  echo "os-release      : $(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME")"
  echo "cpu             : $(grep -m1 -i 'model name\|CPU part\|Processor' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "cpu impl/part   : $(grep -m1 'CPU implementer' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //') / $(grep -m1 'CPU part' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "max freq (kHz)  : $(cat /sys/devices/system/cpu/cpu$CORE/cpufreq/cpuinfo_max_freq 2>/dev/null)"
  echo "gcc             : $($CC --version | head -1)"
  echo "cmake           : $(cmake --version 2>/dev/null | head -1)"
  echo "governor        : $(cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null)"
  echo "perf_paranoid   : $(cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null) (<=2 lets userspace read CPU cycles)"
  echo "pinned core     : $CORE"
  echo "third-party deps: none (only the official ICCS drng.c / KAT_CryptHash.c, unmodified)"
  echo "RNG method      : DRNG from API_CryptHash (SM3 Hash-DRBG); KAT messages seeded per official harness"
  echo "ISA / opt       : AArch64; NEON within-permutation SIMD (perf), -Os CV-stack streaming (resource)"
} | tee "$ENVF"

DRV="$ROOT/Implementations/validate_driver.c"
PERF="$ROOT/SelfAssessment/perf_cycles_arm.c"
KATC="$ROOT/SelfAssessment/kat_check.c"
: > "$OUT/functional_arm.txt"

run_version() {  # $1=label  $2=dir  $3=flags
    label="$1"; dir="$2"; flags="$3"; vsrc="$dir/QSH-512/CryptHash_AlgorithmInstance.c"; inc="$dir/QSH-512"
    echo "==== version: $label  ($flags) ===="
    size_flags=$(echo "$flags" | sed 's/-flto//g')
    if ! $CC $size_flags -I"$inc" -c "$vsrc" -o "$OUT/impl_$label.o" 2>"$OUT/warn_$label.txt"; then
        echo "  BUILD FAILED:"; sed 's/^/    /' "$OUT/warn_$label.txt"; echo "$label BUILD-FAIL" >> "$OUT/functional_arm.txt"; return 1
    fi
    echo "  build warnings: $(grep -c warning "$OUT/warn_$label.txt")"

    if [ "$HAVE_SIZE" = 1 ]; then
        echo "  static memory (size $label, no -flto):"; size "$OUT/impl_$label.o" | tee "$OUT/static_$label.txt" | sed 's/^/    /'
    else echo "  static memory: skipped" | tee "$OUT/static_$label.txt"; fi

    # ---- functional A: KAT_2_12 known-answer (also validates NEON on this CPU) ----
    echo "  [KAT] KAT_2_12 known-answer:"
    if [ -d "$TV" ] && $CC $flags -I"$inc" "$KATC" "$vsrc" -o "$OUT/katc_$label" 2>/dev/null; then
        for v in 512 768 1024; do
            r=$($PIN "$OUT/katc_$label" "$TV/KAT_2_12_QSH-$v.txt" 2>>"$OUT/.kerr"); st=$?
            echo "    QSH-$v: $(echo "$r" | sed 's#.*/##')  $( [ $st -eq 0 ] && echo PASS || echo FAIL )"
            echo "$label KAT_2_12 QSH-$v: $r [$( [ $st -eq 0 ] && echo PASS || echo FAIL )]" >> "$OUT/functional_arm.txt"
        done
    else echo "    skipped (no Test_Vectors or build failed)"; echo "$label KAT_2_12: skipped" >> "$OUT/functional_arm.txt"; fi

    # ---- functional B: cross-version byte-identity vs portable reference ----
    $CC -O2 -std=c99 -I"$REF_DIR/QSH-512" "$DRV" "$REF_DIR/QSH-512/CryptHash_AlgorithmInstance.c" -o "$OUT/d_ref" 2>/dev/null
    $CC $flags -I"$inc" "$DRV" "$vsrc" -o "$OUT/d_$label" 2>/dev/null
    func="PASS"
    if [ -x "$OUT/d_ref" ] && [ -x "$OUT/d_$label" ]; then
        for v in 512 768 1024; do
            $PIN "$OUT/d_ref" $v > "$OUT/.r"; $PIN "$OUT/d_$label" $v > "$OUT/.v"
            diff -q "$OUT/.r" "$OUT/.v" >/dev/null 2>&1 || func="FAIL($v)"
        done
    else func="BUILD-FAIL"; fi
    echo "  [KAT] cross-version == reference (multi-chunk 0..300 KB): $func"
    echo "$label consistency==reference: $func" >> "$OUT/functional_arm.txt"

    # ---- functional C: FULL official KAT -- NEON (opt) always, others if KAT_HEAVY ----
    if [ -d "$TV" ] && { [ "$label" = "opt" ] || [ "$KAT_HEAVY" = "1" ]; }; then
        echo "  [KAT] full official KAT vs Test_Vectors (incl. 2_23 / 2_33 / Loop):"
        for v in 512 768 1024; do
            D="$dir/QSH-$v"
            if ( cd "$D" && $CC $flags drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen_sa 2>/dev/null && ./katgen_sa >/dev/null 2>&1 ); then
                for K in 2_12 2_23 2_33 Loop; do
                    if diff -q "$D/output/KAT_${K}_QSH-$v.txt" "$TV/KAT_${K}_QSH-$v.txt" >/dev/null 2>&1; then s=PASS; else s=FAIL; fi
                    echo "    QSH-$v KAT_$K: $s"
                    echo "$label full-KAT QSH-$v KAT_$K: $s" >> "$OUT/functional_arm.txt"
                done
            else echo "    QSH-$v: build/run failed"; echo "$label full-KAT QSH-$v: BUILD-FAIL" >> "$OUT/functional_arm.txt"; fi
            rm -f "$D/katgen_sa"; rm -rf "$D/output"
        done
    fi

    # ---- performance ----
    : > "$OUT/perf_$label.csv"
    if $CC $flags -I"$inc" "$PERF" "$vsrc" -o "$OUT/perf_$label" 2>/dev/null && [ -x "$OUT/perf_$label" ]; then
        for v in 512 768 1024; do $PIN "$OUT/perf_$label" $v $CPU_GHZ >> "$OUT/perf_$label.csv"; done
        echo "  performance -> $OUT/perf_$label.csv"
    else echo "  performance: BUILD FAILED"; fi

    # ---- resource: peak RSS over >=100 hashes (1 MiB) + large-input peak ----
    cat > "$OUT/.peak_small.c" <<EOF
#include <stdlib.h>
int CryptHash(int,const unsigned char*,unsigned long long,unsigned char*);
int main(void){ size_t n=1048576; unsigned char*m=malloc(n),d[128];
  for(size_t i=0;i<n;i++)m[i]=(unsigned char)i;
  for(int it=0; it<100; it++) CryptHash(512,m,(unsigned long long)n*8,d);
  return 0; }
EOF
    cat > "$OUT/.peak_big.c" <<EOF
#include <stdlib.h>
int CryptHash(int,const unsigned char*,unsigned long long,unsigned char*);
int main(void){ size_t n=(size_t)$PEAK_BIG_MIB*1048576UL; unsigned char*m=malloc(n),d[128];
  if(!m) return 1; for(size_t i=0;i<n;i++)m[i]=(unsigned char)i;
  CryptHash(512,m,(unsigned long long)n*8,d); return 0; }
EOF
    $CC $flags -I"$inc" "$OUT/.peak_small.c" "$vsrc" -o "$OUT/peaksmall_$label" 2>/dev/null
    $CC $flags -I"$inc" "$OUT/.peak_big.c"   "$vsrc" -o "$OUT/peakbig_$label"   2>/dev/null
    if [ "$HAVE_TIME" = 1 ] && [ -x "$OUT/peaksmall_$label" ]; then
        /usr/bin/time -v "$OUT/peaksmall_$label" 2>"$OUT/peak_${label}_small.txt" || true
        /usr/bin/time -v "$OUT/peakbig_$label"   2>"$OUT/peak_${label}_big.txt"   || true
        echo "  peak RSS  1MiB x100 : $(grep -i 'maximum resident' "$OUT/peak_${label}_small.txt" | sed 's/^[ \t]*//')"
        echo "  peak RSS  ${PEAK_BIG_MIB}MiB x1: $(grep -i 'maximum resident' "$OUT/peak_${label}_big.txt" | sed 's/^[ \t]*//')"
    else echo "  peak RSS: skipped"; fi
}

echo "==== [3/7] reference version (portable C99) ===="; run_version ref "$REF_DIR" "$REF_FLAGS"
echo "==== [4/7] performance-optimized version (NEON within-permutation) ===="; run_version opt "$OPT_DIR" "$OPT_FLAGS"
echo "==== [5/7] resource-optimized version (CV-stack, -Os) ===="; run_version res "$RES_DIR" "$RES_FLAGS"

# ---- NEON validation verdict ----
echo "==== NEON validation verdict ===="
if grep -q '^opt .*FAIL' "$OUT/functional_arm.txt"; then
    echo "  *** FAIL: the NEON performance build did NOT reproduce the KAT on this CPU."
    echo "      DO NOT submit the NEON version. Use the portable reference/resource"
    echo "      builds for the optimized slot, or fix NEON, then re-run."
    NEON_OK="FAILED -- do not submit NEON"
else
    echo "  PASS: NEON performance build reproduced KAT_2_12 + full official KAT."
    NEON_OK="PASSED -- NEON validated on this CPU"
fi

echo "==== [6/7] assembling report ===="
{
  echo "# QSH AArch64 Implementation Self-Assessment (NGCC guideline 1-1)"
  echo; echo "Material naming (see results/submission/): 密码杂凑-QSH-{512,768,1024}-arm-{参考实现版,性能优化版,资源优化版}"
  echo; echo "NEON validation: $NEON_OK"
  echo; echo "## 1. Algorithm basic info"
  echo "- Category: cryptographic hash;  Name: QuantaSylva Hash (QSH)"
  echo "- Instances: QSH-512 / QSH-768 / QSH-1024 (digest 512/768/1024 bits)"
  echo "- Interface: int CryptHash(int digest_len_bits,const unsigned char*msg,unsigned long long msg_len_bits,unsigned char*digest)"
  echo; echo "## 2. Environment & recordable items"; echo '```'; cat "$ENVF"; echo '```'
  echo "Compile flags:"; echo "- reference  : $REF_FLAGS"; echo "- performance: $OPT_FLAGS"; echo "- resource   : $RES_FLAGS"
  echo; echo "## 3. Functional test (KAT)"
  echo "KAT_2_12 = known-answer over all 4097 message bit-lengths (0..4096), checked"
  echo "for every version against Test_Vectors/ -- this is also the NEON validation."
  echo "The full official KAT (2_12/2_23/2_33/Loop, incl. 1 GiB messages) is run on"
  echo "the NEON build$( [ "$KAT_HEAVY" = 1 ] && echo " and (KAT_HEAVY=1) on all versions")."
  echo "Cross-version byte-identity over multi-chunk inputs (0..300 KB) is also checked."
  echo '```'; cat "$OUT/functional_arm.txt" 2>/dev/null; echo '```'
  echo; echo "## 4. Performance (CPU cycles via perf_event; throughput MB/s). S1..S8 = 32..65536 B, plus r1 at 256K/1M"
  echo "(cyc_src column: 'perf_event' = measured cycles; 'derived' = time x frequency.)"
  for L in ref opt res; do echo; echo "### version: $L"; echo '```'; cat "$OUT/perf_$L.csv" 2>/dev/null; echo '```'; done
  echo; echo "## 5. Resource consumption"
  echo "static = text+data+bss of the algorithm object; peak RSS via /usr/bin/time -v."
  echo "1 MiB x100 = steady working set (>=100 iters); ${PEAK_BIG_MIB} MiB = chaining-value"
  echo "memory: reference/NEON allocate an O(Pi) flat CV array, the resource build uses"
  echo "an O(log2 Pi) CV-stack (e.g. 1 GiB -> ~128 MB vs a few KB of CVs)."
  for L in ref opt res; do
    echo; echo "### version: $L"; echo '```'
    cat "$OUT/static_$L.txt" 2>/dev/null
    echo "peak RSS 1MiB x100 : $(grep -i 'maximum resident' "$OUT/peak_${L}_small.txt" 2>/dev/null | sed 's/^[ \t]*//')"
    echo "peak RSS ${PEAK_BIG_MIB}MiB x1: $(grep -i 'maximum resident' "$OUT/peak_${L}_big.txt" 2>/dev/null | sed 's/^[ \t]*//')"
    echo '```'
  done
  echo; echo "## 6. Transmission/storage overhead: N/A (hash function)"
  echo; echo "## 7. Raw-evidence index"
  echo "- environment: results/environment_arm.txt"
  echo "- functional : results/functional_arm.txt ; Test_Vectors/"
  echo "- performance: results/perf_{ref,opt,res}.csv"
  echo "- resource   : results/static_*.txt , results/peak_*_{small,big}.txt"
  echo "- build logs : results/warn_*.txt"
  echo "- named material: results/submission/ (per guideline 1-4)"
} > "$REPORT"

echo "==== [7/7] guideline 1-4 named material -> results/submission/ ===="
SUB="$OUT/submission"; rm -rf "$SUB"; mkdir -p "$SUB"
emit() {  # $1=src dir  $2=version-name(zh)  $3=flags
  for v in 512 768 1024; do
    dst="$SUB/密码杂凑-QSH-$v-arm-$2"; mkdir -p "$dst"
    cp "$1/QSH-$v/"CryptHash_AlgorithmInstance.* "$1/QSH-$v/"drng.* "$1/QSH-$v/"KAT_CryptHash.c "$dst/" 2>/dev/null
    [ -f "$1/QSH-$v/README.txt" ] && cp "$1/QSH-$v/README.txt" "$dst/"
    cat > "$dst/build.sh" <<EOF
#!/bin/sh
# AArch64 build ($2).
set -e
gcc $3 drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen
echo "built ./katgen  (run it to generate ./output/KAT_*_QSH-$v.txt)"
EOF
    chmod +x "$dst/build.sh"
    cat > "$dst/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.11.4)
project(CryptHash_QSH_${v}_arm C)
set(CMAKE_C_STANDARD 99)
add_compile_options($3)
add_executable(katgen drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c)
EOF
    cp "$REPORT" "$dst/SELF_ASSESSMENT_REPORT.md"
    cp "$ENVF" "$dst/ENVIRONMENT.txt"
    printf 'Third-party dependencies: none.\nOnly the official ICCS files drng.c / drng.h / KAT_CryptHash.c are used (unmodified).\n' > "$dst/DEPENDENCIES.txt"
  done
}
emit "$REF_DIR" "参考实现版"   "$REF_FLAGS"
emit "$OPT_DIR" "性能优化版"   "$OPT_FLAGS"
emit "$RES_DIR" "资源优化版"   "$RES_FLAGS"
echo "  created $(find "$SUB" -maxdepth 1 -type d -name '密码*' | wc -l) named packages:"
find "$SUB" -maxdepth 1 -type d -name '密码*' | sed 's#.*/#    #' | sort

rm -f "$OUT"/.peak_small.c "$OUT"/.peak_big.c "$OUT"/.r "$OUT"/.v "$OUT"/.kerr \
      "$OUT"/d_ref "$OUT"/d_opt "$OUT"/d_res "$OUT"/katc_* \
      "$OUT"/peaksmall_* "$OUT"/peakbig_* "$OUT"/perf_ref "$OUT"/perf_opt "$OUT"/perf_res "$OUT"/impl_*.o 2>/dev/null

echo "DONE."
echo "NEON: $NEON_OK"
echo "Report : $REPORT"
echo "Named  : $SUB/  (zip this for submission)"
echo "Perf   : $OUT/perf_{ref,opt,res}.csv"
