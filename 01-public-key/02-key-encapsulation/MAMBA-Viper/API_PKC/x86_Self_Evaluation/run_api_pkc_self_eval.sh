#!/usr/bin/env bash
set -u -o pipefail
RUNS=1000; WARMUP=100; DO_BENCH=1
while [ $# -gt 0 ]; do case "$1" in --runs) RUNS="$2"; shift 2;; --warmup) WARMUP="$2"; shift 2;; --no-bench) DO_BENCH=0; shift;; -h|--help) echo "Usage: $0 [--runs N] [--warmup N] [--no-bench]"; exit 0;; *) echo "Unknown option $1"; exit 2;; esac; done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; cd "$REPO_ROOT" || exit 2
TS="$(date +%Y%m%d-%H%M%S)"; RES="$REPO_ROOT/x86_Self_Evaluation/results/$TS"; mkdir -p "$RES/bin" "$RES/kats/reference" "$RES/kats/optimized"
FAIL=(); INSTANCES=(MAMBA-Viper-128 MAMBA-Viper-192 MAMBA-Viper-256 MAMBA-Viper-384 MAMBA-Viper-512)
levels(){ echo "${1##*-}"; }
log(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$RES/summary.md"; }
run_capture(){ local name="$1"; shift; { echo "# $*"; "$@"; } >>"$RES/$name" 2>&1; local rc=$?; [ $rc -eq 0 ] || FAIL+=("$name: $* (rc=$rc)"); return $rc; }
[ -d API_PKC ] || { echo "API_PKC missing"; exit 2; }
{
 echo "date: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"; echo "uname: $(uname -a)"; echo; command -v lscpu >/dev/null && lscpu || true; echo; gcc --version || true; echo; make --version || true; echo; command -v cmake >/dev/null && cmake --version || echo "cmake: not found"; echo; echo "/proc/cpuinfo summary:"; awk -F: '/model name|flags/ {gsub(/^ /,"",$2); print $1 ":" $2; if (++c>=2) exit}' /proc/cpuinfo 2>/dev/null || true;
} > "$RES/environment.txt" 2>&1
{ echo "branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"; echo "HEAD: $(git rev-parse HEAD 2>/dev/null)"; echo "status:"; git status --short; } > "$RES/git_status.txt"
AVX2=0; (lscpu 2>/dev/null | rg -qw avx2 || rg -qw avx2 /proc/cpuinfo) && AVX2=1
: > "$RES/benchmark.csv"
: > "$RES/sizes.csv"
: > "$RES/kat_consistency.log"; : > "$RES/api_check.log"; : > "$RES/benchmark_reference.log"; : > "$RES/benchmark_optimized.log"; : > "$RES/build_kat_reference.log"; : > "$RES/build_kat_optimized.log"
get_src(){ awk '/^SRC[[:space:]]*=/{sub(/^SRC[[:space:]]*=[[:space:]]*/,""); print}' "$1/Makefile"; }
get_var(){ local macro="$1" dir="$2" exp=""; case "$macro" in CRYPTO_PUBLICKEYBYTES) exp=EXPECTED_PK;; CRYPTO_SECRETKEYBYTES) exp=EXPECTED_SK;; CRYPTO_BYTES) exp=EXPECTED_SS;; CRYPTO_CIPHERTEXTBYTES) exp=EXPECTED_CT;; esac; awk -v n="$exp" '$1=="#define" && $2==n {gsub(/ULL/,"",$3); print $3; exit}' "$dir/KEM_AlgorithmInstance.c"; }
compile_tool(){ local dir="$1" impl="$2" inst="$3" toolsrc="$4" out="$5"; local src; src="$(get_src "$dir" | sed 's/KAT_KEM\.c//g')"; local pk sk ss ct lvl; pk=$(get_var CRYPTO_PUBLICKEYBYTES "$dir"); sk=$(get_var CRYPTO_SECRETKEYBYTES "$dir"); ss=$(get_var CRYPTO_BYTES "$dir"); ct=$(get_var CRYPTO_CIPHERTEXTBYTES "$dir"); lvl=$(levels "$inst"); (cd "$dir" && gcc $(awk '/^CPPFLAGS/{sub(/^CPPFLAGS[[:space:]]*\?=[[:space:]]*/,""); print}' Makefile) $(awk '/^CFLAGS/{sub(/^CFLAGS[[:space:]]*\?=[[:space:]]*/,""); print}' Makefile) -DEXPECTED_PK="$pk" -DEXPECTED_SK="$sk" -DEXPECTED_SS="$ss" -DEXPECTED_CT="$ct" -DINSTANCE_NAME=\"$inst\" -DIMPLEMENTATION_NAME=\"$impl\" -I. -o "$out" $src "$REPO_ROOT/$toolsrc" -lm); }
for impl in Reference Optimized; do
  base="API_PKC/Implementations/${impl}_Implementation"; logname="build_kat_${impl,,}.log"
  if [ "$impl" = Optimized ] && [ "$AVX2" -ne 1 ]; then echo "Optimized skipped: CPU lacks AVX2" | tee -a "$RES/$logname"; continue; fi
  for inst in "${INSTANCES[@]}"; do dir="$base/$inst"; log "KAT $impl $inst"; { echo "## $impl $inst"; (cd "$dir" && make clean && make && make kat); } >>"$RES/$logname" 2>&1; rc=$?; if [ $rc -ne 0 ]; then FAIL+=("KAT $impl $inst rc=$rc"); continue; fi; cp "$dir/output/KAT_KEM_${inst}.txt" "$RES/kats/${impl,,}/" 2>/dev/null || true; (cd "$dir" && make clean) >>"$RES/$logname" 2>&1 || true
  done
done
for inst in "${INSTANCES[@]}"; do off="API_PKC/Test_Vectors/KAT_KEM_${inst}.txt"; if [ ! -f "$off" ]; then echo "MISSING official $off" >>"$RES/kat_consistency.log"; FAIL+=("missing $off"); else cmp -s "$off" "$RES/kats/reference/KAT_KEM_${inst}.txt" && echo "PASS official vs reference $inst" >>"$RES/kat_consistency.log" || { echo "FAIL official vs reference $inst" >>"$RES/kat_consistency.log"; FAIL+=("KAT official/reference $inst"); }; fi; if [ "$AVX2" -eq 1 ]; then cmp -s "$RES/kats/reference/KAT_KEM_${inst}.txt" "$RES/kats/optimized/KAT_KEM_${inst}.txt" && echo "PASS reference vs optimized $inst" >>"$RES/kat_consistency.log" || { echo "FAIL reference vs optimized $inst" >>"$RES/kat_consistency.log"; FAIL+=("KAT ref/opt $inst"); }; fi; done
for impl in Reference Optimized; do
  [ "$impl" = Optimized ] && [ "$AVX2" -ne 1 ] && { echo "Optimized api/bench SKIP: no AVX2" >>"$RES/api_check.log"; continue; }
  for inst in "${INSTANCES[@]}"; do dir="API_PKC/Implementations/${impl}_Implementation/$inst"; lvl=$(levels "$inst"); pk=$(get_var CRYPTO_PUBLICKEYBYTES "$dir"); sk=$(get_var CRYPTO_SECRETKEYBYTES "$dir"); ss=$(get_var CRYPTO_BYTES "$dir"); ct=$(get_var CRYPTO_CIPHERTEXTBYTES "$dir"); echo "$impl,$inst,$lvl,$pk,$sk,$ss,$ct,PASS" >>"$RES/sizes.csv"; api_bin="$RES/bin/api_check_${impl}_${inst}"; if compile_tool "$dir" "$impl" "$inst" "API_PKC/Internal_Tests/NGCC_API/api_check.c" "$api_bin" >>"$RES/api_check.log" 2>&1 && "$api_bin" >>"$RES/api_check.log" 2>&1; then echo "PASS api_check $impl $inst" >>"$RES/api_check.log"; else FAIL+=("api_check $impl $inst"); fi; if [ "$DO_BENCH" -eq 1 ]; then bench_bin="$RES/bin/benchmark_${impl}_${inst}"; tmp_log="$RES/bench_${impl}_${inst}.tmp"; if compile_tool "$dir" "$impl" "$inst" "x86_Self_Evaluation/benchmark_kem_api.c" "$bench_bin" >>"$RES/benchmark_${impl,,}.log" 2>&1 && "$bench_bin" "$RUNS" "$WARMUP" >"$tmp_log" 2>&1; then cat "$tmp_log" >>"$RES/benchmark_${impl,,}.log"; awk -F, -v ts="$TS" '/^RESULT,/ {printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", ts,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19}' "$tmp_log" >> "$RES/benchmark.csv"; rm -f "$tmp_log"; else cat "$tmp_log" >>"$RES/benchmark_${impl,,}.log" 2>/dev/null || true; rm -f "$tmp_log"; FAIL+=("benchmark $impl $inst"); fi; fi; done
done
{ echo "Forbidden dependency scan"; rg -n "RAND_bytes|OpenSSL|/dev/urandom|getrandom|arc4random" API_PKC x86_Self_Evaluation/benchmark_kem_api.c || true; } > "$RES/dependency_scan.log"
if rg -n "RAND_bytes|OpenSSL|/dev/urandom|getrandom|arc4random" API_PKC x86_Self_Evaluation/benchmark_kem_api.c >/dev/null; then FAIL+=("forbidden dependency matches"); fi
{ echo "Build artifact scan"; find API_PKC x86_Self_Evaluation -path 'x86_Self_Evaluation/results' -prune -o \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name '*.dylib' -o -name '*.dll' -o -name '*.exe' -o -name '*.pdb' -o -name KAT_KEM_API_PKC -o -name api_check -o -name benchmark_kem_api \) -print; } > "$RES/artifact_scan.log"
if tail -n +2 "$RES/artifact_scan.log" | read x; then FAIL+=("build artifacts remain"); fi
{ echo "Package check"; for f in environment.txt git_status.txt build_kat_reference.log build_kat_optimized.log kat_consistency.log api_check.log benchmark_reference.log benchmark_optimized.log benchmark.csv sizes.csv dependency_scan.log artifact_scan.log package_check.log summary.md; do [ -e "$RES/$f" ] && echo "PASS $f" || echo "FAIL $f"; done; } > "$RES/package_check.log"
{
 echo "# x86 Self-Evaluation Summary"; echo; echo "Result directory: $RES"; echo "Runs: $RUNS"; echo "Warmup: $WARMUP"; echo "AVX2: $([ $AVX2 -eq 1 ] && echo yes || echo no)"; echo; echo "## Status"; if [ ${#FAIL[@]} -eq 0 ]; then echo "PASS"; else printf 'FAIL: %d issue(s)\n' "${#FAIL[@]}"; printf -- '- %s\n' "${FAIL[@]}"; fi; echo; echo "Implicit rejection: see api_check.log and benchmark logs";
} >> "$RES/summary.md"
{
 echo '% Environment summary block'; echo '\begin{verbatim}'; sed -n '1,25p' "$RES/environment.txt"; echo '\end{verbatim}';
 echo '% Reference performance table'; echo '\begin{tabular}{llrrrr}'; echo 'Instance & Operation & Mean & Median & Min & Max \\'; awk -F, '$2=="Reference"{printf "%s & %s & %s & %s & %s & %s \\\\\n",$3,$5,$8,$9,$10,$11}' "$RES/benchmark.csv"; echo '\end{tabular}';
 echo '% Optimized performance table'; echo '\begin{tabular}{llrrrr}'; echo 'Instance & Operation & Mean & Median & Min & Max \\'; awk -F, '$2=="Optimized"{printf "%s & %s & %s & %s & %s & %s \\\\\n",$3,$5,$8,$9,$10,$11}' "$RES/benchmark.csv"; echo '\end{tabular}';
 echo '% Sizes table'; echo '\begin{tabular}{llrrrr}'; echo 'Implementation & Instance & PK & SK & SS & CT \\'; awk -F, '{printf "%s & %s & %s & %s & %s & %s \\\\\n",$1,$2,$4,$5,$6,$7}' "$RES/sizes.csv"; echo '\end{tabular}';
 echo '% Test status summary block'; echo '\begin{verbatim}'; tail -n 20 "$RES/summary.md"; echo '\end{verbatim}';
} > "$RES/latex_tables.tex"
rm -rf "$RES/bin"
echo; echo "===== x86 self-evaluation summary ====="; if [ ${#FAIL[@]} -eq 0 ]; then echo "PASS"; else echo "FAIL"; printf ' - %s\n' "${FAIL[@]}"; fi; echo "Results: $RES"; exit $([ ${#FAIL[@]} -eq 0 ] && echo 0 || echo 1)
