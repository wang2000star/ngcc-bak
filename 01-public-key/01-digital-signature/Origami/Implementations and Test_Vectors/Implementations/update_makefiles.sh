#!/bin/bash
set -eu

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

for dir in \
    Reference_Implementation/Origami-128 \
    Reference_Implementation/Origami-256 \
    Reference_Implementation/Origami-384 \
    Reference_Implementation/Origami-512 \
    Optimized_Implementation/Origami-128 \
    Optimized_Implementation/Origami-256 \
    Optimized_Implementation/Origami-384 \
    Optimized_Implementation/Origami-512; do

    mf="$BASE_DIR/$dir/Makefile"
    echo "=== Updating $mf ==="

    # 1) Add COMM_COST vars after BENCH_DRIVER line
    sed -i "/^BENCH_DRIVER = /a COMM_COST = comm_cost_\$(INSTANCE)\nCOMM_COST_DRIVER = ../../Common/comm_cost.c" "$mf"

    # 2) Add COMM_COST_OBJS after BENCH_OBJS line
    if echo "$dir" | grep -q "Reference"; then
        sed -i "/^BENCH_OBJS = /a COMM_COST_OBJS = SIG_AlgorithmInstance.o comm_cost.o drng.o auxfunc.o symmetric_iccs.o origami_ref.o aes.o" "$mf"
    else
        sed -i "/^BENCH_OBJS = /a COMM_COST_OBJS = SIG_AlgorithmInstance.o comm_cost.o drng.o auxfunc.o symmetric_iccs.o origami_opt.o aes.o" "$mf"
    fi

    # 3) Update all target
    sed -i "s/^all: \$(KAT) \$(BENCH)$/all: \$(KAT) \$(BENCH) \$(COMM_COST)/" "$mf"

    # 4) Update PHONY
    sed -i "s/^.PHONY: all kat bench run-bench clean$/.PHONY: all kat bench run-bench comm-cost run-comm-cost clean/" "$mf"

    # 5) Update clean
    sed -i "s|rm -f \$(OBJS) bench_sig.o \$(BENCH) \$(KAT)|rm -f \$(OBJS) bench_sig.o comm_cost.o \$(BENCH) \$(KAT) \$(COMM_COST)|" "$mf"

    # 6) Append new targets via cat
    cat >> "$mf" << "EOF"

\$(COMM_COST): \$(COMM_COST_OBJS)
	\$(CC) \$(CFLAGS) -o \$@ \$(COMM_COST_OBJS)

comm_cost.o: \$(COMM_COST_DRIVER)
	\$(CC) \$(CFLAGS) -I. -c -o \$@ \$(COMM_COST_DRIVER)

comm-cost: \$(COMM_COST)

run-comm-cost: \$(COMM_COST)
	./\$(COMM_COST)
EOF

done

echo ""
echo "All Makefiles updated successfully."
