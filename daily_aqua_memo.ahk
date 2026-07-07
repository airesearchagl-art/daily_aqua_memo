; ============================================================
; Daily Aqua Memo (MVP)
; ------------------------------------------------------------
; Aqua Voice などで通常テキスト入力された短尺メモを、
; 小さな入力フォームから受け取り、Markdown 形式で
; ローカル outbox (outbox\YYYY-MM-DD.md) へ追記保存する。
;
; このスクリプトは:
;   - 録音しない
;   - 音声認識・文字起こしをしない
;   - Aqua Voice API を制御しない
;   - ネットワークアクセスをしない
;   - outbox 配下以外へ書き込まない
; ============================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------- 設定読み込み ----------

CONFIG_PATH := A_ScriptDir "\config.json"

global Cfg := LoadConfigOrDie(CONFIG_PATH)

; ホットキー登録 (既定: ^!m = Ctrl+Alt+M)
try {
    Hotkey(Cfg["hotkey"], (*) => ShowMemoForm())
} catch as e {
    FatalError("ホットキーの登録に失敗しました: " Cfg["hotkey"] "`n" e.Message)
}

TraySetIcon("shell32.dll", 172)  ; メモ風アイコン(ローカルDLLのみ使用)
A_TrayMenu.Add()
A_TrayMenu.Add("メモ入力を開く", (*) => ShowMemoForm())

; ---------- GUI ----------

global MemoGui := 0
global CtxDropDown := 0
global MemoEdit := 0

ShowMemoForm() {
    global MemoGui, CtxDropDown, MemoEdit, Cfg

    ; 既に開いている場合は前面化のみ
    if IsObject(MemoGui) {
        MemoGui.Show()
        MemoEdit.Focus()
        return
    }

    MemoGui := Gui("+AlwaysOnTop", "Daily Aqua Memo")
    MemoGui.SetFont("s10", "Segoe UI")

    MemoGui.AddText(, "context:")
    CtxDropDown := MemoGui.AddDropDownList("w200", Cfg["contexts"])
    defaultIndex := IndexOf(Cfg["contexts"], Cfg["default_context"])
    CtxDropDown.Choose(defaultIndex > 0 ? defaultIndex : 1)

    MemoGui.AddText("xm", "メモ (Ctrl+Enter で保存 / Esc でキャンセル):")
    MemoEdit := MemoGui.AddEdit("xm w420 r8 Multi WantTab")

    saveBtn := MemoGui.AddButton("xm w120 Default", "保存")
    cancelBtn := MemoGui.AddButton("x+10 w120", "キャンセル")

    saveBtn.OnEvent("Click", (*) => SaveMemo())
    cancelBtn.OnEvent("Click", (*) => CloseMemoForm())
    MemoGui.OnEvent("Escape", (*) => CloseMemoForm())
    MemoGui.OnEvent("Close", (*) => CloseMemoForm())

    ; Ctrl+Enter 保存 (このフォームがアクティブな間だけ有効)
    HotIfWinActive("ahk_id " MemoGui.Hwnd)
    Hotkey("^Enter", (*) => SaveMemo(), "On")
    HotIf()

    MemoGui.Show()
    MemoEdit.Focus()
}

CloseMemoForm() {
    global MemoGui
    if IsObject(MemoGui) {
        HotIfWinActive("ahk_id " MemoGui.Hwnd)
        try Hotkey("^Enter", "Off")
        HotIf()
        MemoGui.Destroy()
        MemoGui := 0
    }
}

; ---------- 保存処理 ----------

