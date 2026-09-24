# Benchmarking

## Speed

Benchmarking the speed is relatively simple. Included in the test files is `test_benchmark.c` which simply counts the cycles consumed when running each of the 3 main algorithms.

## Memory

For memory we must measure static and peak memory usage. Static memory usage is achieved by compiling the scheme into a static library then evaluating the size of the relevant sections, namely:
- `.text`
- `.data`
- `.rodata`
- `.bss`
This can be done by generating the relevant csv file from the following `size` command:

```
size -A -d liblwekem256.a | awk 'BEGIN {print "Object_File,Section,Size_Bytes"} /ex liblwekem256.a/ {obj=$1} /^\.(text|data|bss|rodata)/ {print obj "," $1 "," $2}' > static_memory.csv
```

Then analysing that with whichever spreadsheet program you see fit.

For peak memory usage we utilise the `valgrind` tool `massif`. The figures were collected using the following command:

```
valgrind --tool=massif --pages-as-heap=yes ./lwekem256-test_basic
```
