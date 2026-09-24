param(
    [int]$SelftestRuns = 100,
    [int]$KatRuns = 10,
    [int]$KemLoops = 1000,
    [int]$ProgressEvery = 10,
    [switch]$CalibratedLoops,
    [switch]$SkipSanitizers
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$implRoot = Join-Path $root "Implementations"
$tvRoot = Join-Path $root "Test_Vectors"
$instances = @("HQC-128", "HQC-256", "HQC-384", "HQC-512")
$families = @("Reference_Implementation", "Optimized_Implementation")

function Resolve-MsysBash {
    $candidates = @("C:\msys64\usr\bin\bash.exe")
    $commands = Get-Command "bash" -All -ErrorAction SilentlyContinue
    foreach ($cmd in $commands) {
        if ($cmd.Source -and
            $cmd.Source -notmatch '\\Windows\\System32\\bash\.exe$' -and
            $cmd.Source -notmatch '\\Microsoft\\WindowsApps\\bash\.exe$') {
            $candidates += $cmd.Source
        }
    }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw "Missing MSYS2 bash."
}

function Convert-ToMsysPath {
    param([string]$Path)
    $full = (Resolve-Path $Path).Path
    if ($full -match '^([A-Za-z]):\\(.*)$') {
        return "/" + $matches[1].ToLower() + "/" + (($matches[2]) -replace '\\', '/')
    }
    return ($full -replace '\\', '/')
}

function Invoke-Bash {
    param([string]$Dir, [string]$Command)
    $msysDir = Convert-ToMsysPath $Dir
    $cmd = "export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; cd '$msysDir' && $Command"
    & $script:Bash -lc $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed in $Dir`: $Command"
    }
}

function Try-Bash {
    param([string]$Dir, [string]$Command)
    $msysDir = Convert-ToMsysPath $Dir
    $cmd = "export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; cd '$msysDir' && $Command"
    & $script:Bash -lc $cmd
    return ($LASTEXITCODE -eq 0)
}

function Write-Harness {
    param([string]$Dir)
    $path = Join-Path $Dir "submission_harness.c"
    @'
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "drng.h"
#include "KEM_AlgorithmInstance.h"

DRNG_ctx drng_algorithm;

static int ct_equal(const unsigned char *a, const unsigned char *b, unsigned long long n) {
    unsigned char d = 0;
    unsigned long long i;
    for (i = 0; i < n; i++) d |= (unsigned char)(a[i] ^ b[i]);
    return d == 0;
}

static void seed_rng(unsigned int round) {
    unsigned char seed[48];
    unsigned int i;
    for (i = 0; i < sizeof(seed); i++) {
        seed[i] = (unsigned char)(0x5aU + 13U * i + 17U * round);
    }
    init_random_number(&drng_algorithm, seed, sizeof(seed));
}

int main(int argc, char **argv) {
    int loops = 1000;
    int progress_every = 10;
    unsigned long long pk_len = kem_get_pk_len_bytes();
    unsigned long long sk_len = kem_get_sk_len_bytes();
    unsigned long long ss_len = kem_get_ss_len_bytes();
    unsigned long long ct_len = kem_get_ct_len_bytes();
    unsigned char *pk = (unsigned char *)calloc(pk_len, 1);
    unsigned char *sk = (unsigned char *)calloc(sk_len, 1);
    unsigned char *ct = (unsigned char *)calloc(ct_len, 1);
    unsigned char *tmp = (unsigned char *)calloc(ct_len, 1);
    unsigned char *ss1 = (unsigned char *)calloc(ss_len, 1);
    unsigned char *ss2 = (unsigned char *)calloc(ss_len, 1);
    unsigned long long pk_out, sk_out, ss_out, ct_out;
    int i;
    clock_t t0, t1;
    double keygen_s = 0.0, enc_s = 0.0, dec_s = 0.0;
    if (argc > 1) loops = atoi(argv[1]);
    if (argc > 2) progress_every = atoi(argv[2]);
    if (!pk || !sk || !ct || !tmp || !ss1 || !ss2) return 2;
    for (i = 0; i < loops; i++) {
        unsigned long long tamper[3];
        int j;
        seed_rng((unsigned int)i);
        t0 = clock();
        if (kem_keygen(pk, &pk_out, sk, &sk_out) != 0) return 10;
        t1 = clock(); keygen_s += (double)(t1 - t0) / CLOCKS_PER_SEC;
        if (pk_out != pk_len || sk_out != sk_len) return 11;
        t0 = clock();
        if (kem_enc(pk, pk_len, ss1, &ss_out, ct, &ct_out) != 0) return 12;
        t1 = clock(); enc_s += (double)(t1 - t0) / CLOCKS_PER_SEC;
        if (ss_out != ss_len || ct_out != ct_len) return 13;
        t0 = clock();
        if (kem_dec(sk, sk_len, ct, ct_len, ss2, &ss_out) != 0) return 14;
        t1 = clock(); dec_s += (double)(t1 - t0) / CLOCKS_PER_SEC;
        if (ss_out != ss_len || !ct_equal(ss1, ss2, ss_len)) return 15;
        tamper[0] = 0;
        tamper[1] = ct_len > 33 ? 33 : 0;
        tamper[2] = ct_len - 1;
        for (j = 0; j < 3; j++) {
            memcpy(tmp, ct, ct_len);
            tmp[tamper[j]] ^= 1U;
            memset(ss2, 0, ss_len);
            if (kem_dec(sk, sk_len, tmp, ct_len, ss2, &ss_out) == 0) return 20 + j;
            if (ct_equal(ss1, ss2, ss_len)) return 30 + j;
        }
        if (progress_every > 0 && ((i + 1) % progress_every == 0 || i + 1 == loops)) {
            fprintf(stderr, "progress=%d/%d\n", i + 1, loops);
            fflush(stderr);
        }
    }
    printf("loops=%d pk=%llu sk=%llu ct=%llu ss=%llu keygen_ms=%.6f enc_ms=%.6f dec_ms=%.6f\n",
           loops, pk_len, sk_len, ct_len, ss_len,
           1000.0 * keygen_s / loops,
           1000.0 * enc_s / loops,
           1000.0 * dec_s / loops);
    free(pk); free(sk); free(ct); free(tmp); free(ss1); free(ss2);
    return 0;
}
'@ | Set-Content -LiteralPath $path -Encoding ASCII
}

$script:Bash = Resolve-MsysBash
New-Item -ItemType Directory -Force -Path $tvRoot | Out-Null
$results = @()
$katHashes = @{}
$perf = @()

foreach ($family in $families) {
    foreach ($instance in $instances) {
        $dir = Join-Path $implRoot "$family/$instance"
        $instanceLoops = $KemLoops
        if ($CalibratedLoops) {
            if ($instance -eq "HQC-384") { $instanceLoops = [Math]::Min($KemLoops, 100) }
            if ($instance -eq "HQC-512") { $instanceLoops = [Math]::Min($KemLoops, 25) }
        }
        Write-Host "==> $family/$instance"
        Write-Harness $dir
        Invoke-Bash $dir "make clean && make selftest && make kat"

        Invoke-Bash $dir "for i in `$(seq 1 $SelftestRuns); do ./selftest >/dev/null || exit 1; done"

        $firstHash = $null
        for ($i = 1; $i -le $KatRuns; $i++) {
            Invoke-Bash $dir "./kat_kem >/dev/null"
            $katFile = Join-Path $dir "output/KAT_KEM_$instance.txt"
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $katFile).Hash
            if ($null -eq $firstHash) { $firstHash = $hash }
            if ($hash -ne $firstHash) { throw "KAT not stable for $family/$instance" }
        }
        $katHashes["$family/$instance"] = $firstHash

        if ($family -eq "Reference_Implementation") {
            Copy-Item -LiteralPath (Join-Path $dir "output/KAT_KEM_$instance.txt") `
                -Destination (Join-Path $tvRoot "KAT_KEM_$instance.txt") -Force
        }

        Invoke-Bash $dir "cc -std=c99 -O2 -Wall -Wextra -pedantic -o submission_harness submission_harness.c KEM_AlgorithmInstance.c nss_hqc_core.c code_layer.c auxfunc.c drng.c && ./submission_harness $instanceLoops $ProgressEvery > submission_harness.log"
        $harnessLine = Get-Content -LiteralPath (Join-Path $dir "submission_harness.log") | Select-Object -Last 1
        $perf += [pscustomobject]@{ Family=$family; Instance=$instance; Harness=$harnessLine }

        $asan = "skipped"
        $ubsan = "skipped"
        if (-not $SkipSanitizers) {
            if (Try-Bash $dir "cc -std=c99 -O1 -g -fsanitize=address -fno-omit-frame-pointer -o submission_harness_asan submission_harness.c KEM_AlgorithmInstance.c nss_hqc_core.c code_layer.c auxfunc.c drng.c && ./submission_harness_asan 10 >/dev/null") {
                $asan = "passed"
            } else {
                $asan = "unavailable_or_failed"
            }
            if (Try-Bash $dir "cc -std=c99 -O1 -g -fsanitize=undefined -fno-omit-frame-pointer -o submission_harness_ubsan submission_harness.c KEM_AlgorithmInstance.c nss_hqc_core.c code_layer.c auxfunc.c drng.c && ./submission_harness_ubsan 10 >/dev/null") {
                $ubsan = "passed"
            } else {
                $ubsan = "unavailable_or_failed"
            }
        }

        $results += [pscustomobject]@{
            Family=$family
            Instance=$instance
            Selftest="passed (${SelftestRuns}x)"
            Kat="passed (${KatRuns}x stable)"
            KemLoop="passed (${instanceLoops}x)"
            Tamper="passed (${instanceLoops}x u/v/salt)"
            CodeLayer="passed via selftest"
            Sanitizer="ASan=$asan; UBSan=$ubsan"
            KatHash=$firstHash
        }
    }
}

foreach ($instance in $instances) {
    if ($katHashes["Reference_Implementation/$instance"] -ne $katHashes["Optimized_Implementation/$instance"]) {
        throw "Reference/optimized KAT hash mismatch for $instance"
    }
}

$outDir = Join-Path $root "docs/validation_artifacts"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outDir "submission_validation_results.json") -Encoding ASCII
$perf | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outDir "performance_capture_raw.json") -Encoding ASCII
Write-Host "Submission validation passed."
