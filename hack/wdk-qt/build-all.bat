@echo off
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "BUILD=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%"
cd /d "%BUILD%"

echo ============ regenerate makefiles (qmake_all) ============
nmake qmake_all

echo ============ build qtbase (nmake from root: bootstrap -> tools -> libs -> plugins) ============
nmake
echo ============ root nmake exit=%errorlevel% ============
endlocal
