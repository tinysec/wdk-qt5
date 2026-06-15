@echo off
:: Prove the WDK7-built Qt is consumable by a CMake project via find_package(Qt5)
:: using the setup-wdk7 toolchain. QT_LINK = shared (default) | static.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "QTPREFIX=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%\install"
set "T=%~dp0cmake-consumer"
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

echo ============ imports (QT_LINK=%QT_LINK%) ============
"%WDK%\bin\x86\x86\link.exe" /dump /imports "%B%\app.exe" 2>nul | findstr /i ".dll"

echo ============ run ============
set "PATH=%QTPREFIX%\bin;%QTPREFIX%\lib;%PATH%"
"%B%\app.exe"
echo [run exit=%errorlevel%]
endlocal
