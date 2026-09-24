# Beyond-Core-SVP-Scabbard

**Repository layout**
- `framework/`: SageMath scripts and utilities used to generate instances and run algorithmic experiments (e.g., `DBDD.sage`, `geometry.sage`, `instance_gen.sage`).
- `Scabbard/`: Python utilities and executables for running the Scabbard experiments:
  - `scabbard-bkz.py` — BKZ-related runner/experiment script.
  - `cost.py` — cost/estimation utilities.
  - `scabbard-gates.py` — gate-analysis script.
  

**Dependencies**
- Python 3.8+ for the `Scabbard` scripts.

**Usage examples**
From the Scabbard folder:

For the BKZ experiment run:
```bash
cd Scabbard
python3 scabbard-bkz.py
```

To estimate the log_2(gates) and log_2(bit memory) cost analysis:
```bash
cd Scabbard
python3 scabbard-gates.py
```

