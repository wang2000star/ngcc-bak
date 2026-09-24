@echo off
setlocal EnableExtensions

cd /d "%~dp0\.."
set "CC=gcc"
set "REF_CFLAGS=-std=c99 -Wpedantic -Wall -Wextra -O2"
set "PERF_CFLAGS=-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
set "BUILD=build\iphe512_boundaries"
set "REF_DIR=Implementations\Reference_Implementation\Iphe-512"
set "PERF_DIR=Implementations\Optimized_Implementation\Performance_Implementation\Iphe-512"

if not exist "%BUILD%" mkdir "%BUILD%"

%CC% %REF_CFLAGS% -I"%REF_DIR%" -include CryptHash_AlgorithmInstance.h "scripts\test_iphe512_boundaries.c" "%REF_DIR%\CryptHash_AlgorithmInstance.c" -o "%BUILD%\ref_iphe512_boundaries.exe"
if errorlevel 1 exit /b 1
%CC% %PERF_CFLAGS% -I"%PERF_DIR%" -include CryptHash_AlgorithmInstance.h "scripts\test_iphe512_boundaries.c" "%PERF_DIR%\CryptHash_AlgorithmInstance.c" -o "%BUILD%\perf_iphe512_boundaries.exe"
if errorlevel 1 exit /b 1

"%BUILD%\ref_iphe512_boundaries.exe" > "%BUILD%\ref.out"
if errorlevel 1 exit /b 1
"%BUILD%\perf_iphe512_boundaries.exe" > "%BUILD%\perf.out"
if errorlevel 1 exit /b 1

cmd /c fc /b "%BUILD%\ref.out" "%BUILD%\perf.out" >nul
if errorlevel 1 (
    echo FAIL Iphe-512 boundary consistency check
    cmd /c fc "%BUILD%\ref.out" "%BUILD%\perf.out"
    exit /b 1
)

echo PASS Iphe-512 boundary consistency check
exit /b 0
