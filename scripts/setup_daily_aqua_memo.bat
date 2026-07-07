@echo off
setlocal

rem ============================================================
rem Daily Aqua Memo setup script
rem - Helper that only runs git clone / fetch / switch / pull
rem - Does not commit, push, or create pull requests
rem - Does not run git reset --hard, git clean, or force push
rem - Never touches obsidian-vault
rem ============================================================

set "BASE_DIR=C:\Users\shuns\.claude\projects"
set "REPO_DIR=%BASE_DIR%\daily_aqua_memo"
set "REPO_URL=https://github.com/airesearchagl-art/daily_aqua_memo.git"
set "BRANCH=main"

echo === Daily Aqua Memo setup ===
echo repo : %REPO_URL%
echo path : %REPO_DIR%
echo.

git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git was not found. Install Git for Windows first.
    goto fail
)

if not exist "%BASE_DIR%" (
    mkdir "%BASE_DIR%"
    if errorlevel 1 (
        echo [ERROR] Could not create folder: %BASE_DIR%
        goto fail
    )
)

if exist "%REPO_DIR%\.git" goto update_repo
if exist "%REPO_DIR%" goto backup_and_clone
goto clone_repo

:update_repo
echo Updating the existing repository...
cd /d "%REPO_DIR%" || goto fail
git fetch origin
if errorlevel 1 (
    echo [ERROR] git fetch origin failed. Check network and authentication.
    goto fail
)
call :switch_branch
if errorlevel 1 (
    echo [ERROR] Could not switch to branch %BRANCH%.
    goto fail
)
git pull --ff-only origin %BRANCH%
if errorlevel 1 (
    echo [WARN] git pull --ff-only failed. You may have local changes.
    echo [WARN] This script never runs reset or clean. Check the state manually.
)
goto show_result

:backup_and_clone
echo The daily_aqua_memo folder exists but has no .git directory.
echo It will be renamed to a backup folder before cloning. Nothing is deleted.
set "TS="
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%i"
if not defined TS (
    echo [ERROR] Could not get a timestamp.
    goto fail
)
ren "%REPO_DIR%" "daily_aqua_memo_backup_%TS%"
if errorlevel 1 (
    echo [ERROR] Could not rename to backup: %REPO_DIR%
    goto fail
)
echo Backup: %BASE_DIR%\daily_aqua_memo_backup_%TS%
goto clone_repo

:clone_repo
echo Cloning the repository...
cd /d "%BASE_DIR%" || goto fail
git clone %REPO_URL% daily_aqua_memo
if errorlevel 1 (
    echo [ERROR] git clone failed. Check network and authentication.
    goto fail
)
cd /d "%REPO_DIR%" || goto fail
call :switch_branch
if errorlevel 1 (
    echo [ERROR] Could not switch to branch %BRANCH%.
    goto fail
)
goto show_result

:show_result
echo.
echo --- current branch ---
git branch --show-current
echo.
echo --- git status --short ---
git status --short
echo.
echo --- git log --oneline -5 ---
git log --oneline -5
echo.
echo Setup finished. Next, run:
echo   scripts\run_daily_aqua_memo.bat
echo.
pause
exit /b 0

:fail
echo.
echo Setup was cancelled. Check the error message above.
pause
exit /b 1

rem ------------------------------------------------------------
rem :switch_branch subroutine
rem Switches to %BRANCH% and returns errorlevel 0 on success.
rem - If the local branch exists, plain "git switch" is used.
rem   Being already on the branch is a success, not an error.
rem - A tracking branch is created only when the local branch
rem   does not exist and origin/%BRANCH% exists.
rem - If neither exists, this returns an error.
rem ------------------------------------------------------------
:switch_branch
git show-ref --verify --quiet refs/heads/%BRANCH%
if errorlevel 1 goto sb_create_tracking
git switch %BRANCH%
if errorlevel 1 exit /b 1
exit /b 0

:sb_create_tracking
git show-ref --verify --quiet refs/remotes/origin/%BRANCH%
if errorlevel 1 (
    echo [ERROR] origin/%BRANCH% was not found.
    exit /b 1
)
git switch -c %BRANCH% --track origin/%BRANCH%
if errorlevel 1 exit /b 1
exit /b 0
