@echo off
setlocal

rem ============================================================
rem Daily Aqua Memo run script
rem - Finds AutoHotkey v2 and starts daily_aqua_memo.ahk
rem - Does not download AutoHotkey
rem - Does not modify registry or file associations
rem - Does not require administrator privileges
rem ============================================================

rem Move from this script's location to the repository root
cd /d "%~dp0.." || goto fail
set "REPO_DIR=%CD%"

if not exist "%REPO_DIR%\daily_aqua_memo.ahk" (
    echo [ERROR] daily_aqua_memo.ahk was not found: %REPO_DIR%
    echo Run scripts\setup_daily_aqua_memo.bat first.
    goto fail
)

rem --- Search for AutoHotkey v2 candidates ---
set "AHK_EXE="
if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\AutoHotkey64.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\AutoHotkey64.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe"
if not defined AHK_EXE for /f "delims=" %%i in ('where AutoHotkey64.exe 2^>nul') do if not defined AHK_EXE set "AHK_EXE=%%i"
if not defined AHK_EXE for /f "delims=" %%i in ('where AutoHotkey.exe 2^>nul') do if not defined AHK_EXE set "AHK_EXE=%%i"

if not defined AHK_EXE goto ahk_not_found

echo AutoHotkey found: %AHK_EXE%
echo Starting Daily Aqua Memo...
start "" "%AHK_EXE%" "%REPO_DIR%\daily_aqua_memo.ahk"
echo Started. The app stays in the task tray. Use Ctrl+Alt+M to open the memo form.
exit /b 0

:ahk_not_found
echo [ERROR] AutoHotkey v2 was not found.
echo.
echo Install AutoHotkey v2 from:
echo https://www.autohotkey.com/
echo.
echo Note: if Windows shows an "app picker" dialog when you open a .ahk
echo file, AutoHotkey is not installed or the .ahk file association is
echo not set. Installing AutoHotkey v2 sets the association so that
echo double-clicking the script starts it.
echo.
echo This script does not download AutoHotkey.
echo This script does not modify registry or file associations.
echo Run this script again after installing AutoHotkey v2.
pause
exit /b 1

:fail
echo.
echo Startup was cancelled. Check the error message above.
pause
exit /b 1
