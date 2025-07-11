#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
WMIC出力のデバッグ用スクリプト
実際のWMIC出力を確認し、ファイルに保存する
"""

import subprocess
import sys

def main():
    """デバッグ用のメイン処理"""
    
    # WMIC実行
    print("WMICコマンドを実行中...", file=sys.stderr, flush=True)
    cmd = ["wmic", "process", "get", "Caption,Name,ProcessId,CommandLine", "/FORMAT:LIST"]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding='utf-8',
            shell=False
        )
        
        if result.returncode != 0:
            print(f"エラー: WMICコマンドの実行に失敗しました (戻り値: {result.returncode})", 
                  file=sys.stderr, flush=True)
            if result.stderr:
                print(f"エラー出力: {result.stderr}", file=sys.stderr, flush=True)
            sys.exit(1)
        
        # 生の出力をファイルに保存
        with open('wmic_raw_output.txt', 'w', encoding='utf-8') as f:
            f.write(result.stdout)
        
        print("WMIC出力をwmic_raw_output.txtに保存しました", file=sys.stderr, flush=True)
        
        # 出力の基本情報を表示
        lines = result.stdout.split('\n')
        print(f"総行数: {len(lines)}", file=sys.stderr, flush=True)
        print(f"最初の20行:", file=sys.stderr, flush=True)
        
        for i, line in enumerate(lines[:20], 1):
            print(f"行{i}: {repr(line)}", file=sys.stderr, flush=True)
        
        # 空行の位置を確認
        empty_lines = [i+1 for i, line in enumerate(lines) if not line.strip()]
        print(f"空行の位置: {empty_lines[:10]}...", file=sys.stderr, flush=True)
        
        # キー=値の形式の行を確認
        key_value_lines = [i+1 for i, line in enumerate(lines) if '=' in line]
        print(f"キー=値形式の行数: {len(key_value_lines)}", file=sys.stderr, flush=True)
        
    except FileNotFoundError:
        print("エラー: WMICコマンドが見つかりません。Windows環境で実行してください。", 
              file=sys.stderr, flush=True)
        sys.exit(1)
    except Exception as e:
        print(f"エラー: WMICコマンドの実行中にエラーが発生しました: {repr(e)}", 
              file=sys.stderr, flush=True)
        sys.exit(1)

if __name__ == "__main__":
    main()