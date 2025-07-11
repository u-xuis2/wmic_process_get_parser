#!/bin/bash

umask 077

CUR_PATH=`pwd`
BIN_PATH=`dirname "${0}"`
BIN_NAME=`basename "${0}"`

set -uo pipefail

cd "${BIN_PATH}"
cd ..

echo "エラーケーステスト"
echo "================"

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

# テスト1: 不正なJSONファイルでのエラーハンドリング
echo ""
echo "テスト1: 不正なJSONファイルでのエラーハンドリング"
echo "--------------------------------------------"

# 不正なJSONファイルを作成
cat > invalid_settings.json << 'EOF'
{
  "indent": 2,
  "invalid_json": 
}
EOF

# 不正な設定ファイルを読み込むテスト
cat > test_invalid_json.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# 設定ファイルを一時的に置き換える
os.rename('settings.json', 'settings.json.backup') if os.path.exists('settings.json') else None
os.rename('invalid_settings.json', 'settings.json')

try:
    from wmic_process_parser import load_settings
    settings = load_settings()
    print("SUCCESS: 不正なJSONファイルでもデフォルト設定が使用されました")
except Exception as e:
    print(f"ERROR: 予期しないエラーが発生しました: {e}")

# 設定ファイルを元に戻す
os.rename('settings.json', 'invalid_settings.json')
os.rename('settings.json.backup', 'settings.json') if os.path.exists('settings.json.backup') else None
EOF

if python test_invalid_json.py > test_invalid_json_output.txt 2>&1; then
    if grep -q "SUCCESS" test_invalid_json_output.txt; then
        test_result "不正なJSONファイルの処理" "PASS" ""
    else
        test_result "不正なJSONファイルの処理" "FAIL" "不正なJSONファイルの処理に失敗"
    fi
else
    test_result "不正なJSONファイルの処理" "FAIL" "テストスクリプトの実行に失敗"
fi

# テスト2: 空のWMIC出力の処理
echo ""
echo "テスト2: 空のWMIC出力の処理"
echo "------------------------"

cat > test_empty_output.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_wmic_output

try:
    # 空の出力をテスト
    processes = parse_wmic_output("")
    if len(processes) == 0:
        print("SUCCESS: 空の出力が正しく処理されました")
    else:
        print("ERROR: 空の出力で予期しないプロセスが検出されました")
        
    # 空白のみの出力をテスト
    processes = parse_wmic_output("   \n\n   ")
    if len(processes) == 0:
        print("SUCCESS: 空白のみの出力が正しく処理されました")
    else:
        print("ERROR: 空白のみの出力で予期しないプロセスが検出されました")
        
except Exception as e:
    print(f"ERROR: 予期しないエラーが発生しました: {e}")
EOF

if python test_empty_output.py > test_empty_output_result.txt 2>&1; then
    success_count=$(grep -c "SUCCESS" test_empty_output_result.txt)
    if [ "$success_count" -eq 2 ]; then
        test_result "空のWMIC出力の処理" "PASS" ""
    else
        test_result "空のWMIC出力の処理" "FAIL" "空の出力処理に失敗"
    fi
else
    test_result "空のWMIC出力の処理" "FAIL" "テストスクリプトの実行に失敗"
fi

# テスト3: 不正なプロセスIDの処理
echo ""
echo "テスト3: 不正なプロセスIDの処理"
echo "----------------------------"

cat > test_invalid_pid.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_wmic_output

try:
    # 不正なプロセスIDを含むデータ
    invalid_pid_output = """Caption=notepad.exe
CommandLine=C:\\Windows\\System32\\notepad.exe
Name=notepad.exe
ProcessId=invalid_pid

Caption=explorer.exe
CommandLine=C:\\Windows\\explorer.exe
Name=explorer.exe
ProcessId=5678"""
    
    processes = parse_wmic_output(invalid_pid_output)
    
    # 2つのプロセスが検出されることを確認
    if len(processes) == 2:
        # 最初のプロセスのPIDがNoneであることを確認
        if processes[0].get('process_id') is None:
            print("SUCCESS: 不正なプロセスIDが正しく処理されました")
        else:
            print("ERROR: 不正なプロセスIDが適切に処理されませんでした")
        
        # 2番目のプロセスのPIDが正しいことを確認
        if processes[1].get('process_id') == 5678:
            print("SUCCESS: 正常なプロセスIDが正しく処理されました")
        else:
            print("ERROR: 正常なプロセスIDが適切に処理されませんでした")
    else:
        print("ERROR: 期待されるプロセス数が検出されませんでした")
        
except Exception as e:
    print(f"ERROR: 予期しないエラーが発生しました: {e}")
EOF

