#!/bin/sh
# =============================================================================
# QSH x86 self-assessment (NGCC guideline 1-2). Run on a quiet single-socket
# Linux x86-64 box. For the three required versions (reference / performance-
# optimized / resource-optimized) and the three instances (QSH-512/768/1024):
#   - environment + recordable items (compiler flags, ISA, deps, RNG method)
#   - FUNCTIONAL (KAT): known-answer check of KAT_2_12 (4097 vectors = every
#     message bit-length 0..4096) against Test_Vectors/; full official KAT
#     (2_12/2_23/2_33/Loop) on the optimized build (fast); cross-version
#     byte-identity over multi-chunk inputs.
#   - PERFORMANCE: cycles (rdtsc/TSC) + throughput (MB/s) at S1..S8 (+ long r1)
#   - RESOURCE: static memory (size); peak RSS over >=100 hashes (1 MiB);
#     and a large-input (default 64 MiB) peak that exposes the resource
#     version's O(log Pi) chaining-value memory vs the O(Pi) flat array.
#   - writes results/Report_x86_selfassessment.md AND results/submission/
#     with the materials renamed per guideline 1-4.
#
# Usage:
#   nohup stdbuf -oL -eL sh SelfAssessment/selfassess_x86.sh > ~/selfassess.log 2>&1 &
#   tail -f ~/selfassess.log
# Env toggles:
#   KAT_HEAVY=1     run the FULL official KAT (incl. 1 GiB 2_33) for ALL three
#                   versions, not just the optimized one (slow on the scalar
#                   reference/resource builds: tens of minutes).
#   PEAK_BIG_MIB=N  large-input peak-RSS size in MiB (default 64).
#   CC=gcc-13       compiler override (e.g. Homebrew gcc on macOS).
# =============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/SelfAssessment/results"; mkdir -p "$OUT"
REPORT="$OUT/Report_x86_selfassessment.md"
ENVF="$OUT/environment.txt"
TV="$ROOT/Test_Vectors"
CORE=0
KAT_HEAVY="${KAT_HEAVY:-0}"
PEAK_BIG_MIB="${PEAK_BIG_MIB:-64}"

REF_FLAGS="-std=c99 -Wpedantic -Wall -Wextra -O2"
# -mtune=native measured ~3-7% SLOWER than plain -O3 on the test CPU, so it's omitted.
OPT_FLAGS="-O3 -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
# NOTE: the resource build uses -O3, not -Os.  Its "resource" optimization is the
# O(log2 Pi) chaining-value stack (algorithmic, memory), NOT code size.  -Os here
# pathologically spills the wide SIMD permutation state (w=64 = 16 YMM live ->
# ~115 cyc/byte vs 13 at -O3), so -O3 gives full speed AND the O(log Pi) memory.
RES_FLAGS="-O3 -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
REF_DIR="$ROOT/Implementations/Reference_Implementation"
OPT_DIR="$ROOT/Implementations/Optimized_Implementation_WithinPerm"
RES_DIR="$ROOT/Implementations/Resource_Optimized_Implementation"

CC="${CC:-gcc}"

