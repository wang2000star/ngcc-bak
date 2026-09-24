# HARE server validation guide

This guide gives fresh-run commands for the current package:

```text
HARE_Code_Package_kr_only.zip
```

Always use a new run directory.  Return the result archive even if the runner
fails.  Long validations should be started inside `tmux`; if the network drops,
reconnect and inspect the existing run before starting a new one.

## 1. Mac upload

### ARM/SVE server

```bash
cd ~/Desktop

ssh root@<ARM_SERVER> 'mkdir -p /root/hare-upload'

scp HARE_Code_Package_kr_only.zip \
    HARE_Code_Package_kr_only.zip.sha256 \
    root@<ARM_SERVER>:/root/hare-upload/
```

### x86 server

```bash
cd ~/Desktop

ssh -o ConnectTimeout=10 -o IdentitiesOnly=yes \
  -i ~/.ssh/<X86_IDENTITY_FILE> \
  root@<X86_SERVER> 'mkdir -p /root/hare-upload'

scp -o ConnectTimeout=10 -o IdentitiesOnly=yes \
    -i ~/.ssh/<X86_IDENTITY_FILE> \
    HARE_Code_Package_kr_only.zip \
    HARE_Code_Package_kr_only.zip.sha256 \
    root@<X86_SERVER>:/root/hare-upload/
```

## 2. Fresh server run directory

Use the same commands after logging into either server.  The runner auto-detects
architecture, but the explicit modes below are recommended.

```bash
PKG=/root/hare-upload/HARE_Code_Package_kr_only.zip
SHA=/root/hare-upload/HARE_Code_Package_kr_only.zip.sha256
TAG=hare_v15_submission_$(date -u +%Y%m%d_%H%M%S)
RUN=/root/hare-runs/$TAG

mkdir -p "$RUN/src" "$RUN/results"
cd /root/hare-upload
sha256sum -c "$SHA"
python3 -m zipfile -e "$PKG" "$RUN/src"
cd "$RUN/src/HARE_Code_Package"
```

## 3. Package gates

```bash
bash tools/gates/check_manifest.sh | tee "$RUN/results/manifest.log"
bash tools/gates/check_generated_artifacts.sh | tee "$RUN/results/generated_artifacts.log"
```

Both gates must print `PASS` before platform validation.

## 4. Recommended tmux wrapper for long runs

Use `tmux` so the validation keeps running after a network disconnect.

```bash
# Start once, before launching the runner.
tmux new -s hare_server
```

Inside tmux, run the x86 or ARM command below.  Detach with `Ctrl-b` then `d`.
Reconnect with:

```bash
# ARM
ssh root@<ARM_SERVER>
# or x86
ssh -o ConnectTimeout=10 -o IdentitiesOnly=yes -i ~/.ssh/<X86_IDENTITY_FILE> root@<X86_SERVER>

tmux attach -t hare_server
```

If `tmux` is unavailable, use the same validation command with `nohup`, but the
preferred workflow is `tmux`.

## 5. x86 validation

Run on `root@<X86_SERVER>`:

```bash
OUT="$RUN/results/server_x86_$(date -u +%Y%m%d_%H%M%S)"
CONSOLE="$RUN/results/$(basename "$OUT").console.log"

HARE_SERVER_MODE=x86 \
HARE_CPU_CORE=0 \
HARE_BENCH_INSTANCES=10 \
HARE_BENCH_REPEATS=100 \
HARE_BENCH_WARMUP_REPEATS=10 \
RUN_SANITIZERS=1 \
JOBS=8 \
  bash tools/server/run_server_validation.sh "$OUT" \
  2>&1 | tee "$CONSOLE"

STATUS=${PIPESTATUS[0]}
echo "runner_status=$STATUS"
echo "RESULTS=$OUT"
echo "CONSOLE=$CONSOLE"
```

Expected x86 gates:

```text
manifest PASS
generated-artifact check PASS
Release build PASS
CTest PASS
run_kat_all PASS
verify_kat_all PASS
verify_kat_optimized_all PASS
PCLMUL audit PASS
four KR Reference benchmarks with decaps_shared_secret_match_count=1000/1000
four KR x86 Optimized benchmarks with decaps_shared_secret_match_count=1000/1000
static size, stack usage, raw sample CSV, and peak RSS records present
```

## 6. ARM/SVE validation

Run on `root@<ARM_SERVER>`:

