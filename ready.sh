#!/bin/bash

umask 077

CUR_PATH=`pwd`
BIN_PATH=`dirname "${0}"`
BIN_NAME=`basename "${0}"`

set -uo pipefail

cd "${BIN_PATH}"

echo "WMIC Process Parser 環境セットアップスクリプト"
echo "================================================"

# Python バージョンチェック
echo "Python バージョンチェック..."
python_version=$(python --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+')
if [ -z "$python_version" ]; then
    echo "エラー: Python が見つかりません"
    exit 100
fi

major_version=$(echo "$python_version" | cut -d. -f1)
minor_version=$(echo "$python_version" | cut -d. -f2)

if [ "$major_version" -lt 3 ] || [ "$major_version" -eq 3 -a "$minor_version" -lt 6 ]; then
    echo "エラー: Python 3.6以上が必要です (現在: $python_version)"
    exit 101
fi

echo "Python バージョン: $python_version ✓"

# 設定ファイルの作成
echo ""
echo "設定ファイルの確認..."
if [ ! -f "settings.json" ]; then
    if [ -f "settings.json.template" ]; then
        echo "settings.json.template から settings.json を作成します..."
        cp settings.json.template settings.json
        echo "settings.json を作成しました ✓"
    else
        echo "警告: settings.json.template が見つかりません"
        echo "デフォルト設定で settings.json を作成します..."
        cat > settings.json << 'EOF'
{
  "indent": 2
}
EOF
        echo "settings.json を作成しました ✓"
    fi
else
    echo "settings.json が既に存在します ✓"
fi

# テストディレクトリの作成
echo ""
echo "テストディレクトリの確認..."
if [ ! -d "test" ]; then
    mkdir test
    echo "test ディレクトリを作成しました ✓"
else
    echo "test ディレクトリが既に存在します ✓"
fi

# 基本的な権限チェック
echo ""
echo "スクリプトの権限確認..."
if [ -f "wmic_process_parser.py" ]; then
    chmod +x wmic_process_parser.py
    echo "wmic_process_parser.py の実行権限を設定しました ✓"
else
    echo "警告: wmic_process_parser.py が見つかりません"
fi

# 環境情報の表示
echo ""
echo "環境情報:"
echo "  OS: $(uname -s)"
echo "  Python: $(python --version)"
echo "  作業ディレクトリ: $(pwd)"

echo ""
echo "セットアップ完了 ✓"
echo ""
echo "使用方法:"
echo "  python wmic_process_parser.py --help"
echo "  python wmic_process_parser.py"
echo "  python wmic_process_parser.py output.json"