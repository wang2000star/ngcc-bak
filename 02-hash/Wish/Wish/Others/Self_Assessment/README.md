# Self-Assessment

This directory holds the self-assessment data and report of the Wish hash family.
It uses the **`ngcc_bench`** benchmark harness to load each implementation's
shared library (`.so`), run it against the published KAT vectors, and emit a
JSON performance report.

## Layout

```
Self_Assessment/
├── ngcc_bench/          benchmark harness (see "ngcc_bench" below)
├── Data/
│   ├── x86/             x86-64 .so libraries + testwish.sh
│   └── arm/             AArch64 .so libraries + testwish.sh
├── Reports/
│   ├── x86/             generated x86-64 JSON reports (.json.en / .json.zh)
│   └── arm/             generated AArch64 JSON reports (.json.en / .json.zh)
└── README.md            this file
```

## ngcc_bench

`ngcc_bench` is direcly obtained from:

> https://github.com/openHiTLS/ngcc_bench

It must be compiled following that project's instructions before running the
benchmark. Requirements: CMake >= 3.16, a C11 compiler (GCC or Clang), and on
Linux `libdl` / `libm`. Build it from the `ngcc_bench/` directory:

```bash
cd ngcc_bench
mkdir -p build
cd build
cmake ..
make -j
```

This produces the executable `ngcc_bench/build/ngcc_bench`, which the
`testwish.sh` scripts invoke.

## Running the benchmark

Run the script from inside the architecture directory that matches your host
(`Data/x86/` on x86-64, `Data/arm/` on AArch64):

```bash
# x86-64 host
cd Data/x86
./testwish.sh

# AArch64 host
cd Data/arm
sudo ./testwish.sh
```

Each `testwish` script loads every `.so` in its directory, runs the `hash` benchmark in `all` mode against the KAT vectors from `../Test_Vector/`, and writes one JSON report per library.

## Reports

The generated reports are placed in:

- `Reports/x86/`
- `Reports/arm/`

`ngcc_bench` emits two files per library, an English (`.json.en`) and a Chinese
(`.json.zh`) report, e.g. `Wish512_x86_aes_report.json.en`.

---

> **Note:** The data and reports are each generated and tested on dedicated machines.
> The files may have been renamed for clarity in this final
> presentation, but their contents remain unchanged and faithfully reflect the
> original test environments and measured performance.
