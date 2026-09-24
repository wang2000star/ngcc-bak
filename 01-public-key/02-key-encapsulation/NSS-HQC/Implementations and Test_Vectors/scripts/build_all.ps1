param(
    [switch]$Kat
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$implRoot = Join-Path $root "Implementations"
$vectorRoot = Join-Path $root "Test_Vectors"
$tmpRoot = Join-Path $root ".build_tmp\msys2_tmp"
$homeRoot = Join-Path $tmpRoot "home"
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
New-Item -ItemType Directory -Path $homeRoot -Force | Out-Null

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

function Test-AsciiPath {
    param([string]$Path)

    foreach ($ch in $Path.ToCharArray()) {
        if ([int][char]$ch -gt 127) {
            return $false
        }
    }
    return $true
}

function New-TempDriveMapping {
    param([string]$TargetPath)

    if (Test-AsciiPath $TargetPath) {
        return $null
    }

    foreach ($letter in ("Z", "Y", "X", "W", "V", "U", "T", "S", "R", "Q", "P")) {
        $drive = "${letter}:"
        if (-not (Test-Path "${drive}\")) {
            & cmd.exe /c "subst $drive `"$TargetPath`""
            if ($LASTEXITCODE -eq 0) {
                return $drive
            }
        }
    }
    throw "Unable to create an ASCII subst drive for temporary directory: $TargetPath"
}

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
    throw "Missing MSYS2 bash. Install MSYS2, or add C:\msys64\usr\bin to PATH."
}

function Convert-ToMsysPath {
    param([string]$Path)

    $full = (Resolve-Path $Path).Path
    if ($full -match '^([A-Za-z]):\\(.*)$') {
        $drive = $matches[1].ToLower()
        $rest = $matches[2] -replace '\\', '/'
        return "/$drive/$rest"
    }
    if ($full -match '^([A-Za-z]):\\?$') {
        return "/$($matches[1].ToLower())"
    }
    return ($full -replace '\\', '/')
}

$substDrive = $null
try {
    $tmpEnvWin = (Resolve-Path $tmpRoot).Path
    $substDrive = New-TempDriveMapping -TargetPath $tmpEnvWin
    if ($substDrive) {
        $tmpEnvWin = "${substDrive}\"
        $homeEnvWin = Join-Path $tmpEnvWin "home"
    } else {
        $homeEnvWin = (Resolve-Path $homeRoot).Path
    }
    New-Item -ItemType Directory -Path $homeEnvWin -Force | Out-Null

    $msysTmp = Convert-ToMsysPath $tmpEnvWin
    $msysHome = Convert-ToMsysPath $homeEnvWin

    function Invoke-BashBuild {
        param(
            [string]$TargetName,
            [string]$InstanceDir,
            [string]$BashExe,
            [switch]$RunKat
        )

        $msysDir = Convert-ToMsysPath $InstanceDir
        if ($RunKat) {
            $cmd = "export HOME='$msysHome'; export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; export TMPDIR='$msysTmp'; export TMP='$tmpEnvWin'; export TEMP='$tmpEnvWin'; cd '$msysDir' && make clean && make test"
        } else {
            $cmd = "export HOME='$msysHome'; export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; export TMPDIR='$msysTmp'; export TMP='$tmpEnvWin'; export TEMP='$tmpEnvWin'; cd '$msysDir' && make clean && make selftest"
        }

        Write-Host "    $BashExe -lc `"$cmd`""
        & $BashExe -lc $cmd
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Build failed in $TargetName with exit code $exitCode"
        }
    }

    $bash = Resolve-MsysBash
    & $bash -lc "export HOME='$msysHome'; export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; export TMPDIR='$msysTmp'; export TMP='$tmpEnvWin'; export TEMP='$tmpEnvWin'; command -v make >/dev/null && (command -v gcc >/dev/null || command -v clang >/dev/null)"
    if ($LASTEXITCODE -ne 0) {
        throw "Missing make or gcc/clang inside MSYS2 bash. Install base-devel and a UCRT64 toolchain first."
    }

    $passed = 0
    foreach ($target in $targets) {
        $dir = Join-Path $implRoot $target
        if (-not (Test-Path $dir)) {
            throw "Missing implementation directory: $target"
        }

        Write-Host "==> $target"
        Invoke-BashBuild -TargetName $target -InstanceDir $dir -BashExe $bash -RunKat:$Kat
        $passed++
    }

    if ($Kat) {
        New-Item -ItemType Directory -Path $vectorRoot -Force | Out-Null
        foreach ($instance in @("HQC-128", "HQC-256", "HQC-384", "HQC-512")) {
            $refKat = Join-Path $implRoot "Reference_Implementation/$instance/output/KAT_KEM_$instance.txt"
            $optKat = Join-Path $implRoot "Optimized_Implementation/$instance/output/KAT_KEM_$instance.txt"
            if (-not (Test-Path $refKat)) {
                throw "Missing Reference submission-candidate KAT: $refKat"
            }
            if (-not (Test-Path $optKat)) {
                throw "Missing Optimized submission-candidate KAT: $optKat"
            }

            $refHash = (Get-FileHash -Algorithm SHA256 -Path $refKat).Hash
            $optHash = (Get-FileHash -Algorithm SHA256 -Path $optKat).Hash
            if ($refHash -ne $optHash) {
                throw "Reference/Optimized submission-candidate KAT mismatch for $instance"
            }

            Copy-Item -Force -Path $refKat -Destination (Join-Path $vectorRoot "KAT_KEM_$instance.txt")
            Write-Host "Submission-candidate KAT $instance SHA256=$refHash"
        }
        Write-Host "All selftests and KAT generation steps passed for $passed implementation instances."
    } else {
        Write-Host "All selftests passed for $passed implementation instances."
    }
} finally {
    if ($substDrive) {
        & cmd.exe /c "subst $substDrive /D" | Out-Null
    }
}
