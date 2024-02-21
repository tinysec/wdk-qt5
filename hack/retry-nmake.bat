@echo off
:retry
nmake.exe
 
REM 检查nmake.exe的退出码
if %errorlevel% NEQ 0 (
    echo NMake failed with exit code %errorlevel%. Retrying...
    ping -n 5 127.0.0.1 > nul 2>&1
    goto retry
)