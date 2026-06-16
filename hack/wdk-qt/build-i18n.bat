@echo off
:: Build the Qt Linguist i18n tools (lrelease, lupdate) against the variant's
:: qtbase and install them into the prefix bin/. Runtime i18n (QTranslator,
:: QLocale, tr()) is already in QtCore; these tools let a developer compile their
:: own translations (.ts -> .qm) and extract tr() strings (source -> .ts).
::
:: Notes:
::  - Build dirs live at the repo root, NOT under the qtbase build dir, or qmake
::    picks up qtbase's .qmake config and fails with "no top-level .qmake.conf".
::  - Use "nmake release": the default "all" also builds a debug binary, which
::    needs msvcrtd (excluded by our zero-redist recipe) and would fail.
::  - "-after DESTDIR=..." redirects the tool exe into the build dir (otherwise a
::    standalone tool build drops it at <drive>:\bin).
::  - lupdate needs its UAC manifest embedded: its .pro only sets RC_FILE for
::    MinGW, and our build disables MSVC manifest embedding, so without this
::    Windows installer-detection flags the "update" name and demands elevation.
::    We force RC_FILE so WDK rc.exe embeds the asInvoker manifest.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "BUILD=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%"
set "QM=%BUILD%\bin\qmake.exe"
set "LING=%REPO%\qttools\src\linguist"
set "BIN=%BUILD%\install\bin"

echo ============ build lrelease ============
set "O=%REPO%\build-i18n-%QT_ARCH%-%QT_LINK%-lrelease"
if exist "%O%" rmdir /s /q "%O%"
mkdir "%O%"
cd /d "%O%"
"%QM%" "%LING%\lrelease\lrelease.pro" -after "DESTDIR=%O%"
if errorlevel 1 ( echo [LRELEASE QMAKE FAILED] & exit /b 1 )
nmake release
if errorlevel 1 ( echo [LRELEASE BUILD FAILED] & exit /b 1 )
copy /y "%O%\lrelease.exe" "%BIN%\"
if errorlevel 1 ( echo [LRELEASE COPY FAILED] & exit /b 1 )

echo ============ build lupdate (with UAC manifest) ============
set "O=%REPO%\build-i18n-%QT_ARCH%-%QT_LINK%-lupdate"
if exist "%O%" rmdir /s /q "%O%"
mkdir "%O%"
cd /d "%O%"
"%QM%" "%LING%\lupdate\lupdate.pro" -after "DESTDIR=%O%" "RC_FILE=%LING%\lupdate\lupdate.rc"
if errorlevel 1 ( echo [LUPDATE QMAKE FAILED] & exit /b 1 )
nmake release
if errorlevel 1 ( echo [LUPDATE BUILD FAILED] & exit /b 1 )
copy /y "%O%\lupdate.exe" "%BIN%\"
if errorlevel 1 ( echo [LUPDATE COPY FAILED] & exit /b 1 )

echo ============ i18n tools installed: %BIN%\lrelease.exe + lupdate.exe ============
endlocal
