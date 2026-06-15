@echo off
:: QT_LINK = shared (default) | static -> builds the testapp against that variant.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "QTBIN=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\bin"
set "QTLIB=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\lib"
set "APP=%~dp0testapp"

cd /d "%APP%"
if exist Makefile del /q Makefile >nul 2>&1
if exist release rmdir /s /q release >nul 2>&1

echo ============ qmake (QT_LINK=%QT_LINK%) ============
"%QTBIN%\qmake.exe" testapp.pro -o Makefile
if errorlevel 1 exit /b 1

echo ============ nmake ============
nmake
if errorlevel 1 exit /b 1

echo ============ imports ============
link /dump /imports "%APP%\release\testapp.exe" | findstr /i ".dll"

echo ============ run ============
set "PATH=%QTLIB%;%PATH%"
"%APP%\release\testapp.exe"
echo [run exit=%errorlevel%]
endlocal
