<# Build, run, sanitize, or clean every Polar-KEM implementation directory. #>
[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$RunKAT,
    [switch]$Sanitize
)

$ErrorActionPreference = 'Stop'

if ($Clean -and $Sanitize) {
    throw '-Clean and -Sanitize are mutually exclusive.'
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$families = @('Reference_Implementation', 'Optimized_Implementation')
$instances = @('PolarKEM-128', 'PolarKEM-256', 'PolarKEM-512')

foreach ($family in $families) {
    foreach ($instance in $instances) {
        $instanceDir = Join-Path (Join-Path $scriptRoot $family) $instance
        Write-Host "==> $family/$instance"
        Push-Location -LiteralPath $instanceDir
        try {
            if ($Clean) {
                & .\build.bat clean
            }
            elseif ($Sanitize) {
                & .\build.bat sanitize
            }
            else {
                & .\build.bat
            }

            if ($LASTEXITCODE -ne 0) {
                throw "Build command failed in $instanceDir with exit code $LASTEXITCODE."
            }

            if ($RunKAT -and -not $Clean) {
                & .\KAT_KEM.exe
                if ($LASTEXITCODE -ne 0) {
                    throw "KAT failed in $instanceDir with exit code $LASTEXITCODE."
                }
            }
        }
        finally {
            Pop-Location
        }
    }
}
