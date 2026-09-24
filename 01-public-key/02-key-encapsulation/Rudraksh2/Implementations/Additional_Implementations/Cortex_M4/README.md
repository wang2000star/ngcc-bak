This repository contains Cortex-M4 code for Rudraksh2

## Requirements

This repository includes the [pqm4](https://github.com/mupq/pqm4) framework for benchmarking on the [STM32F4 Discovery board](https://www.st.com/en/evaluation-tools/stm32f4discovery.html). We refer to the pqm4 documentation for installation instructions and prerequisites.

## Running Benchmarks

Go to lwekem128/lwekem256/lwekem512 folder and then run the following commands

```bash
[sudo] make clean
[sudo] python3 benchmarks.py
[sudo] python3 convert_benchmarks.py md 
```

Benchmarks can then be found in the terminal
