@echo off
chcp 65001 >nul
setlocal

rem ============================================================
rem Daily Aqua Memo run script
rem   - AutoHotkey v2 を探して daily_aqua_memo.ahk を起動する
rem   - AutoHotkey の自動ダウンロードはしない
rem   - レジストリ変更・.ahk 関連付け変更はしない
rem   - 管理者権限は要求しない
rem ============================================================

rem スクリプト自身の場所からリポジトリルートへ移動
cd /d "%~dp0.." || goto fail
set "REPO_DIR=%CD%"

if not exist "%REPO_DIR%\daily_aqua_memo.ahk" (
    echo [ERROR] daily_aqua_memo.ahk が見つかりません: %REPO_DIR%
    echo 先に scripts\setup_daily_aqua_memo.bat を実行してください。
    goto fail
)

rem --- AutoHotkey v2 候補を探す ---
set "AHK_EXE="
if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\AutoHotkey64.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\AutoHotkey64.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe"
if not defined AHK_EXE for /f "delims=" %%i in ('where AutoHotkey64.exe 2^>nul') do if not defined AHK_EXE set "AHK_EXE=%%i"
if not defined AHK_EXE for /f "delims=" %%i in ('where AutoHotkey.exe 2^>nul') do if not defined AHK_EXE set "AHK_EXE=%%i"

if not defined AHK_EXE goto ahk_not_found

echo AutoHotkey : %AHK_EXE%
echo Daily Aqua Memo を起動します...
start "" "%AHK_EXE%" "%REPO_DIR%\daily_aqua_memo.ahk"
echo 起動しました。タスクトレイに常駐します。Ctrl+Alt+M で入力フォームが開きます。
exit /b 0

:ahk_not_found
echo [ERROR] AutoHotkey v2 が見つかりませんでした。
echo.
echo AutoHotkey v2 をインストールしてください。
echo 公式サイト: https://www.autohotkey.com/
echo.
echo 補足: .ahk ファイルを開いたときに「アプリを選択して .ahk ファイルを開く」
echo という画面が表示されるのは、AutoHotkey が未インストール、または .ahk の
echo 関連付けが未設定のためです。AutoHotkey v2 をインストールすると関連付けが
echo 設定され、ダブルクリックでスクリプトを起動できるようになります。
echo.
echo このスクリプトは AutoHotkey の自動ダウンロード・レジストリ変更・
echo 関連付けの変更は行いません。インストール後にもう一度実行してください。
pause
exit /b 1

:fail
echo.
echo 起動を中断しました。上記のエラーメッセージを確認してください。
pause
exit /b 1
