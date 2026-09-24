$ErrorActionPreference = 'Stop'
$Algorithms = @('iphe-512', 'iphe-768', 'iphe-1024')
$Lengths = @(32, 128, 512, 1024, 4096, 8192, 16384, 65536)
$Times = 1000
foreach ($algorithm in $Algorithms) {
  foreach ($length in $Lengths) {
    & .\build\ngcc_bench.exe -a $algorithm -t $Times -l $length
    if ($LASTEXITCODE -ne 0) { throw "NGCC failed: $algorithm, $length Bytes" }
  }
}
