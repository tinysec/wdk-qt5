@echo off
:: nmake install into the variant prefix, then (static only) inject the static
:: link deps into the Qt5 CMake configs so find_package consumers link cleanly.
:: QT_LINK = shared (default) | static.
setlocal
call "%~dp0wdk-env.bat"

if "%QT_LINK%"=="" set "QT_LINK=shared"
if "%QT_ARCH%"=="" set "QT_ARCH=i386"
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
set "BUILD=%REPO%\build-wdk-qtbase-%QT_ARCH%-%QT_LINK%"

cd /d "%BUILD%"
echo ============ nmake install (QT_LINK=%QT_LINK%) ============
nmake install
if errorlevel 1 ( echo [INSTALL FAILED] & exit /b 1 )

if /I "%QT_LINK%"=="static" (
    echo ============ patch static CMake deps ============
    python "%~dp0patch-static-cmake-deps.py" "%BUILD%\install"
)

:: QtSql has no driver (-no-sql-sqlite) and a UI library never uses it. Qt 5.6
:: has no flag to skip building it, so remove its artifacts from the prefix.
:: (Network and Xml are kept -- those are genuinely useful for GUI apps.)
echo ============ drop unused QtSql ============
del /q "%BUILD%\install\lib\Qt5Sql.lib" "%BUILD%\install\lib\Qt5Sql.prl" "%BUILD%\install\bin\Qt5Sql.dll" 2>nul
if exist "%BUILD%\install\include\QtSql"    rmdir /s /q "%BUILD%\install\include\QtSql"
if exist "%BUILD%\install\lib\cmake\Qt5Sql" rmdir /s /q "%BUILD%\install\lib\cmake\Qt5Sql"

echo ============ install done: %BUILD%\install ============
endlocal
