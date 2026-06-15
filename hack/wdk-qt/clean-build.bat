@echo off
:: Full clean rebuild: wipe the variant build dir, reconfigure, build everything.
:: QT_LINK = shared (default) | static.
setlocal

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "BUILD=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%"
if exist "%BUILD%" rmdir /s /q "%BUILD%"

echo ############ CONFIGURE (QT_LINK=%QT_LINK%) ############
call "%~dp0configure-qtbase.bat"
if errorlevel 1 (
    echo [CONFIGURE FAILED]
    exit /b 1
)

echo ############ BUILD ############
call "%~dp0build-all.bat"

endlocal
