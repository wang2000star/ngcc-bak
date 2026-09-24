$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSCommandPath
$Build = Join-Path $Root "build"
cmake -S $Root -B $Build
cmake --build $Build -j
$Exe = Join-Path $Build "ngcc_bench.exe"
if (-not (Test-Path -LiteralPath $Exe)) { $Exe = Join-Path $Build "ngcc_bench" }
$Algs = @("iphe-512-perf", "iphe-768-perf", "iphe-1024-perf")
$Sizes = @(32, 128, 512, 1024, 4096, 8192, 16384, 65536)
foreach ($Alg in $Algs) {
  foreach ($Size in $Sizes) {
    & $Exe -a $Alg -t 1000 -l $Size
  }
}
