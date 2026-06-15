@echo off
setlocal

set "WDK=C:\WinDDK\7600.16385.1"

:: WDK7 toolchain only (cl 15.00 = VS2008 SP1), no VS2008 dirs at all
set "PATH=%WDK%\bin\x86\x86;%WDK%\bin\x86;%PATH%"
set "INCLUDE=%WDK%\inc\api\crt\stl70;%WDK%\inc\atl71;%WDK%\inc\crt;%WDK%\inc\api;%WDK%\inc\ddk"
set "LIB=%WDK%\lib\win7\i386;%WDK%\lib\crt\i386;%WDK%\lib\atl\i386"

cd /d "%~dp0"

echo ============ cl version ============
cl 2>&1 | findstr /i Version

echo ============ 1) compile only ============
cl /nologo /c /W3 /GS /EHsc /wd4290 /D_STL70_ /D_STATIC_CPPLIB /D_DLL=1 /D_MT=1 /MD /O2 /Ob2 /DNDEBUG probe.cpp
echo [compile exit=%errorlevel%]

echo ============ 2) link explicitly ============
link /nologo /INCREMENTAL:NO /MANIFEST:NO /OUT:probe.exe probe.obj ^
   /NODEFAULTLIB:msvcrtd /DEFAULTLIB:ntstc_msvcrt /DEFAULTLIB:msvcrt /DEFAULTLIB:kernel32
set CLERR=%errorlevel%
echo [link exit=%CLERR%]
if not "%CLERR%"=="0" goto done

echo ============ imports (which CRT dll?) ============
link /dump /imports probe.exe | findstr /i ".dll"

echo ============ run ============
probe.exe
echo [run exit=%errorlevel%]

:done
endlocal
