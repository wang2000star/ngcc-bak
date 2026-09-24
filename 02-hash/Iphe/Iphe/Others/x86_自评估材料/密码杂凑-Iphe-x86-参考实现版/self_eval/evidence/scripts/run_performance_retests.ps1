$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSCommandPath
$Versions = @(
    @{
        Name = "Reference"
        Key = "reference"
        Project = "ngcc_bench_iphe_reference"
        Algs = @("iphe-512", "iphe-768", "iphe-1024")
    },
    @{
        Name = "Performance"
        Key = "performance"
        Project = "ngcc_bench_iphe_performance"
        Algs = @("iphe-512-perf", "iphe-768-perf", "iphe-1024-perf")
    },
    @{
        Name = "Resource"
        Key = "resource"
        Project = "ngcc_bench_iphe_resource"
        Algs = @("iphe-512-res", "iphe-768-res", "iphe-1024-res")
    }
)
$Sizes = @(32, 128, 512, 1024, 4096, 8192, 16384, 65536)
$Rounds = 1..3
$FocusRounds = 1..7
$AffinityMask = 1

function Get-ProjectRoot {
    param([hashtable]$Version)
    $Matches = Get-ChildItem -LiteralPath $Root -Recurse -Directory -Filter $Version.Project
    if ($Matches.Count -lt 1) {
        throw "Project directory not found: $($Version.Project)"
    }
    return $Matches[0].FullName
}

function Invoke-NgccRetest {
    param(
        [hashtable]$Version,
        [string]$Alg,
        [int]$Size,
        [string]$Mode,
        [int]$Round
    )
    $ProjectRoot = Get-ProjectRoot -Version $Version
    $SelfEval = Split-Path -Parent $ProjectRoot
    $Build = Join-Path $ProjectRoot "build"
    $Exe = Join-Path $Build "ngcc_bench.exe"
    if (-not (Test-Path -LiteralPath $Exe)) {
        $Exe = Join-Path $Build "ngcc_bench"
    }
    if (-not (Test-Path -LiteralPath $Exe)) {
        throw "ngcc_bench executable not found for $($Version.Name)"
    }

    $Evidence = Join-Path $SelfEval ("evidence\retest\" + $Version.Key)
    $JsonOut = Join-Path $Evidence "json"
    $LogOut = Join-Path $Evidence "log"
    New-Item -ItemType Directory -Force -Path $JsonOut, $LogOut | Out-Null

    $SafeAlg = $Alg.Replace("-", "_")
    $Stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $Prefix = "{0}_{1}_{2}_r{3}_{4}" -f $SafeAlg, $Size, $Mode, $Round, $Stamp
    $StdOut = Join-Path $LogOut ($Prefix + ".stdout.log")
    $StdErr = Join-Path $LogOut ($Prefix + ".stderr.log")
    $RunLog = Join-Path $Evidence "retest_run_log.txt"
    Add-Content -LiteralPath $RunLog -Value ("RUN mode={0} round={1} alg={2} size={3} affinity=0x{4:X}" -f $Mode, $Round, $Alg, $Size, $AffinityMask)

    $ReportDir = Join-Path $ProjectRoot "reports"
    New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
    $Before = Get-ChildItem -LiteralPath $ReportDir -Filter "*.json" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $Psi = New-Object System.Diagnostics.ProcessStartInfo
    $Psi.FileName = $Exe
    $Psi.WorkingDirectory = $ProjectRoot
    $Psi.UseShellExecute = $false
    $Psi.RedirectStandardOutput = $true
    $Psi.RedirectStandardError = $true
    $Psi.Arguments = "-a `"$Alg`" -t 1000 -l $Size"
    $P = New-Object System.Diagnostics.Process
    $P.StartInfo = $Psi
    [void]$P.Start()
    try {
        $P.ProcessorAffinity = [IntPtr]$AffinityMask
        Add-Content -LiteralPath $RunLog -Value ("AFFINITY_SET pid={0} mask=0x{1:X}" -f $P.Id, $AffinityMask)
    } catch {
        Add-Content -LiteralPath $RunLog -Value ("AFFINITY_FAILED pid={0} error={1}" -f $P.Id, $_.Exception.Message)
    }
    $P.WaitForExit()
    $P.StandardOutput.ReadToEnd() | Set-Content -LiteralPath $StdOut -Encoding UTF8
    $P.StandardError.ReadToEnd() | Set-Content -LiteralPath $StdErr -Encoding UTF8
    $P.Refresh()
    Add-Content -LiteralPath $RunLog -Value ("EXIT code={0}" -f $P.ExitCode)
    if ($P.ExitCode -ne 0) {
        throw "ngcc_bench failed: $($Version.Name) $Alg $Size $Mode round $Round"
    }

    $After = Get-ChildItem -LiteralPath $ReportDir -Filter "*.json" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $After) {
        throw "No JSON report generated for $($Version.Name) $Alg $Size"
    }
    if ($Before -and $After.FullName -eq $Before.FullName -and $After.LastWriteTime -le $Before.LastWriteTime) {
        throw "No fresh JSON report detected for $($Version.Name) $Alg $Size"
    }
    $JsonDest = Join-Path $JsonOut ($Prefix + ".json")
    Copy-Item -LiteralPath $After.FullName -Destination $JsonDest -Force
}

foreach ($Version in $Versions) {
    $ProjectRoot = Get-ProjectRoot -Version $Version
    $Build = Join-Path $ProjectRoot "build"
    cmake -S $ProjectRoot -B $Build | Out-Host
    cmake --build $Build -j | Out-Host
}

foreach ($Version in $Versions) {
    foreach ($Round in $Rounds) {
        foreach ($Alg in $Version.Algs) {
            foreach ($Size in $Sizes) {
                Invoke-NgccRetest -Version $Version -Alg $Alg -Size $Size -Mode "light" -Round $Round
            }
        }
    }
}

$FocusCsv = Join-Path $Root "performance_retest_focus_points.csv"
if (Test-Path -LiteralPath $FocusCsv) {
    $FocusRows = Import-Csv -LiteralPath $FocusCsv
    foreach ($Row in $FocusRows) {
        $Version = $Versions | Where-Object { $_.Name -eq $Row.version } | Select-Object -First 1
        if ($null -eq $Version) { continue }
        foreach ($Round in $FocusRounds) {
            Invoke-NgccRetest -Version $Version -Alg $Row.algorithm_id -Size ([int]$Row.input_bytes) -Mode "focus" -Round $Round
        }
    }
}
