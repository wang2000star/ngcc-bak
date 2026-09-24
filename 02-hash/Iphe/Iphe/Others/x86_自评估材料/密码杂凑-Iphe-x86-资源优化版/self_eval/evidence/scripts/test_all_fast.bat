@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0\.."
set "CC=gcc"
set "REF_CFLAGS=-std=c99 -Wpedantic -Wall -Wextra -O2"
set "PERF_CFLAGS=-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
set "RES_CFLAGS=-Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
set "BUILD=build\fast"
set "FAIL=0"

if not exist "%BUILD%" mkdir "%BUILD%"

call :test_group Reference_Implementation REF "%REF_CFLAGS%"
call :test_group Optimized_Implementation\Performance_Implementation PERF "%PERF_CFLAGS%"
call :test_group Optimized_Implementation\Resource_Implementation RESOURCE "%RES_CFLAGS%"

for %%I in (Iphe-512 Iphe-768 Iphe-1024) do (
    fc /b "%BUILD%\REF_%%I.digest" "%BUILD%\PERF_%%I.digest" >nul
    if errorlevel 1 (
        echo FAIL consistency check REF vs PERF %%I
        set "FAIL=1"
    )
    fc /b "%BUILD%\REF_%%I.digest" "%BUILD%\RESOURCE_%%I.digest" >nul
    if errorlevel 1 (
        echo FAIL consistency check REF vs RESOURCE %%I
        set "FAIL=1"
    )
)

if "%FAIL%"=="0" (
    echo PASS fast selftests and multi-implementation consistency check
    exit /b 0
)

echo FAIL fast selftests or multi-implementation consistency check
exit /b 1

:test_group
set "GROUP_PATH=%~1"
set "LABEL=%~2"
set "CFLAGS=%~3"
for %%I in (Iphe-512 Iphe-768 Iphe-1024) do (
    call :test_instance "%GROUP_PATH%" "%LABEL%" "%CFLAGS%" "%%I"
)
exit /b 0

:test_instance
set "GROUP_PATH=%~1"
set "LABEL=%~2"
set "CFLAGS=%~3"
set "INST=%~4"
set "DIR=Implementations\%GROUP_PATH%\%INST%"
echo Building %LABEL% %INST%
%CC% %CFLAGS% "%DIR%\iphe_selftest.c" "%DIR%\CryptHash_AlgorithmInstance.c" -o "%BUILD%\%LABEL%_%INST%_selftest.exe"
if errorlevel 1 (
    echo FAIL compile selftest %LABEL% %INST%
    set "FAIL=1"
    exit /b 0
)
"%BUILD%\%LABEL%_%INST%_selftest.exe"
if errorlevel 1 (
    echo FAIL run selftest %LABEL% %INST%
    set "FAIL=1"
)
%CC% %CFLAGS% -I"%DIR%" -include CryptHash_AlgorithmInstance.h "scripts\digest_probe.c" "%DIR%\CryptHash_AlgorithmInstance.c" -o "%BUILD%\%LABEL%_%INST%_probe.exe"
if errorlevel 1 (
    echo FAIL compile digest probe %LABEL% %INST%
    set "FAIL=1"
    exit /b 0
)
"%BUILD%\%LABEL%_%INST%_probe.exe" > "%BUILD%\%LABEL%_%INST%.digest"
if errorlevel 1 (
    echo FAIL run digest probe %LABEL% %INST%
    set "FAIL=1"
)
exit /b 0
