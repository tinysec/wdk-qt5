@echo off
setlocal
call "%~dp0wdk-env.bat"

:: QT_LINK = shared (default) | static  -> selects -shared/-static + build dir.
if "%QT_LINK%"=="" set "QT_LINK=shared"
if /I "%QT_LINK%"=="static" ( set "LINKFLAG=-static" ) else ( set "QT_LINK=shared" & set "LINKFLAG=-shared" )

:: Repo root = two levels up from this script (hack\wdk-qt -> repo root).
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "SRC=%REPO%\qtbase"
set "BUILD=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%"

if not exist "%BUILD%" mkdir "%BUILD%"
cd /d "%BUILD%"

echo ============ cl in use (QT_LINK=%QT_LINK%) ============
where cl
cl 2>&1 | findstr /i Version

echo ============ configure qtbase (WDK7, %LINKFLAG%) ============
call "%SRC%\configure.bat" -platform win32-wdk7-msvc2008 -make-tool nmake -release %LINKFLAG% -opensource -confirm-license -mp ^
  -nomake examples -nomake tests -no-compile-examples ^
  -no-openssl -no-freetype -no-harfbuzz -no-iconv ^
  -no-dbus ^
  -no-direct2d -no-directwrite -no-style-fusion ^
  -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre ^
  -no-sql-sqlite -no-opengl ^
  -prefix "%BUILD%\install"

echo ============ configure exit=%errorlevel% ============
endlocal
