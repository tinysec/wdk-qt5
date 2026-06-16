@echo off
:: Prove the WDK7-built Qt5Charts is consumable by a CMake project via
:: find_package(Qt5 COMPONENTS Charts), in both shared and static link modes.
:: QT_LINK = shared (default) | static ; QT_ARCH = i386 (default) | amd64.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "QTPREFIX=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\install"
set "T=%~dp0charts-consumer"
set "B=%T%\build-%QT_ARCH%-%QT_LINK%"

if exist "%B%" rmdir /s /q "%B%"

cmake -S "%T%" -B "%B%" -G "NMake Makefiles" ^
  -DCMAKE_TOOLCHAIN_FILE="%T%\wdk7-toolchain.cmake" ^
  -DWDK7_ARCH=%QT_ARCH% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH="%QTPREFIX%"
if errorlevel 1 ( echo [CMAKE CONFIGURE FAILED] & exit /b 1 )

cmake --build "%B%"
if errorlevel 1 ( echo [CMAKE BUILD FAILED] & exit /b 1 )

echo ============ run (QT_LINK=%QT_LINK%) ============
set "PATH=%QTPREFIX%\bin;%QTPREFIX%\lib;%PATH%"
"%B%\chartsapp.exe"
if errorlevel 1 ( echo [CHARTS APP RUN FAILED] & exit /b 1 )
echo [charts consume OK]
endlocal