```bash
OUT="$RUN/results/server_arm_$(date -u +%Y%m%d_%H%M%S)"
CONSOLE="$RUN/results/$(basename "$OUT").console.log"

HARE_SERVER_MODE=arm \
HARE_CPU_CORE=0 \
HARE_BENCH_INSTANCES=10 \
HARE_BENCH_REPEATS=100 \
HARE_BENCH_WARMUP_REPEATS=10 \
RUN_SANITIZERS=0 \
JOBS=8 \
  bash tools/server/run_server_validation.sh "$OUT" \
  2>&1 | tee "$CONSOLE"

STATUS=${PIPESTATUS[0]}
echo "runner_status=$STATUS"
echo "RESULTS=$OUT"
echo "CONSOLE=$CONSOLE"
```

Expected ARM/SVE gates:

```text
manifest PASS
generated-artifact check PASS
PMULL ON build/CTest/KAT/benchmark PASS
PMULL ON gf2x object contains pmull
PMULL OFF build/CTest/KAT/benchmark PASS
PMULL OFF gf2x object contains no pmull
four KR Reference benchmarks with decaps_shared_secret_match_count=1000/1000
four KR ARM/SVE PMULL ON benchmarks with decaps_shared_secret_match_count=1000/1000
four KR ARM/SVE PMULL OFF benchmarks with decaps_shared_secret_match_count=1000/1000
static size, stack usage, raw sample CSV, and peak RSS records present
```

If the ARM run is too long, first smoke-test with `HARE_BENCH_INSTANCES=3` and
`HARE_BENCH_REPEATS=20`; use 10×100 for the final evidence archive.

## 7. Reconnect after network interruption

If the terminal disconnects or you close the first terminal, reconnect and inspect
before starting a new run.

```bash
# Set these to the values printed when the run was launched.
RUN=/root/hare-runs/<TAG>
OUT=/root/hare-runs/<TAG>/results/<server_x86_or_server_arm_TIMESTAMP>
CONSOLE=/root/hare-runs/<TAG>/results/<server_x86_or_server_arm_TIMESTAMP>.console.log

# Check whether validation or benchmarks are still running.
ps -eo pid,ppid,sid,stat,etime,cmd \
  | grep -E 'run_server_validation|bench_HARE|ctest|cmake|taskset|perf record' \
  | grep -v grep || true

# Inspect current logs and status.
tail -n 120 "$CONSOLE" 2>/dev/null || true
cat "$OUT/summary.log" 2>/dev/null || true
cat "$OUT/run_status.tsv" 2>/dev/null || true
grep -R "decaps_shared_secret_match_count" "$OUT/bench" 2>/dev/null || true
```

Interpretation:

```text
RUNNER_EXIT_STATUS=0
  The main validation finished.  You may optionally run component profiling and
  then pack the result.

RUNNER_EXIT_STATUS=1 or 2
  The runner failed or preflight failed.  Pack and return the result archive for
  analysis; do not delete the directory.

No summary.log and processes still running
  Leave the run alone or reattach tmux.

No summary.log and no process
  The run was interrupted.  Pack the partial result for analysis or start a new
  fresh run directory.
```

## 8. Optional component hotspot profiling after a completed run

The server runner can also collect profiling during validation by setting
`RUN_COMPONENT_PROFILE=1` before starting the runner.  If the main validation
has already completed without profiling, run one of the following commands from
`$RUN/src/HARE_Code_Package`.

### x86 optimized KR hotspot profiling

```bash
HARE_CPU_CORE=${HARE_CPU_CORE:-0} \
HARE_COMPONENT_PROFILE_INSTANCES=${HARE_COMPONENT_PROFILE_INSTANCES:-1} \
HARE_COMPONENT_PROFILE_REPEATS=${HARE_COMPONENT_PROFILE_REPEATS:-20} \
HARE_COMPONENT_PROFILE_WARMUP_REPEATS=${HARE_COMPONENT_PROFILE_WARMUP_REPEATS:-2} \
  bash tools/profiling/run_component_hotspots.sh \
    "$OUT/builds/build-x86" \
    "$OUT/hotspots/x86_optimized_kr_late" \
    x86_optimized_kr_late \
    "$OUT/builds/build-x86/bench_HARE_128_kr_x86" \
    "$OUT/builds/build-x86/bench_HARE_256_kr_x86" \
    "$OUT/builds/build-x86/bench_HARE_384_kr_x86" \
    "$OUT/builds/build-x86/bench_HARE_512_kr_x86"
```

