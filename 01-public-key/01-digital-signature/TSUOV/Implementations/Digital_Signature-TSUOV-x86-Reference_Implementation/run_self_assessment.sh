#!/bin/sh
# One-click reproducible self-assessment for a digital signature implementation.
#
# Discovers parameter-set folders named FAMILY_LEVEL (e.g. TSUOV_128) under
# API_PKC/Implementations/{Optimized,Reference}_Implementation/.
#
# Usage:
#   ./run_self_assessment.sh [iterations] [optimized|reference]
set -e

ITERS="${1:-1000}"
IMPL="${2:-optimized}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/build"
REPORTS="$HERE/reports"

case "$IMPL" in
reference|ref|Reference|REF)
    PKC_FLAG=OFF
    IMPL_DIR=Reference_Implementation
    IMPL_LABEL=reference
    IMPL_SUFFIX=_ref
    ;;
optimized|opt|Optimized|OPT|"")
    PKC_FLAG=ON
    IMPL_DIR=Optimized_Implementation
    IMPL_LABEL=optimized
    IMPL_SUFFIX=_opt
    ;;
*)
    echo "Unknown implementation: $IMPL (use optimized or reference)" >&2
    exit 1
    ;;
esac

discover_folders() {
    _root="$HERE/API_PKC/Implementations/${IMPL_DIR}"
    _found=""
    for _dir in "$_root"/*; do
        [ -d "$_dir" ] || continue
        _base=$(basename "$_dir")
        _level="${_base##*_}"
        _family="${_base%_*}"
        [ "$_family" != "$_base" ] || continue
        case "$_level" in *[!0-9]*) continue;; esac
        _found="${_found}${_base}
"
    done
    printf '%s' "$_found" | sed '/^$/d' | sort -t_ -k2 -n
}

echo "== Cleaning previous run artifacts =="
mkdir -p "$REPORTS" "$HERE/logs"
rm -f "$REPORTS"/*.json "$REPORTS/summary.csv"
: > "$HERE/logs/self_assessment.log"

echo "== Building (cmake, ${IMPL_LABEL} implementation) =="
mkdir -p "$BUILD"
cd "$BUILD"
cmake -DPKC_OPTIMIZED_IMPL="${PKC_FLAG}" .. >/dev/null
make -j$(nproc 2>/dev/null || echo 2) ngcc_bench 2>&1 | grep -E '^make.*Error|error:' || true

echo "== Running self-assessment (iterations=$ITERS, impl=$IMPL_LABEL) =="
discover_folders | while IFS= read -r FOLDER; do
    [ -n "$FOLDER" ] || continue
    LEVEL="${FOLDER##*_}"
    FAMILY="${FOLDER%_*}"
    FAMILY_LC=$(printf '%s' "$FAMILY" | tr '[:upper:]' '[:lower:]')
    CLI="${FAMILY_LC}-${LEVEL}"
    "$BUILD/ngcc_bench_${FOLDER}" -a "$CLI" -t "$ITERS" \
        -l "$BUILD/API_PKC/Implementations/${IMPL_DIR}/libsigalg_${FOLDER}.a" \
        -o "$REPORTS"
done

echo ""
echo "== Generating self-assessment report =="
if command -v python3 >/dev/null 2>&1; then
    IMPL_LABEL="$IMPL_LABEL" python3 "$HERE/gen_report.py" \
        --reports "$REPORTS" --out "$HERE/self_assessment_report${IMPL_SUFFIX}.md"
else
    echo "WARN: python3 not found; skipping Markdown report generation."
fi

echo ""
echo "== Done. Summary (reports/summary.csv): =="
cat "$REPORTS/summary.csv"
