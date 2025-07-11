# WMIC Process Parser

WindowsのWMIC PROCESS GETコマンドの出力をパースしてJSON形式で出力するツール

## 概要

このツールは、Windowsのwmicコマンドを使用してプロセス情報を取得し、構造化されたJSON形式で出力します。

## 必要環境

- Python 3.6以上
- Windows環境
- WMIC利用可能な環境

## セットアップ

1. リポジトリをクローン
2. 設定ファイルを作成（オプション）

```bash
# 設定ファイルの作成（オプション）
cp settings.json.template settings.json
```

## 使用方法

### 基本的な使用方法

```bash
# 標準出力に出力
python wmic_process_parser.py

# ファイルに出力
python wmic_process_parser.py output.json
```

### ヘルプ表示

```bash
python wmic_process_parser.py --help
```

## 設定ファイル

`settings.json`ファイルで出力設定をカスタマイズできます。

```json
{
  "indent": 2
}
```

### 設定項目

- `indent`: JSON出力のインデント（デフォルト: 2）

## 出力形式

```json
{
  "execution_time": "2024-01-01T12:00:00Z",
  "processes": [
    {
      "caption": "notepad.exe",
      "name": "notepad.exe",
      "process_id": 1234,
      "command_line": "C:\\Windows\\System32\\notepad.exe document.txt",
      "executable_path": "C:\\Windows\\System32\\notepad.exe",
      "executable_name": "notepad.exe"
    }
  ]
}
```

### 出力フィールド

- `execution_time`: 実行時刻（ISO 8601形式）
- `processes`: プロセス情報の配列
  - `caption`: プロセスキャプション
  - `name`: プロセス名
  - `process_id`: プロセスID
  - `command_line`: コマンドライン
  - `executable_path`: 実行ファイルパス
  - `executable_name`: 実行ファイル名

## エラーハンドリング

- WMICコマンドの実行エラー
- JSON生成エラー
- ファイル入出力エラー

エラーメッセージは標準エラー出力に表示されます。

## セキュリティ

- subprocessモジュールを使用（shell=False）
- 基本的なエラーハンドリング

## ライセンス

MIT License
