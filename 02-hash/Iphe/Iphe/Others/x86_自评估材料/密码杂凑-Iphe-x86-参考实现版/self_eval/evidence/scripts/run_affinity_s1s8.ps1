$ErrorActionPreference = "Stop"

param(
    [string]$NgccRoot = $env:NGCC_ROOT,
    [int]$AffinityMask = 1
)

if ([string]::IsNullOrWhiteSpace($NgccRoot)) {
    throw "Set NGCC_ROOT to the NGCC project root before running this script."
}

$Exe = Join-Path $NgccRoot "build\ngcc_bench.exe"
$WorkDir = Join-Path $NgccRoot "build"
$Reports = Join-Path $NgccRoot "reports"
if (-not (Test-Path -LiteralPath $Exe)) {
    throw ("ngcc_bench.exe not found: {0}" -f $Exe)
}

$OutDir = Join-Path (Split-Path -Parent $PSCommandPath) "affinity_run"
$JsonOut = Join-Path $OutDir "json"
$LogOut = Join-Path $OutDir "log"
New-Item -ItemType Directory -Force -Path $JsonOut,$LogOut | Out-Null
Get-ChildItem -Path $JsonOut -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Path $LogOut -File -ErrorAction SilentlyContinue | Remove-Item -Force

$Algs = @(
    "iphe-512", "iphe-768", "iphe-1024",
    "iphe-512-perf", "iphe-768-perf", "iphe-1024-perf",
    "iphe-512-res", "iphe-768-res", "iphe-1024-res"
)
$Sizes = @(32, 128, 512, 1024, 4096, 8192, 16384, 65536)

$RunLog = Join-Path $OutDir "affinity_run_log.txt"
("Affinity target: logical CPU 0 (mask 0x{0:X})" -f $AffinityMask) | Set-Content -Path $RunLog -Encoding UTF8
"Executable: ngcc_bench.exe" | Add-Content -Path $RunLog -Encoding UTF8
"Started: $(Get-Date -Format o)" | Add-Content -Path $RunLog -Encoding UTF8

foreach ($Alg in $Algs) {
    foreach ($Size in $Sizes) {
        $Args = @("-a", $Alg, "-t", "1000", "-l", [string]$Size)
        $SafeAlg = $Alg.Replace("-", "_")
        $RunStamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
        $StdOut = Join-Path $LogOut ("{0}_{1}_{2}.stdout.log" -f $SafeAlg,$Size,$RunStamp)
        $StdErr = Join-Path $LogOut ("{0}_{1}_{2}.stderr.log" -f $SafeAlg,$Size,$RunStamp)
        "RUN ngcc_bench.exe $($Args -join ' ')" | Add-Content -Path $RunLog -Encoding UTF8
        $P = Start-Process -FilePath $Exe -ArgumentList $Args -WorkingDirectory $WorkDir -PassThru -WindowStyle Hidden -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr
        try {
            $P.ProcessorAffinity = [IntPtr]$AffinityMask
            ("AFFINITY_SET pid={0} mask=0x{1:X} alg={2} size={3}" -f $P.Id,$AffinityMask,$Alg,$Size) | Add-Content -Path $RunLog -Encoding UTF8
        } catch {
            "AFFINITY_FAILED pid=$($P.Id) alg=$Alg size=$Size error=$($_.Exception.Message)" | Add-Content -Path $RunLog -Encoding UTF8
        }
        $P.WaitForExit()
        $P.Refresh()
        "EXIT code=$($P.ExitCode) alg=$Alg size=$Size" | Add-Content -Path $RunLog -Encoding UTF8
        if (($null -ne $P.ExitCode) -and ($P.ExitCode -ne 0)) {
            throw "ngcc_bench failed for $Alg size $Size with exit code $($P.ExitCode)"
        }

        $Json = Get-ChildItem -Path $Reports -File -Filter "*.json" |
            Where-Object { $_.LastWriteTime -ge (Get-Date).AddMinutes(-5) } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($null -eq $Json) {
            throw "No JSON report found after $Alg size $Size"
        }
        $CopyName = "{0}_{1}_{2}.json" -f $SafeAlg,$Size,$RunStamp
        Copy-Item -LiteralPath $Json.FullName -Destination (Join-Path $JsonOut $CopyName) -Force
        ("COPIED_JSON source=reports/{0} dest={1}" -f $Json.Name,$CopyName) | Add-Content -Path $RunLog -Encoding UTF8
    }
}

"Finished: $(Get-Date -Format o)" | Add-Content -Path $RunLog -Encoding UTF8
Get-ChildItem -Path $JsonOut -File | Select-Object Name, Length, LastWriteTime | Export-Csv -Path (Join-Path $OutDir "new_reports.csv") -NoTypeInformation -Encoding UTF8
Get-ChildItem -Path $LogOut -File | Select-Object Name, Length, LastWriteTime | Export-Csv -Path (Join-Path $OutDir "new_logs.csv") -NoTypeInformation -Encoding UTF8
"Copied JSON reports: $((Get-ChildItem -Path $JsonOut -File).Count)" | Add-Content -Path $RunLog -Encoding UTF8
"Captured logs: $((Get-ChildItem -Path $LogOut -File).Count)" | Add-Content -Path $RunLog -Encoding UTF8
