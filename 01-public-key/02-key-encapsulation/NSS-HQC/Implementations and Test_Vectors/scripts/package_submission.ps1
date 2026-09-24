param(
    [string]$OutputDir = "submission_package",
    [switch]$CreateZip,
    [string]$ZipPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root $OutputDir
$srcImpl = Join-Path $root "Implementations"
$dstImpl = Join-Path $out "Implementations"
$dstTv = Join-Path $out "Test_Vectors"
$instances = @("HQC-128", "HQC-256", "HQC-384", "HQC-512")
$families = @("Reference_Implementation", "Optimized_Implementation")

if (Test-Path $out) {
    Remove-Item -LiteralPath $out -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dstImpl, $dstTv | Out-Null

Copy-Item -LiteralPath (Join-Path $root "Implementations/README") `
    -Destination (Join-Path $dstImpl "README") -Force

foreach ($family in $families) {
    foreach ($instance in $instances) {
        $src = Join-Path $srcImpl "$family/$instance"
        $dst = Join-Path $dstImpl "$family/$instance"
        if (-not (Test-Path $src)) {
            throw "Missing source directory: $src"
        }
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    }
}

$artifactPatterns = @(
    "*.o", "*.exe", "*.log", "kat_kem", "selftest",
    "submission_harness*", "output"
)
foreach ($pattern in $artifactPatterns) {
    Get-ChildItem -LiteralPath $dstImpl -Recurse -Force -Filter $pattern -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force
}

foreach ($instance in $instances) {
    $srcKat = Join-Path $root "Test_Vectors/KAT_KEM_$instance.txt"
    if (-not (Test-Path $srcKat)) {
        $srcKat = Join-Path $srcImpl "Reference_Implementation/$instance/output/KAT_KEM_$instance.txt"
    }
    if (-not (Test-Path $srcKat)) {
        throw "Missing KAT file for $instance"
    }
    Copy-Item -LiteralPath $srcKat -Destination (Join-Path $dstTv "KAT_KEM_$instance.txt") -Force
}

$materials = @(
    "VALIDATION_MATRIX.md",
    "SUBMISSION_COMPLIANCE_CHECKLIST.md",
    "PERFORMANCE_CAPTURE.md",
    "SANITIZER_STATUS.md",
    "ISO_C_CHECK.md",
    "THIRD_PARTY_NOTICES.md",
    "REFERENCE_BASELINE_FREEZE.md"
)
foreach ($material in $materials) {
    $src = Join-Path $root $material
    if (Test-Path $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $out (Split-Path -Leaf $material)) -Force
    }
}

Write-Host "Submission package exported to $out"

if ($CreateZip) {
    if ($ZipPath -eq "") {
        $ZipPath = Join-Path $root "NSS-HQC_submission_package.zip"
    }
    if (Test-Path $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }
    $zipInputs = Get-ChildItem -LiteralPath $out -Force | ForEach-Object { $_.FullName }
    Compress-Archive -Path $zipInputs -DestinationPath $ZipPath -Force
    Write-Host "Submission archive exported to $ZipPath"
    Write-Host "Archive root contains Implementations/ and Test_Vectors/ directly."
}
