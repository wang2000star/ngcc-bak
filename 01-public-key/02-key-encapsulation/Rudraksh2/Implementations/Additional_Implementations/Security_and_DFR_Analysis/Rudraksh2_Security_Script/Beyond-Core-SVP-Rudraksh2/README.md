# Beyond-Core-SVP-Rudraksh2

**Repository layout**
- `framework/`: SageMath scripts and utilities used to generate instances and run algorithmic experiments (e.g., `DBDD.sage`, `geometry.sage`, `instance_gen.sage`).
- `Rudraksh2/`: Python utilities and executables for running the Rudraksh2 experiments:
  - `rudraksh2-bkz.py` — BKZ-related runner/experiment script.
  - `cost.py` — cost/estimation utilities.
  - `rudraksh2-gates.py` — gate-analysis script.
  

**Dependencies**
- Python 3.8+ for the `Rudraksh2` scripts.

**Usage examples**
From the Rudraksh2 folder:

For the BKZ experiment run:
```bash
$ cd Rudraksh2
$ python3 rudraksh2-bkz.py
```

To estimate the log_2(gates) and log_2(bit memory) cost analysis:
```bash
$ cd Rudraksh2
$ python3 rudraksh2-gates.py
```

