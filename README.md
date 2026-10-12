# pandoc-filters

Pandoc 用 Lua フィルタ。

## drawio-filter

`` ```drawio `` のコードブロック（draw.io の XML）を、draw.io CLI で PDF に変換して画像として埋め込む。SVG はラベルが `foreignObject` になり、Typst では文字が欠けるため PDF を使う。

変換には PATH 上の draw.io CLI が必要。Windows では `draw.io.exe` または `drawio`、それ以外では `drawio`。

Markdown では次のように書く。

~~~markdown
```drawio
<mxfile>...</mxfile>
```
~~~

```text
pandoc input.md --lua-filter drawio-filter.lua -o output.pdf
```

## インストール

Pandoc はフィルタ名だけを渡すと `%APPDATA%\pandoc\filters`（通常は `C:\Users\<ユーザー>\AppData\Roaming\pandoc\filters`）を探す。コピーではなくリンクにしておくと、このリポジトリの更新がそのまま使われる。

どちらも、このリポジトリのルートで実行する。

### ファイルのシンボリックリンク

`filters` が既にあり、中の他のフィルタを残す場合。リンクは `drawio-filter.lua` だけ作る。Windows では開発者モード、または管理者として実行した PowerShell が必要。

```powershell
$filters = Join-Path $env:APPDATA "pandoc\filters"
New-Item -ItemType Directory -Force -Path $filters | Out-Null
New-Item -ItemType SymbolicLink `
  -Path (Join-Path $filters "drawio-filter.lua") `
  -Target (Resolve-Path ".\drawio-filter.lua")
```

同名のリンクやファイルが既にあると失敗する。差し替えるときは先にそれを削除する。

### ディレクトリのジャンクション

`filters` がまだない、または空で置き換えてよい場合。リポジトリ自体を `%APPDATA%\pandoc\filters` にする。`Junction` は管理者権限が不要。

`filters` に別のフィルタがあるときは、先にそれらをこのリポジトリへ移してから、既存の `filters` を削除または改名する。ジャンクションは既存のフォルダの上には張れない。

```powershell
$filters = Join-Path $env:APPDATA "pandoc\filters"
New-Item -ItemType Junction -Path $filters -Target (Resolve-Path ".")
```

Pandoc が読むのはこのフォルダ直下の `.lua` だけなので、`.git` などはフィルタとして扱われない。
