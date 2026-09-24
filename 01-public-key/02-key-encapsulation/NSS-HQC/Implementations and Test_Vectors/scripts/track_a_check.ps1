$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$implRoot = Join-Path $root "Implementations"
$expectedFiles = @(
    "auxfunc.c",
    "auxfunc.h",
    "drng.c",
    "drng.h",
    "KAT_KEM.c",
    "KEM_AlgorithmInstance.c",
    "KEM_AlgorithmInstance.h",
    "nss_hqc_core.c",
    "nss_hqc_core.h",
    "code_layer.c",
    "code_layer.h",
    "selftest.c",
    "params.h",
    "Makefile",
    "README.txt"
)
$targets = @(
    "Reference_Implementation/HQC-128",
    "Reference_Implementation/HQC-256",
    "Reference_Implementation/HQC-384",
    "Reference_Implementation/HQC-512",
    "Optimized_Implementation/HQC-128",
    "Optimized_Implementation/HQC-256",
    "Optimized_Implementation/HQC-384",
    "Optimized_Implementation/HQC-512"
)

foreach ($target in $targets) {
    $dir = Join-Path $implRoot $target
    if (-not (Test-Path $dir)) {
        throw "Missing implementation directory: $target"
    }
    foreach ($file in $expectedFiles) {
        if (-not (Test-Path (Join-Path $dir $file))) {
            throw "Missing $file in $target"
        }
    }
    $header = Get-Content -Raw -Path (Join-Path $dir "KEM_AlgorithmInstance.h")
    if ($header -notmatch "OUTPUT_BLANK_TEST_VECTORS 0") {
        throw "KAT output mode is not enabled in $target"
    }
}

$scanTargets = @(
    (Join-Path $root "README.md"),
    (Join-Path $root "Implementations"),
    (Join-Path $root "Test_Vectors")
)
$patterns = @("src / include / tests")
$oldRefs = @()
if (Get-Command "rg" -ErrorAction SilentlyContinue) {
    $oldRefs = rg -n ($patterns -join "|") $scanTargets 2>$null
    if ($LASTEXITCODE -ne 0) {
        $oldRefs = @()
    }
} else {
    $files = foreach ($target in $scanTargets) {
        if (Test-Path $target -PathType Leaf) {
            Get-Item $target
        } elseif (Test-Path $target -PathType Container) {
            Get-ChildItem -Recurse -File -Path $target
        }
    }
    foreach ($pattern in $patterns) {
        $matches = Select-String -Path $files.FullName -Pattern $pattern -SimpleMatch -ErrorAction SilentlyContinue
        foreach ($match in $matches) {
            $oldRefs += "$($match.Path):$($match.LineNumber):$($match.Line)"
        }
    }
}
if ($oldRefs.Count -gt 0) {
    $oldRefs | ForEach-Object { Write-Host $_ }
    throw "Found stale references to the old code layout."
}

Write-Host "Track A layout/API checks passed."
if (-not (Get-Command "make" -ErrorAction SilentlyContinue)) {
    Write-Host "Compiler step skipped: make is not installed."
} elseif (-not (Get-Command "gcc" -ErrorAction SilentlyContinue) -and -not (Get-Command "clang" -ErrorAction SilentlyContinue)) {
    Write-Host "Compiler step skipped: gcc/clang is not installed."
} else {
    & (Join-Path $PSScriptRoot "build_all.ps1")
}
