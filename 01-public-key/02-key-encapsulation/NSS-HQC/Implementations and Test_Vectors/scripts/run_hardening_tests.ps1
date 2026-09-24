param()
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$implRoot = Join-Path $root "Implementations/Reference_Implementation"
$bash = "C:\msys64\usr\bin\bash.exe"
function Convert-ToMsysPath([string]$Path) {
  $full=(Resolve-Path $Path).Path
  if($full -match '^([A-Za-z]):\\(.*)$'){ return "/$($matches[1].ToLower())/$($matches[2] -replace '\\','/')" }
  return ($full -replace '\\','/')
}
foreach($instance in @('HQC-128','HQC-256','HQC-384','HQC-512')){
  $dir=Join-Path $implRoot $instance
  $msys=Convert-ToMsysPath $dir
  $cmd="export MSYSTEM=UCRT64; export PATH=/ucrt64/bin:/usr/bin:`$PATH; cd '$msys' && make hardening"
  Write-Host "==> $instance"
  & $bash -lc $cmd
  if($LASTEXITCODE -ne 0){ throw "Hardening test failed for $instance" }
}