### ARM/SVE PMULL ON KR hotspot profiling

```bash
HARE_CPU_CORE=${HARE_CPU_CORE:-0} \
HARE_COMPONENT_PROFILE_INSTANCES=${HARE_COMPONENT_PROFILE_INSTANCES:-1} \
HARE_COMPONENT_PROFILE_REPEATS=${HARE_COMPONENT_PROFILE_REPEATS:-20} \
HARE_COMPONENT_PROFILE_WARMUP_REPEATS=${HARE_COMPONENT_PROFILE_WARMUP_REPEATS:-2} \
  bash tools/profiling/run_component_hotspots.sh \
    "$OUT/builds/build-arm-pmull-on" \
    "$OUT/hotspots/arm_additional_kr_pmull_on_late" \
    arm_additional_kr_pmull_on_late \
    "$OUT/builds/build-arm-pmull-on/bench_HARE_128_kr_arm_sve" \
    "$OUT/builds/build-arm-pmull-on/bench_HARE_256_kr_arm_sve" \
    "$OUT/builds/build-arm-pmull-on/bench_HARE_384_kr_arm_sve" \
    "$OUT/builds/build-arm-pmull-on/bench_HARE_512_kr_arm_sve"
```

If Linux `perf` is unavailable or blocked by the kernel, the profiler records
`UNAVAILABLE_*` in `hotspots/*/component_profile_status.txt`. This does not
invalidate the correctness/performance validation unless `REQUIRE_COMPONENT_PROFILE=1` is set.

## 9. Result files

Inspect these files in `$OUT`:

```text
summary.log
run_status.tsv
environment.txt
logs/*.log
audit/*.log
bench/*.log
bench/*.raw.csv
resource/*
MANIFEST.sha256
hotspots/*
```

## 10. Pack results on the server

```bash
CONSOLE="${CONSOLE:-$RUN/results/.console.log}"

OUT="${OUT:-}"

if [ -z "$OUT" ] && [ -f "$CONSOLE" ]; then
  OUT=$(awk -F= '/^RESULT_DIR=/{v=$2} END{print v}' "$CONSOLE")
fi

if [ -z "$OUT" ] || [ ! -d "$OUT" ]; then
  OUT=$(find "$RUN/results" "$RUN/src/hare-results" -maxdepth 1 -type d -name 'server_*' -print 2>/dev/null | sort | tail -n 1)
fi

if [ -z "$OUT" ] || [ ! -d "$OUT" ]; then
  echo "ERROR: cannot locate RESULT_DIR under $RUN/results or $RUN/src/hare-results"
  exit 2
fi

NAME=$(basename "$OUT")
ARCHIVE="$RUN/${NAME}.tar.gz"

tar_args=(-C "$(dirname "$OUT")" "$NAME")
if [ -f "$CONSOLE" ]; then
  tar_args+=(-C "$(dirname "$CONSOLE")" "$(basename "$CONSOLE")")
fi

tar -czf "$ARCHIVE" "${tar_args[@]}"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

echo "RESULT_DIR=$OUT"
echo "RESULT_PACKAGE=$ARCHIVE"
echo "RESULT_SHA=$ARCHIVE.sha256"
```

## 11. Download results to Mac

### ARM/SVE result download

```bash
scp root@<ARM_SERVER>:/root/hare-runs/<TAG>/<RESULT_NAME>.tar.gz ~/Desktop/
scp root@<ARM_SERVER>:/root/hare-runs/<TAG>/<RESULT_NAME>.tar.gz.sha256 ~/Desktop/
```

### x86 result download

```bash
scp -o ConnectTimeout=10 -o IdentitiesOnly=yes \
    -i ~/.ssh/<X86_IDENTITY_FILE> \
    root@<X86_SERVER>:/root/hare-runs/<TAG>/<RESULT_NAME>.tar.gz ~/Desktop/

scp -o ConnectTimeout=10 -o IdentitiesOnly=yes \
    -i ~/.ssh/<X86_IDENTITY_FILE> \
    root@<X86_SERVER>:/root/hare-runs/<TAG>/<RESULT_NAME>.tar.gz.sha256 ~/Desktop/
```

Mac-side check:

```bash
cd ~/Desktop
shasum -a 256 <RESULT_NAME>.tar.gz
cat <RESULT_NAME>.tar.gz.sha256
```

Return the `.tar.gz`, `.tar.gz.sha256`, and console log for analysis.