if python test_invalid_pid.py > test_invalid_pid_result.txt 2>&1; then
    success_count=$(grep -c "SUCCESS" test_invalid_pid_result.txt)
    if [ "$success_count" -eq 2 ]; then
        test_result "不正なプロセスIDの処理" "PASS" ""
    else
        test_result "不正なプロセスIDの処理" "FAIL" "不正なプロセスIDの処理に失敗"
    fi
else
    test_result "不正なプロセスIDの処理" "FAIL" "テストスクリプトの実行に失敗"
fi

# テスト4: コマンドライン解析のエラーケース
echo ""
echo "テスト4: コマンドライン解析のエラーケース"
echo "-----------------------------------"

cat > test_command_line_parsing.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_command_line

try:
    # 空のコマンドライン
    path, name = parse_command_line("")
    if path is None and name is None:
        print("SUCCESS: 空のコマンドラインが正しく処理されました")
    else:
        print("ERROR: 空のコマンドラインで予期しない結果が返されました")
    
    # Noneのコマンドライン
    path, name = parse_command_line(None)
    if path is None and name is None:
        print("SUCCESS: Noneのコマンドラインが正しく処理されました")
    else:
        print("ERROR: Noneのコマンドラインで予期しない結果が返されました")
    
    # 引用符で囲まれたパス
    path, name = parse_command_line('"C:\\Program Files\\Test\\app.exe" -arg1 -arg2')
    if path == "C:\\Program Files\\Test\\app.exe" and name == "app.exe":
        print("SUCCESS: 引用符で囲まれたパスが正しく処理されました")
    else:
        print(f"ERROR: 引用符で囲まれたパスの処理に失敗 (path: {path}, name: {name})")
        
except Exception as e:
    print(f"ERROR: 予期しないエラーが発生しました: {e}")
EOF

if python test_command_line_parsing.py > test_command_line_result.txt 2>&1; then
    success_count=$(grep -c "SUCCESS" test_command_line_result.txt)
    if [ "$success_count" -eq 3 ]; then
        test_result "コマンドライン解析のエラーケース" "PASS" ""
    else
        test_result "コマンドライン解析のエラーケース" "FAIL" "コマンドライン解析のエラーケース処理に失敗"
    fi
else
    test_result "コマンドライン解析のエラーケース" "FAIL" "テストスクリプトの実行に失敗"
fi

# テスト5: 不正な出力パスでのエラーハンドリング
echo ""
echo "テスト5: 不正な出力パスでのエラーハンドリング"
echo "---------------------------------------"

# 存在しないディレクトリへのファイル出力を試すテスト
cat > test_invalid_output_path.py << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from wmic_process_parser import parse_wmic_output, generate_json_output, load_settings

try:
    settings = load_settings()
    processes = parse_wmic_output("Caption=test.exe\nProcessId=1234")
    json_output = generate_json_output(processes, settings)
    
    # 存在しないディレクトリへの出力を試す
    try:
        with open('/nonexistent/directory/output.json', 'w', encoding='utf-8') as f:
            f.write(json_output)
        print("ERROR: 存在しないディレクトリへの出力が成功してしまいました")
    except (OSError, IOError) as e:
        print("SUCCESS: 存在しないディレクトリへの出力で適切にエラーが発生しました")
    except Exception as e:
        print(f"ERROR: 予期しないエラーが発生しました: {e}")
        
except Exception as e:
    print(f"ERROR: テストの実行でエラーが発生しました: {e}")
EOF

if python test_invalid_output_path.py > test_invalid_output_result.txt 2>&1; then
    if grep -q "SUCCESS" test_invalid_output_result.txt; then
        test_result "不正な出力パスでのエラーハンドリング" "PASS" ""
    else
        test_result "不正な出力パスでのエラーハンドリング" "FAIL" "不正な出力パスの処理に失敗"
    fi
else
    test_result "不正な出力パスでのエラーハンドリング" "FAIL" "テストスクリプトの実行に失敗"
fi

# 一時ファイルの削除
rm -f invalid_settings.json test_invalid_json.py test_invalid_json_output.txt
rm -f test_empty_output.py test_empty_output_result.txt
rm -f test_invalid_pid.py test_invalid_pid_result.txt
rm -f test_command_line_parsing.py test_command_line_result.txt
rm -f test_invalid_output_path.py test_invalid_output_result.txt

echo ""
echo "エラーケーステスト結果サマリー"
echo "============================"
echo "総テスト数: $TOTAL_TESTS"
echo "成功: $PASSED_TESTS"
echo "失敗: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "🎉 すべてのエラーケーステストが成功しました！"
    exit 0
else
    echo ""
    echo "❌ $FAILED_TESTS 個のエラーケーステストが失敗しました"
    exit 1
fi