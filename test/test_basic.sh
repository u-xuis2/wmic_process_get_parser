#!/bin/bash

umask 077

CUR_PATH=`pwd`
BIN_PATH=`dirname "${0}"`
BIN_NAME=`basename "${0}"`

set -uo pipefail

cd "${BIN_PATH}"
cd ..

echo "基本機能テスト"
echo "============="

# テスト結果カウンタ
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# テスト結果を記録する関数
test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo "[PASS] $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "[FAIL] $test_name"
        if [ -n "$details" ]; then
            echo "       詳細: $details"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# テスト1: ヘルプオプション
echo ""
echo "テスト1: ヘルプオプション"
echo "------------------------"
if python wmic_process_parser.py --help > /dev/null 2>&1; then
    test_result "ヘルプオプション" "PASS" ""
else
    test_result "ヘルプオプション" "FAIL" "ヘルプオプションの実行に失敗"
fi

# テスト2: 設定ファイルテンプレートの存在確認
echo ""
echo "テスト2: 設定ファイルテンプレートの存在確認"
echo "----------------------------------------"
if [ -f "settings.json.template" ]; then
    test_result "設定ファイルテンプレート" "PASS" ""
else
    test_result "設定ファイルテンプレート" "FAIL" "settings.json.templateが見つかりません"
fi

# テスト3: JSON出力の基本構造確認（モックデータ使用）
echo ""
echo "テスト3: JSON出力の基本構造確認"
echo "-----------------------------"

# モックのWMIC出力を作成
MOCK_WMIC_OUTPUT="Caption=notepad.exe
CommandLine=C:\\Windows\\System32\\notepad.exe
Name=notepad.exe
ProcessId=1234

Caption=explorer.exe
CommandLine=C:\\Windows\\explorer.exe
Name=explorer.exe
ProcessId=5678"

# 一時的なPythonスクリプトでパース機能をテスト
cat > test_parser.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_wmic_output

mock_output = """Caption=notepad.exe
CommandLine=C:\\Windows\\System32\\notepad.exe
Name=notepad.exe
ProcessId=1234

Caption=explorer.exe
CommandLine=C:\\Windows\\explorer.exe
Name=explorer.exe
ProcessId=5678"""

processes = parse_wmic_output(mock_output)
print(f"プロセス数: {len(processes)}")
for i, proc in enumerate(processes):
    print(f"プロセス{i+1}: {proc.get('name', 'N/A')} (PID: {proc.get('process_id', 'N/A')})")
EOF

if python test_parser.py > test_parser_output.txt 2>&1; then
    if grep -q "プロセス数: 2" test_parser_output.txt; then
        test_result "JSON出力の基本構造" "PASS" ""
    else
        test_result "JSON出力の基本構造" "FAIL" "期待されるプロセス数が見つかりません"
    fi
else
    test_result "JSON出力の基本構造" "FAIL" "パーサーテストの実行に失敗"
fi

# テスト4: 設定ファイルからのコピー
echo ""
echo "テスト4: 設定ファイルの作成"
echo "------------------------"
if [ -f "settings.json.template" ]; then
    cp settings.json.template settings.json
    if [ -f "settings.json" ]; then
        test_result "設定ファイルの作成" "PASS" ""
    else
        test_result "設定ファイルの作成" "FAIL" "設定ファイルのコピーに失敗"
    fi
else
    test_result "設定ファイルの作成" "FAIL" "テンプレートファイルが見つかりません"
fi

# テスト5: ファイル出力テスト（モックデータ使用）
echo ""
echo "テスト5: ファイル出力テスト"
echo "------------------------"

# モックのWMIC出力を含むテストスクリプトを作成
cat > test_file_output.py << 'EOF'
import sys
import os
import json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_wmic_output, generate_json_output, load_settings

mock_output = """Caption=notepad.exe
CommandLine=C:\\Windows\\System32\\notepad.exe
Name=notepad.exe
ProcessId=1234"""

try:
    settings = load_settings()
    processes = parse_wmic_output(mock_output)
    json_output = generate_json_output(processes, settings)
    
    with open('test_output.json', 'w', encoding='utf-8') as f:
        f.write(json_output)
    
    # 出力ファイルの検証
    with open('test_output.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'processes' in data and len(data['processes']) == 1:
        print("SUCCESS: JSON出力ファイルが正しく作成されました")
    else:
        print("ERROR: JSON出力ファイルの構造が正しくありません")
        
except Exception as e:
    print(f"ERROR: {e}")
EOF

if python test_file_output.py > test_file_output.txt 2>&1; then
    if grep -q "SUCCESS" test_file_output.txt; then
        test_result "ファイル出力テスト" "PASS" ""
    else
        test_result "ファイル出力テスト" "FAIL" "JSON出力ファイルの検証に失敗"
    fi
else
    test_result "ファイル出力テスト" "FAIL" "ファイル出力テストの実行に失敗"
fi

# 一時ファイルの削除
rm -f test_parser.py test_parser_output.txt test_file_output.py test_file_output.txt test_output.json

echo ""
echo "テスト結果サマリー"
echo "================="
echo "総テスト数: $TOTAL_TESTS"
echo "成功: $PASSED_TESTS"
echo "失敗: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "🎉 すべてのテストが成功しました！"
    exit 0
else
    echo ""
    echo "❌ $FAILED_TESTS 個のテストが失敗しました"
    exit 1
fi