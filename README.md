# Daily Aqua Memo

Aqua Voice などで通常テキスト入力された短尺メモを、Windows 上の小さな入力フォームから受け取り、Markdown 形式でローカル outbox へ追記保存する MVP ツールです。

## 目的

- 思いついた短いメモを、最小の操作でその日の Markdown ファイルに貯める
- 貯めた生ログ (raw outbox) は後工程で整理する前提とし、このツールは「受け取って追記する」ことだけに集中する

## 対象環境

- Windows
- AutoHotkey v2

## このツールがやらないこと(重要)

- **録音しません**
- **音声認識・文字起こし(Whisper 等)をしません**
- **Aqua Voice API を制御しません**(Aqua Voice は通常のテキスト入力エンジンとして使うだけです)
- ネットワークアクセスをしません
- GitHub / Obsidian Vault への自動反映をしません

## 前提: AutoHotkey v2 が必要です

- Daily Aqua Memo は **AutoHotkey v2 スクリプト**です。実行には AutoHotkey v2 のインストールが必要です
- `.ahk` ファイルを開いたときに Windows の **「アプリを選択して .ahk ファイルを開く」** 画面が表示される場合、AutoHotkey v2 が未インストール、または `.ahk` の関連付けが未設定である可能性が高いです
- その場合は [AutoHotkey 公式サイト](https://www.autohotkey.com/) から AutoHotkey v2 をインストールしてください(インストールすると関連付けが設定され、ダブルクリックで起動できるようになります)
- インストール後に `daily_aqua_memo.ahk` をダブルクリックするか、`scripts\run_daily_aqua_memo.bat` を実行してください

## 起動方法

1. [AutoHotkey v2](https://www.autohotkey.com/) をインストールする
2. `daily_aqua_memo.ahk` をダブルクリック、または `scripts\run_daily_aqua_memo.bat` を実行する
3. タスクトレイに常駐します

## Windows セットアップ用 bat

clone やブランチ切り替えを毎回手入力しなくて済むよう、以下の bat を用意しています。

> **注**: bat 内のメッセージ・コメントは、cmd.exe のコードページ差異による文字化け(UTF-8 日本語の誤解釈)を防ぐため、すべて ASCII 英語表記にしています。日本語の説明はこの README に集約しています。

| スクリプト | 役割 |
| --- | --- |
| `scripts\setup_daily_aqua_memo.bat` | **clone済みリポジトリ内で使う**状態確認・更新補助。現在ブランチの表示、`git fetch`、upstreamがある場合のみ現在ブランチへの `git pull --ff-only` を行う。**ブランチ切替は行わない** |
| `scripts\run_daily_aqua_memo.bat` | AutoHotkey v2 の実行ファイルを探して `daily_aqua_memo.ahk` を起動する。見つからない場合はインストール案内を表示して終了する |

`setup_daily_aqua_memo.bat` の動作(clone済みリポジトリ内で実行):

- `git --version` で Git の存在を確認(なければエラー停止)
- スクリプト位置からリポジトリルートへ移動し、`.git` の存在を確認(なければエラー停止し、READMEの初回clone手順を案内)
- repo URL / repo path / 現在ブランチを表示
- `git fetch origin` を実行
- 現在ブランチに upstream が設定されている場合のみ、現在ブランチに対して `git pull --ff-only` を実行(upstreamがない場合はWARNを表示してpullをスキップ)
- 最後に現在ブランチ・upstream・`git status --short`・`git log --oneline -5`・次に実行するコマンドを表示

### 初回cloneの手順(手動)

初回のcloneはbatではなく、PowerShellで以下を実行してください。

```powershell
mkdir C:\Users\shuns\.claude\projects -Force
cd C:\Users\shuns\.claude\projects
git clone https://github.com/airesearchagl-art/daily_aqua_memo.git daily_aqua_memo
cd .\daily_aqua_memo
git switch main
.\scripts\run_daily_aqua_memo.bat
```

### 利用ブランチについて

- `scripts\setup_daily_aqua_memo.bat` は **clone済みリポジトリ内で使う補助スクリプト**です(初回cloneは上記の手動コマンドで行います)
- setup bat は **現在のブランチを勝手に `main` へ切り替えません**(`git switch` / `git checkout` / ブランチ作成は一切行いません)
- そのため、**PRブランチの検証中はPRブランチのまま**状態確認・更新ができます
- 通常利用時は `main` を使いますが、**ブランチ切替はユーザーが明示的に** `git switch main` などで行ってください

### bat のセキュリティ方針

- setup bat が行う git 操作は `fetch` と現在ブランチへの `pull --ff-only` **のみ**です(clone / switch / checkout / ブランチ作成はしません)
- commit / push / PR 作成はしません(`git reset --hard` / `git clean` / force push もしません)
- obsidian-vault には触りません
- AutoHotkey を自動ダウンロードしません(公式サイトの URL を表示するだけです)
- レジストリ変更・`.ahk` 関連付けの変更・管理者権限の要求はしません

## 使い方

| 操作 | キー |
| --- | --- |
| 入力フォームを開く | `Ctrl + Alt + M` |
| 保存 | `Ctrl + Enter`(または「保存」ボタン) |
| キャンセル | `Esc`(または「キャンセル」ボタン) |

- フォームには context 選択欄(`quick` / `work` / `design` / `dev` / `personal` / `reflection`、初期値 `quick`)と複数行テキスト入力欄があります
- フォーム表示時はテキスト入力欄にフォーカスされるので、Aqua Voice でそのまま入力できます
- 空入力は保存されません(本文は前後の空白・空行を trim してから判定・保存されます)

## 保存先

```text
C:\Users\shuns\.claude\projects\daily_aqua_memo\outbox\YYYY-MM-DD.md
```

- 当日ファイルへ **追記のみ** 行います(既存内容の上書きはしません)
- ファイルが存在しない場合のみ、冒頭に `# YYYY-MM-DD Daily Raw Outbox` 見出しを作成します
- UTF-8 で保存します
- 保存後はフォームが閉じ、トレイ通知が表示されます

### 保存先の安全チェック

保存先は **スクリプトと同じフォルダ配下の `outbox`** のみに限定されます。起動時に `config.json` の `outbox_dir` を検証し、以下をすべて満たさない場合はエラーメッセージを表示して停止します(別パスへのフォールバックはしません)。

- `outbox_dir` を Win32 `GetFullPathNameW` で正規化し、`..` や `/` 混在によるスクリプトフォルダ外への脱出パスを解決したうえで判定する
- 正規化後のパスが「スクリプトフォルダの `outbox`」と同一、またはスクリプトフォルダ配下で末尾フォルダ名が `outbox` であること
- 末尾フォルダ名が `outbox` でも、スクリプトフォルダの外を指す場合は拒否する
- パスに `obsidian-vault` を含む場合は無条件で拒否する(`C:\Users\shuns\obsidian-vault` 配下への書き込み防止)

## Markdown 出力形式

````markdown
## HH:mm voice / windows / <context>

- source: Aqua Voice
- device: Windows PC
- context: <context>
- status: unprocessed
- created: YYYY-MM-DD HH:mm:ss

### raw

```text
<trim済み本文>
```
````

実際の例は [`examples/sample-output.md`](examples/sample-output.md) を参照してください。

## 設定 (config.json)

```json
{
  "hotkey": "^!m",
  "outbox_dir": "C:\\Users\\shuns\\.claude\\projects\\daily_aqua_memo\\outbox",
  "default_context": "quick",
  "contexts": ["quick", "work", "design", "dev", "personal", "reflection"],
  "source": "Aqua Voice",
  "device": "Windows PC"
}
```

### 設定読み込み失敗時の安全方針

`config.json` が存在しない・読み取れない・必須キーが欠けている場合、このツールは:

- 勝手に Obsidian Vault へ保存 **しません**
- 勝手に別パスへ保存 **しません**
- エラーメッセージを表示して **停止します**

## Git 管理について

- `outbox/*.md`(日々の生ログ)は `.gitignore` により **Git 管理対象外** です
- `outbox/` フォルダ自体は `outbox/.gitkeep` により維持されます
- 間違って保存した場合は、`outbox` 内の当日ファイルを手動で編集・削除してください

## MVP の範囲

- MVP では GitHub / Obsidian Vault への自動反映は行いません
- outbox から processed Markdown を作成して Obsidian Vault へ PR 反映する工程は、次フェーズの別タスクとして扱います

## 禁止事項

このリポジトリ・ツールでは以下を行いません。

- `main` への直接 commit / force push / `git reset --hard` / `git clean`
- outbox 内の実メモ Markdown の commit
- secrets / token / API キーの参照
- クラウド送信処理の追加
- 録音機能・Whisper 文字起こし機能の追加
- Aqua Voice API 制御、Aqua Voice の認証情報や設定ファイルの探索
- `obsidian-vault` リポジトリの clone / 編集 / commit / push / PR 作成
- ローカル Obsidian ノートへの無条件直接追記
