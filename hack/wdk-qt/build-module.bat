@echo off
:: Build a single qtbase src subtree directly (bypassing failed siblings).
:: Usage: build-module.bat <subdir-under-src>   e.g.  build-module.bat gui
:: QT_LINK = shared (default) | static.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
cd /d "%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\src\%1"

echo ============ build module: %1 (QT_LINK=%QT_LINK%) ============
nmake
echo ============ module %1 nmake exit=%errorlevel% ============
endlocal
