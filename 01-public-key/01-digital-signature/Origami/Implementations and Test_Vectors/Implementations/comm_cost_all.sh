#!/bin/sh
set -eu

RESULT_DIR=${RESULT_DIR:-CommCost_Results}
mkdir -p "$RESULT_DIR"

echo "implementation,instance,pk_bytes,sk_bytes,sig_bytes,pk_sig_bytes,keypair_bytes,sig_100M_us,pk_sig_100M_us,sig_1G_us,pk_sig_1G_us" > "$RESULT_DIR/summary.csv"

for impl in Reference_Implementation Optimized_Implementation; do
    for inst in Origami-128 Origami-256 Origami-384 Origami-512; do
        out="$RESULT_DIR/${impl}_${inst}.txt"
        echo "== $impl/$inst =="
        (cd "$impl/$inst" && make clean comm-cost 2>&1 && ./comm_cost_${inst} 2>&1) > "$out"
        # Extract the data line (starts with the instance name)
        awk -v impl="$impl" -v inst="$inst" '$1 ~ /^Origami-/ && $2 ~ /^[0-9]+$/ {
            printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", impl, inst, $2, $3, $4, $5, $6, $7, $8, $9, $10
        }' "$out" >> "$RESULT_DIR/summary.csv"
    done
done

echo ""
echo "=== Communication & Storage Cost Summary ==="
cat "$RESULT_DIR/summary.csv"
echo ""
echo "Results saved to $RESULT_DIR/summary.csv"
