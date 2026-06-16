@echo off
:: Build vendored qtcharts (src/charts; chartsqml2 auto-skips without QtQuick)
:: against an existing qtbase build, using the WDK7 toolchain, and install it
:: into the same prefix so find_package(Qt5Charts) works.
:: env: QT_ARCH (i386|amd64), QT_LINK (shared|static) select the qtbase variant.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"

set "QTBIN=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\bin"
set "SRC=%REPO%\qtcharts"
set "BUILD=%REPO%\build-qtcharts-%QT_ARCH%-%QT_LINK%"

if not exist "%BUILD%" mkdir "%BUILD%"

echo ============ syncqt (generate forwarding headers if missing) ============
if not exist "%SRC%\include\QtCharts\2.1.3\QtCharts\private" (
    where perl >nul 2>&1 || ( echo [perl not found - needed for syncqt] & exit /b 1 )
    perl "%REPO%\qtbase\bin\syncqt.pl" "%SRC%" -outdir "%SRC%" -version 2.1.3 -windows -quiet
    if errorlevel 1 ( echo [SYNCQT FAILED] & exit /b 1 )
)

cd /d "%BUILD%"

echo ============ qmake qtcharts (QT_ARCH=%QT_ARCH% QT_LINK=%QT_LINK%) ============
"%QTBIN%\qmake.exe" "%SRC%\qtcharts.pro"
if errorlevel 1 ( echo [QMAKE FAILED] & exit /b 1 )

echo ============ nmake qmake_all ============
nmake qmake_all

echo ============ nmake ============
nmake
if errorlevel 1 ( echo [BUILD FAILED] & exit /b 1 )

echo ============ nmake install (into the qtbase prefix) ============
nmake install

if /I "%QT_LINK%"=="static" (
    echo ============ patch static CMake deps (now incl. Qt5Charts) ============
    python "%~dp0patch-static-cmake-deps.py" "%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\install"
)

echo ============ qtcharts done (QT_ARCH=%QT_ARCH% QT_LINK=%QT_LINK%) ============
endlocal
