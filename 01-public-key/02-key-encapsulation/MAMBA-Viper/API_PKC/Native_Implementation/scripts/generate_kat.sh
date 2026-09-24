#!/bin/bash
# Generate KAT files for all Viper parameter sets using Reference Implementation

set -e

BASEDIR="$(cd "$(dirname "$0")/Reference_Implementation_KEM" && pwd)"
KATDIR="$(cd "$(dirname "$0")/KAT" && pwd)"

cd "$BASEDIR"

# Parameter sets: (LEVEL, pk+ct_bytes, subdirectory_name)
# 128: 608+736=1344 -> Viper128
# 192: 992+1088=2080 -> Viper192
# 256: 1312+1472=2784 -> Viper256
# 384: 2496+2656=5152 -> Viper384
# 512: 3200+3456=6656 -> Viper512

LEVELS=(128 192 256 384 512)
PKCT=(1344 2080 2784 5152 6656)
DIRS=(Viper128 Viper192 Viper256 Viper384 Viper512)

for i in "${!LEVELS[@]}"; do
    LEVEL="${LEVELS[$i]}"
    PKCT_LEN="${PKCT[$i]}"
    DIR="${DIRS[$i]}"
    
    echo "=== Generating KAT for Viper LEVEL=$LEVEL (pk+ct=$PKCT_LEN) -> KAT/$DIR ==="
    
    make clean >/dev/null 2>&1 || true
    make LEVEL=$LEVEL KAT_KEM >/dev/null 2>&1
    
    if [ ! -f "PQCkemKAT_${PKCT_LEN}.req" ] || [ ! -f "PQCkemKAT_${PKCT_LEN}.rsp" ]; then
        echo "ERROR: KAT generation failed for LEVEL=$LEVEL"
        continue
    fi
    
    mkdir -p "$KATDIR/$DIR"
    cp "PQCkemKAT_${PKCT_LEN}.req" "$KATDIR/$DIR/"
    cp "PQCkemKAT_${PKCT_LEN}.rsp" "$KATDIR/$DIR/"
    echo "OK: KAT/$DIR/PQCkemKAT_${PKCT_LEN}.{req,rsp}"
done

echo ""
echo "All KAT files generated in KAT/"
ls -la "$KATDIR"
