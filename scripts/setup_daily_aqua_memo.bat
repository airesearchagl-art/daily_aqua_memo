@echo off
chcp 65001 >nul
setlocal

rem ============================================================
rem Daily Aqua Memo setup script
rem   - git clone / fetch / switch / pull のみを行う補助スクリプト
rem   - commit / push / PR作成 / reset --hard / clean は行わない
rem   - obsidian-vault には一切触れない
rem ============================================================

set "BASE_DIR=C:\Users\shuns\.claude\projects"
set "REPO_DIR=%BASE_DIR%\daily_aqua_memo"
set "REPO_URL=https://github.com/airesearchagl-art/daily_aqua_memo.git"
set "BRANCH=feature/mvp-local-outbox"

echo === Daily Aqua Memo setup ===
echo repo : %REPO_URL%
echo path : %REPO_DIR%
echo.

git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git が見つかりません。Git for Windows をインストールしてください。
    goto fail
)

if not exist "%BASE_DIR%" (
    mkdir "%BASE_DIR%"
    if errorlevel 1 (
        echo [ERROR] フォルダを作成できません: %BASE_DIR%
        goto fail
    )
)

if exist "%REPO_DIR%\.git" goto update_repo
if exist "%REPO_DIR%" goto backup_and_clone
goto clone_repo

:update_repo
echo 既存リポジトリを更新します...
cd /d "%REPO_DIR%" || goto fail
git fetch origin
if errorlevel 1 (
    echo [ERROR] git fetch origin に失敗しました。ネットワークと認証を確認してください。
    goto fail
)
git switch %BRANCH% >nul 2>&1
if errorlevel 1 (
    git switch -c %BRANCH% --track origin/%BRANCH%
    if errorlevel 1 (
        echo [ERROR] ブランチ %BRANCH% へ切り替えられませんでした。
        goto fail
    )
)
git pull --ff-only
if errorlevel 1 (
    echo [WARN] git pull --ff-only に失敗しました。ローカルに未pushの変更がある可能性があります。
    echo [WARN] このスクリプトは reset や clean を行わないため、手動で状態を確認してください。
)
goto show_result

:backup_and_clone
echo daily_aqua_memo フォルダは存在しますが .git がありません。
echo 削除はせず、バックアップへリネームしてから clone します。
set "TS="
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%i"
if not defined TS (
    echo [ERROR] タイムスタンプを取得できませんでした。
    goto fail
)
ren "%REPO_DIR%" "daily_aqua_memo_backup_%TS%"
if errorlevel 1 (
    echo [ERROR] バックアップへのリネームに失敗しました: %REPO_DIR%
    goto fail
)
echo 退避先: %BASE_DIR%\daily_aqua_memo_backup_%TS%
goto clone_repo

:clone_repo
echo リポジトリを clone します...
cd /d "%BASE_DIR%" || goto fail
git clone %REPO_URL% daily_aqua_memo
if errorlevel 1 (
    echo [ERROR] git clone に失敗しました。ネットワークと認証を確認してください。
    goto fail
)
cd /d "%REPO_DIR%" || goto fail
git switch %BRANCH% >nul 2>&1
if errorlevel 1 (
    git switch -c %BRANCH% --track origin/%BRANCH%
    if errorlevel 1 (
        echo [ERROR] ブランチ %BRANCH% へ切り替えられませんでした。
        goto fail
    )
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
echo セットアップ完了。次はこちらを実行してください:
echo   scripts\run_daily_aqua_memo.bat
echo.
pause
exit /b 0

:fail
echo.
echo セットアップを中断しました。上記のエラーメッセージを確認してください。
pause
exit /b 1