echo "==== [0/7] prerequisites ===="
command -v "$CC" >/dev/null 2>&1 || { echo "ERROR: compiler '$CC' not found.
  sudo apt-get update && sudo apt-get install -y build-essential binutils time util-linux cmake"; exit 1; }
HAVE_SIZE=0; command -v size >/dev/null 2>&1 && HAVE_SIZE=1 || echo "  note: 'size' (binutils) missing -> static-memory step skipped"
HAVE_TIME=0; [ -x /usr/bin/time ] && HAVE_TIME=1 || echo "  note: /usr/bin/time missing -> peak-RSS step skipped"
PIN=""; command -v taskset >/dev/null 2>&1 && PIN="taskset -c $CORE"
[ -d "$TV" ] || echo "  WARNING: $TV not found -> KAT functional check will be skipped"
echo "  compiler : $($CC --version | head -1)"
echo "  KAT_HEAVY=$KAT_HEAVY  PEAK_BIG_MIB=$PEAK_BIG_MIB"

echo "==== [1/7] frequency lock (best effort; needs sudo) ===="
lock_freq() {
    if [ -w /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo && echo "  turbo disabled (intel_pstate)"
    elif [ -w /sys/devices/system/cpu/cpufreq/boost ]; then
        echo 0 > /sys/devices/system/cpu/cpufreq/boost && echo "  boost disabled"
    else echo "  (no writable turbo control -- cloud VM? rdtsc/TSC cycles are turbo-independent anyway)"; fi
    command -v cpupower >/dev/null 2>&1 && cpupower frequency-set -g performance >/dev/null 2>&1 && echo "  governor=performance"
}
lock_freq 2>/dev/null || echo "  freq-lock skipped (no permission)"

echo "==== [2/7] environment ===="
{
  echo "date            : $(date -u)"
  echo "uname           : $(uname -srm)"
  echo "os-release      : $(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME")"
  echo "cpu             : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "cpu-MHz(cur)    : $(grep -m1 'cpu MHz' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "gcc             : $($CC --version | head -1)"
  echo "cmake           : $(cmake --version 2>/dev/null | head -1)"
  echo "governor        : $(cat /sys/devices/system/cpu/cpu$CORE/cpufreq/scaling_governor 2>/dev/null)"
  echo "no_turbo        : $(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null)"
  echo "pinned core     : $CORE"
  echo "third-party deps: none (only the official ICCS drng.c / KAT_CryptHash.c, unmodified)"
  echo "RNG method      : DRNG from API_CryptHash (SM3 Hash-DRBG); KAT messages seeded per official harness"
  echo "ISA / opt       : x86-64 + AVX2; within-permutation SIMD (perf), SIMD core + O(log Pi) CV-stack at -O3 (resource)"
} | tee "$ENVF"

DRV="$ROOT/Implementations/validate_driver.c"
PERF="$ROOT/SelfAssessment/perf_cycles_x86.c"
KATC="$ROOT/SelfAssessment/kat_check.c"
: > "$OUT/functional.txt"

run_version() {  # $1=label  $2=dir  $3=flags
    label="$1"; dir="$2"; flags="$3"; vsrc="$dir/QSH-512/CryptHash_AlgorithmInstance.c"; inc="$dir/QSH-512"
    echo "==== version: $label  ($flags) ===="
    # static-memory object is built WITHOUT -flto so 'size' reports real machine
    # code (an -flto object holds GIMPLE bytecode, not text/data/bss).
    size_flags=$(echo "$flags" | sed 's/-flto//g')
    if ! $CC $size_flags -I"$inc" -c "$vsrc" -o "$OUT/impl_$label.o" 2>"$OUT/warn_$label.txt"; then
        echo "  BUILD FAILED:"; sed 's/^/    /' "$OUT/warn_$label.txt"; echo "$label BUILD-FAIL" >> "$OUT/functional.txt"; return 1
    fi
    echo "  build warnings: $(grep -c warning "$OUT/warn_$label.txt")"

    # ---- static memory (text+data+bss of the algorithm code) ----
    if [ "$HAVE_SIZE" = 1 ]; then
        echo "  static memory (size $label, no -flto):"; size "$OUT/impl_$label.o" | tee "$OUT/static_$label.txt" | sed 's/^/    /'
    else echo "  static memory: skipped" | tee "$OUT/static_$label.txt"; fi

    # ---- functional A: KAT_2_12 known-answer (all 3 instances; one binary dispatches by Dst_Len) ----
    echo "  [KAT] KAT_2_12 known-answer:"
    if [ -d "$TV" ] && $CC $flags -I"$inc" "$KATC" "$vsrc" -o "$OUT/katc_$label" 2>/dev/null; then
        for v in 512 768 1024; do
            r=$($PIN "$OUT/katc_$label" "$TV/KAT_2_12_QSH-$v.txt" 2>>"$OUT/.kerr"); st=$?
            echo "    QSH-$v: $(echo "$r" | sed 's#.*/##')  $( [ $st -eq 0 ] && echo PASS || echo FAIL )"
            echo "$label KAT_2_12 QSH-$v: $r [$( [ $st -eq 0 ] && echo PASS || echo FAIL )]" >> "$OUT/functional.txt"
        done
    else echo "    skipped (no Test_Vectors or build failed)"; echo "$label KAT_2_12: skipped" >> "$OUT/functional.txt"; fi

    # ---- functional B: cross-version byte-identity vs reference over multi-chunk inputs ----
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
    echo "$label consistency==reference: $func" >> "$OUT/functional.txt"

    # ---- functional C: FULL official KAT (2_12/2_23/2_33/Loop) -- optimized always, others if KAT_HEAVY ----
    if [ -d "$TV" ] && { [ "$label" = "opt" ] || [ "$KAT_HEAVY" = "1" ]; }; then
        echo "  [KAT] full official KAT vs Test_Vectors (incl. 2_23 / 2_33 / Loop):"
        for v in 512 768 1024; do
            D="$dir/QSH-$v"
            if ( cd "$D" && $CC $flags drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen_sa 2>/dev/null && ./katgen_sa >/dev/null 2>&1 ); then
                for K in 2_12 2_23 2_33 Loop; do
                    if diff -q "$D/output/KAT_${K}_QSH-$v.txt" "$TV/KAT_${K}_QSH-$v.txt" >/dev/null 2>&1; then s=PASS; else s=FAIL; fi
                    echo "    QSH-$v KAT_$K: $s"
                    echo "$label full-KAT QSH-$v KAT_$K: $s" >> "$OUT/functional.txt"
                done
            else echo "    QSH-$v: build/run failed"; echo "$label full-KAT QSH-$v: BUILD-FAIL" >> "$OUT/functional.txt"; fi
            rm -f "$D/katgen_sa"; rm -rf "$D/output"
        done
    fi

    # ---- performance ----
    : > "$OUT/perf_$label.csv"
    if $CC $flags -I"$inc" "$PERF" "$vsrc" -o "$OUT/perf_$label" 2>/dev/null && [ -x "$OUT/perf_$label" ]; then
        for v in 512 768 1024; do $PIN "$OUT/perf_$label" $v >> "$OUT/perf_$label.csv"; done
        echo "  performance -> $OUT/perf_$label.csv"
    else echo "  performance: BUILD FAILED"; fi

    # ---- resource: peak RSS over >=100 hashes (1 MiB) + large-input peak (CV-memory scaling) ----
    cat > "$OUT/.peak_small.c" <<EOF
#include <stdlib.h>
int CryptHash(int,const unsigned char*,unsigned long long,unsigned char*);
int main(void){ size_t n=1048576; unsigned char*m=malloc(n),d[128];
  for(size_t i=0;i<n;i++)m[i]=(unsigned char)i;
  for(int it=0; it<100; it++) CryptHash(512,m,(unsigned long long)n*8,d);   /* >=100 iterations */
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

echo "==== [3/7] reference version ===="; run_version ref "$REF_DIR" "$REF_FLAGS"
echo "==== [4/7] performance-optimized version (within-permutation AVX2) ===="; run_version opt "$OPT_DIR" "$OPT_FLAGS"
echo "==== [5/7] resource-optimized version (CV-stack, -Os) ===="; run_version res "$RES_DIR" "$RES_FLAGS"

echo "==== [6/7] assembling report ===="
{
  echo "# QSH x86 Implementation Self-Assessment (NGCC guideline 1-2)"
  echo; echo "Material naming (see results/submission/): 密码杂凑-QSH-{512,768,1024}-x86-{参考实现版,性能优化版,资源优化版}"
  echo; echo "## 1. Algorithm basic info"
  echo "- Category: cryptographic hash;  Name: QuantaSylva Hash (QSH)"
  echo "- Instances: QSH-512 / QSH-768 / QSH-1024 (digest 512/768/1024 bits)"
  echo "- Interface: int CryptHash(int digest_len_bits,const unsigned char*msg,unsigned long long msg_len_bits,unsigned char*digest)"
  echo; echo "## 2. Environment & recordable items"; echo '```'; cat "$ENVF"; echo '```'
  echo "Compile flags:"; echo "- reference  : $REF_FLAGS"; echo "- performance: $OPT_FLAGS"; echo "- resource   : $RES_FLAGS"
  echo; echo "## 3. Functional test (KAT)"
  echo "KAT_2_12 = known-answer over all 4097 message bit-lengths (0..4096, every"
  echo "padding/sub-byte edge case), checked for every version against Test_Vectors/."
  echo "The full official KAT (2_12/2_23/2_33/Loop, incl. 1 GiB messages) is run on"
  echo "the optimized build$( [ "$KAT_HEAVY" = 1 ] && echo " and (KAT_HEAVY=1) on all versions")."
  echo "Cross-version byte-identity over multi-chunk inputs (0..300 KB) covers the"
  echo "tree/streaming paths for the reference and resource builds."
  echo '```'; cat "$OUT/functional.txt" 2>/dev/null; echo '```'
  echo; echo "## 4. Performance (cycles via rdtsc/TSC; throughput MB/s). S1..S8 = 32..65536 B, plus r1 at 256K/1M"
  for L in ref opt res; do echo; echo "### version: $L"; echo '```'; cat "$OUT/perf_$L.csv" 2>/dev/null; echo '```'; done
  echo; echo "## 5. Resource consumption"
  echo "static = text+data+bss of the algorithm object; peak RSS measured with"
  echo "/usr/bin/time -v.  The 1 MiB x100 figure is the steady working set (>=100"
  echo "iterations); the ${PEAK_BIG_MIB} MiB figure exposes chaining-value memory:"
  echo "reference/optimized allocate an O(Pi) flat CV array (~Pi*256 B), the resource"
  echo "build uses an O(log2 Pi) CV-stack (e.g. 1 GiB -> ~128 MB vs a few KB of CVs)."
  for L in ref opt res; do
    echo; echo "### version: $L"; echo '```'
    cat "$OUT/static_$L.txt" 2>/dev/null
    echo "peak RSS 1MiB x100 : $(grep -i 'maximum resident' "$OUT/peak_${L}_small.txt" 2>/dev/null | sed 's/^[ \t]*//')"
    echo "peak RSS ${PEAK_BIG_MIB}MiB x1: $(grep -i 'maximum resident' "$OUT/peak_${L}_big.txt" 2>/dev/null | sed 's/^[ \t]*//')"
    echo '```'
  done
  echo; echo "## 6. Transmission/storage overhead: N/A (hash function)"
  echo; echo "## 7. Raw-evidence index"
  echo "- environment: results/environment.txt"
  echo "- functional : results/functional.txt ; Test_Vectors/ (KAT_2_12/2_23/2_33/Loop x QSH-512/768/1024)"
  echo "- performance: results/perf_{ref,opt,res}.csv"
  echo "- resource   : results/static_*.txt , results/peak_*_{small,big}.txt"
  echo "- build logs : results/warn_*.txt"
  echo "- named material: results/submission/ (per guideline 1-4)"
} > "$REPORT"

echo "==== [7/7] guideline 1-4 named material -> results/submission/ ===="
SUB="$OUT/submission"; rm -rf "$SUB"; mkdir -p "$SUB"
emit() {  # $1=src dir  $2=version-name(zh)
  for v in 512 768 1024; do
    dst="$SUB/密码杂凑-QSH-$v-x86-$2"; mkdir -p "$dst"
    cp "$1/QSH-$v/"CryptHash_AlgorithmInstance.* "$1/QSH-$v/"drng.* "$1/QSH-$v/"KAT_CryptHash.c \
       "$1/QSH-$v/"build.sh "$1/QSH-$v/"CMakeLists.txt "$dst/" 2>/dev/null
    [ -f "$1/QSH-$v/README.txt" ] && cp "$1/QSH-$v/README.txt" "$dst/"
    cp "$REPORT" "$dst/SELF_ASSESSMENT_REPORT.md"
    cp "$ENVF" "$dst/ENVIRONMENT.txt"
    printf 'Third-party dependencies: none.\nOnly the official ICCS files drng.c / drng.h / KAT_CryptHash.c are used (unmodified).\n' > "$dst/DEPENDENCIES.txt"
  done
}
emit "$REF_DIR" "参考实现版"
emit "$OPT_DIR" "性能优化版"
emit "$RES_DIR" "资源优化版"
echo "  created $(find "$SUB" -maxdepth 1 -type d | grep -c 密码) named packages:"
find "$SUB" -maxdepth 1 -type d -name '密码*' | sed 's#.*/#    #' | sort

# tidy scratch
rm -f "$OUT"/.peak_small.c "$OUT"/.peak_big.c "$OUT"/.r "$OUT"/.v "$OUT"/.kerr \
      "$OUT"/d_ref "$OUT"/d_ref* "$OUT"/d_opt "$OUT"/d_res "$OUT"/katc_* \
      "$OUT"/peaksmall_* "$OUT"/peakbig_* "$OUT"/perf_ref "$OUT"/perf_opt "$OUT"/perf_res "$OUT"/impl_*.o 2>/dev/null

echo "DONE."
echo "Report : $REPORT"
echo "Named  : $SUB/  (zip this for submission)"
echo "Perf   : $OUT/perf_{ref,opt,res}.csv"
