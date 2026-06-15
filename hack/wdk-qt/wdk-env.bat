@echo off
:: WDK 7.1 user-mode toolchain environment, no setenv.bat (it crashes under
:: cmd /c due to its OACR/doskey/Makedirs steps).
::
:: WDK root: W7BASE / WDK7_ROOT (set by tinysec/setup-wdk7 in CI) -> default.
:: QT_ARCH = i386 (default) | amd64  -> selects the cross compiler + libs.

if not "%W7BASE%"=="" set "WDK=%W7BASE%"
if "%WDK%"=="" if not "%WDK7_ROOT%"=="" set "WDK=%WDK7_ROOT%"
if "%WDK%"=="" set "WDK=C:\WinDDK\7600.16385.1"

if "%QT_ARCH%"=="" set "QT_ARCH=i386"

set "SHIM=%~dp0shim"

:: Compiler dir: bin\x86\x86 targets x86; bin\x86\amd64 cross-targets x64.
if /I "%QT_ARCH%"=="amd64" ( set "CLDIR=%WDK%\bin\x86\amd64" ) else ( set "QT_ARCH=i386" & set "CLDIR=%WDK%\bin\x86\x86" )

set "PATH=%CLDIR%;%WDK%\bin\x86;%PATH%"

:: Headers (arch-independent): shim first (intrin.h/windns.h the WDK omits),
:: then STL70, ATL71, CRT, user-mode SDK (api), DDK.
set "INCLUDE=%SHIM%;%WDK%\inc\api\crt\stl70;%WDK%\inc\atl71;%WDK%\inc\crt;%WDK%\inc\api;%WDK%\inc\ddk"

:: Libs for the selected arch: platform (kernel32 etc.), CRT, ATL.
set "LIB=%WDK%\lib\win7\%QT_ARCH%;%WDK%\lib\crt\%QT_ARCH%;%WDK%\lib\atl\%QT_ARCH%"