SaveMemo() {
    global MemoGui, CtxDropDown, MemoEdit, Cfg

    if !IsObject(MemoGui)
        return

    body := Trim(MemoEdit.Value, " `t`r`n")
    if (body = "") {
        MsgBox("空のメモは保存しません。", "Daily Aqua Memo", "Iconi")
        return
    }

    context := CtxDropDown.Text
    if (context = "")
        context := Cfg["default_context"]

    outboxDir := Cfg["outbox_dir"]

    ; --- 保存先を outbox 配下に限定する安全チェック ---
    if !IsSafeOutboxDir(outboxDir) {
        FatalError("outbox_dir が 'outbox' フォルダを指していません。`n"
            . "安全のため保存を中止します: " outboxDir)
    }
    if !DirExist(outboxDir) {
        FatalError("outbox フォルダが存在しません: " outboxDir "`n"
            . "安全のため自動作成はせず、保存を中止します。")
    }

    dateStr := FormatTime(, "yyyy-MM-dd")
    filePath := outboxDir "\" dateStr ".md"

    eol := "`r`n"
    entry := ""
    if !FileExist(filePath)
        entry .= "# " dateStr " Daily Raw Outbox" eol . eol

    timeHm := FormatTime(, "HH:mm")
    createdAt := FormatTime(, "yyyy-MM-dd HH:mm:ss")

    entry .= "## " timeHm " voice / windows / " context . eol
    entry .= eol
    entry .= "- source: " Cfg["source"] . eol
    entry .= "- device: " Cfg["device"] . eol
    entry .= "- context: " context . eol
    entry .= "- status: unprocessed" eol
    entry .= "- created: " createdAt . eol
    entry .= eol
    entry .= "### raw" eol
    entry .= eol
    entry .= "``````text" eol
    entry .= NormalizeEol(body, eol) . eol
    entry .= "``````" eol
    entry .= eol

    ; UTF-8 (BOMなし) で追記のみ。既存内容は上書きしない。
    try {
        f := FileOpen(filePath, "a", "UTF-8-RAW")
        f.Write(entry)
        f.Close()
    } catch as e {
        MsgBox("保存に失敗しました: " e.Message, "Daily Aqua Memo", "Iconx")
        return
    }

    CloseMemoForm()
    TrayTip("メモを保存しました", filePath, "Iconi")
}

; ---------- ユーティリティ ----------

NormalizeEol(text, eol) {
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    return StrReplace(text, "`n", eol)
}

IndexOf(arr, value) {
    for i, v in arr
        if (v = value)
            return i
    return 0
}

; outbox_dir の末尾フォルダ名が "outbox" であることを要求する。
; これにより設定ミスで Obsidian Vault などへ書き込む事故を防ぐ。
IsSafeOutboxDir(dir) {
    dir := RTrim(dir, "\/")
    SplitPath(dir, &leaf)
    return (leaf = "outbox")
}

FatalError(msg) {
    MsgBox(msg, "Daily Aqua Memo - エラー", "Iconx")
    ExitApp(1)
}

; ---------- 簡易JSON読み込み ----------
; config.json のうち、このMVPが必要とするキーだけを
; 正規表現ベースで安全に読み取る最小実装。
; 読み込みに失敗した場合は別パスへフォールバックせず、
; エラーを表示して停止する。

LoadConfigOrDie(path) {
    if !FileExist(path)
        FatalError("config.json が見つかりません: " path)

    try {
        raw := FileRead(path, "UTF-8")
    } catch as e {
        FatalError("config.json を読み込めません: " e.Message)
    }

    cfg := Map()
    for key in ["hotkey", "outbox_dir", "default_context", "source", "device"] {
        val := JsonGetString(raw, key)
        if (val = "")
            FatalError("config.json に必須キーがありません、または値が不正です: " key)
        cfg[key] := val
    }

    contexts := JsonGetStringArray(raw, "contexts")
    if (contexts.Length = 0)
        FatalError("config.json の contexts が読み取れません。")
    cfg["contexts"] := contexts

    return cfg
}

JsonGetString(json, key) {
    pattern := '"' key '"\s*:\s*"((?:[^"\\]|\\.)*)"'
    if !RegExMatch(json, pattern, &m)
        return ""
    return JsonUnescape(m[1])
}

JsonGetStringArray(json, key) {
    result := []
    pattern := '"' key '"\s*:\s*\[([^\]]*)\]'
    if !RegExMatch(json, pattern, &m)
        return result
    inner := m[1]
    pos := 1
    while (pos := RegExMatch(inner, '"((?:[^"\\]|\\.)*)"', &mi, pos)) {
        result.Push(JsonUnescape(mi[1]))
        pos += mi.Len[0]
    }
    return result
}

JsonUnescape(s) {
    out := ""
    i := 1
    len := StrLen(s)
    while (i <= len) {
        c := SubStr(s, i, 1)
        if (c = "\" && i < len) {
            n := SubStr(s, i + 1, 1)
            switch n {
                case "\": out .= "\"
                case '"': out .= '"'
                case "/": out .= "/"
                case "n": out .= "`n"
                case "r": out .= "`r"
                case "t": out .= "`t"
                case "b": out .= "`b"
                case "f": out .= "`f"
                default:  out .= n
            }
            i += 2
        } else {
            out .= c
            i += 1
        }
    }
    return out
}
