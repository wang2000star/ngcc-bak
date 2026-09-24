#!/bin/sh
set -eu

for inst in Origami-128 Origami-256 Origami-384 Origami-512; do
    echo "== Reference_Implementation/$inst =="
    (cd "Reference_Implementation/$inst" && make clean kat bench)
done

for inst in Origami-128 Origami-256 Origami-384 Origami-512; do
    echo "== Optimized_Implementation/$inst =="
    (cd "Optimized_Implementation/$inst" && make clean all)
done
