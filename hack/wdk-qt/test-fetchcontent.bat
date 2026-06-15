@echo off
:: Prove downstream FetchContent consumption of the CI-published prebuilt Qt.
setlocal
set "QT_ARCH=i386"
call "%~dp0wdk-env.bat"

set "T=%~dp0fetch-test"
set "B=%T%\build"
if exist "%B%" rmdir /s /q "%B%"

cmake -S "%T%" -B "%B%" -G "NMake Makefiles" ^
  -DCMAKE_TOOLCHAIN_FILE="%~dp0cmake-consumer\wdk7-toolchain.cmake" ^
  -DWDK7_ARCH=i386 -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 ( echo [CONFIGURE FAILED] & exit /b 1 )

cmake --build "%B%"
if errorlevel 1 ( echo [BUILD FAILED] & exit /b 1 )

echo ============ run (Qt from FetchContent prebuilt) ============
for /f "delims=" %%P in ('dir /s /b "%B%\_deps\Qt5Core.dll" 2^>nul') do set "QTDLL=%%~dpP"
set "PATH=%QTDLL%;%PATH%"
"%B%\app.exe"
echo [run exit=%errorlevel%]
endlocal
