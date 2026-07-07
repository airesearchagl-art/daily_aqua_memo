@echo off
setlocal

rem ============================================================
rem Daily Aqua Memo setup script
rem - Helper for an ALREADY CLONED repository
rem - Shows repository status and updates the CURRENT branch only
rem - Runs only: git fetch origin / git pull --ff-only
rem - Never switches branches and never creates branches
rem - Does not clone, commit, push, or create pull requests
rem - Does not run git reset --hard, git clean, or force push
rem - Never touches obsidian-vault
rem
rem For the initial clone, follow the manual steps in README.md.
rem ============================================================

set "REPO_URL=https://github.com/airesearchagl-art/daily_aqua_memo.git"

git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git was not found. Install Git for Windows first.
    goto fail
)

rem Move from this script's location to the repository root
cd /d "%~dp0.." || goto fail
set "REPO_DIR=%CD%"

if not exist "%REPO_DIR%\.git" (
    echo [ERROR] This folder is not a git repository: %REPO_DIR%
    echo Clone the repository first. See README.md for the initial clone steps.
    goto fail
)

echo === Daily Aqua Memo setup ===
echo repo : %REPO_URL%
echo path : %REPO_DIR%
echo.

set "CUR_BRANCH="
for /f "delims=" %%i in ('git branch --show-current') do set "CUR_BRANCH=%%i"
if not defined CUR_BRANCH (
    echo [ERROR] Could not determine the current branch. HEAD may be detached.
    goto fail
)
echo current branch : %CUR_BRANCH%
echo This script stays on the current branch. It never switches branches.
echo.

echo Fetching from origin...
git fetch origin
if errorlevel 1 (
    echo [ERROR] git fetch origin failed. Check network and authentication.
    goto fail
)

rem Update the current branch only when it has an upstream
set "UPSTREAM="
for /f "delims=" %%i in ('git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2^>nul') do set "UPSTREAM=%%i"
if not defined UPSTREAM (
    echo [WARN] No upstream is configured for the current branch.
    echo Skip pull. Use git pull manually if needed.
    goto show_result
)

echo upstream : %UPSTREAM%
git pull --ff-only
if errorlevel 1 (
    echo [WARN] git pull --ff-only failed. You may have local changes.
    echo [WARN] This script never runs reset or clean. Check the state manually.
)
goto show_result

:show_result
echo.
echo --- current branch ---
git branch --show-current
echo.
echo --- upstream ---
if defined UPSTREAM (echo %UPSTREAM%) else (echo none)
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
