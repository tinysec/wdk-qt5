@echo off
:: Build an external Qt 5 module (e.g. qtcharts, qtdeclarative) against an already
:: built qtbase variant, installing it INTO the same prefix so find_package picks
:: it up (Qt5Charts, ...). The win32-wdk7-msvc2008 mkspec + wdk-compat.h shims
:: apply automatically because we drive the variant's own qmake.
::
:: Usage: build-extra-module.bat <path-to-module.pro>
::   e.g. build-extra-module.bat D:\src\qtcharts\qtcharts.pro
:: env: QT_LINK (shared|static), QT_ARCH (i386|amd64) select the qtbase variant.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"

set "QTBIN=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\bin"
set "PRO=%~f1"
if not exist "%PRO%" ( echo [module .pro not found: %PRO%] & exit /b 1 )

for %%P in ("%PRO%") do set "PRONAME=%%~nP"
set "MODBUILD=%REPO%\build-extra-%PRONAME%-%QT_ARCH%-%QT_LINK%"
if not exist "%MODBUILD%" mkdir "%MODBUILD%"
cd /d "%MODBUILD%"

echo ============ qmake %PRONAME% (QT_ARCH=%QT_ARCH% QT_LINK=%QT_LINK%) ============
"%QTBIN%\qmake.exe" "%PRO%"
if errorlevel 1 ( echo [QMAKE FAILED] & exit /b 1 )

echo ============ nmake qmake_all ============
nmake qmake_all

echo ============ nmake ============
nmake
if errorlevel 1 ( echo [BUILD FAILED] & exit /b 1 )

echo ============ nmake install (into the qtbase prefix) ============
nmake install
echo ============ done; re-run patch-static-cmake-deps.py for static ============
endlocal
