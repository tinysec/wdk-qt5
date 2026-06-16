@echo off
:: Prove the WDK7-built Qt5Charts is consumable as a real GUI app: build an MDI
:: charts window (line/spline/pie/bar/scatter) via find_package(Qt5 Charts) and
:: run it in --shot mode (renders to a PNG and exits). Exercises the static
:: platform-plugin link path. QT_LINK = shared (default) | static.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "QTPREFIX=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\install"
set "T=%~dp0charts-consumer"
set "B=%T%\build-%QT_ARCH%-%QT_LINK%"

set "STATIC_FLAG="
if /I "%QT_LINK%"=="static" set "STATIC_FLAG=-DCONSUME_STATIC=ON"

if exist "%B%" rmdir /s /q "%B%"

cmake -S "%T%" -B "%B%" -G "NMake Makefiles" ^
  -DCMAKE_TOOLCHAIN_FILE="%T%\wdk7-toolchain.cmake" ^
  -DWDK7_ARCH=%QT_ARCH% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH="%QTPREFIX%" ^
  %STATIC_FLAG%
if errorlevel 1 ( echo [CMAKE CONFIGURE FAILED] & exit /b 1 )

cmake --build "%B%"
if errorlevel 1 ( echo [CMAKE BUILD FAILED] & exit /b 1 )

echo ============ run MDI charts app (--shot) QT_LINK=%QT_LINK% ============
set "PATH=%QTPREFIX%\bin;%QTPREFIX%\lib;%PATH%"
:: start /wait reliably waits for the WIN32 GUI process and keeps the console
:: intact for the checks below (a directly-launched GUI exe detaches stdout).
start "" /wait "%B%\chartsmdi.exe" --shot "%B%\mdi.png"
if errorlevel 1 ( echo [CHARTS MDI RUN FAILED] & exit /b 1 )
if not exist "%B%\mdi.png" ( echo [NO SCREENSHOT PRODUCED] & exit /b 1 )
echo [charts MDI OK -> mdi.png]
endlocal
