#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ファイルからWMIC出力を読み込んでテストするスクリプト
"""

import sys
import json
from wmic_process_parser import parse_wmic_output, generate_json_output, load_settings

def main():
    """メイン処理"""
    
    if len(sys.argv) != 2:
        print("使用方法: python test_with_file.py <wmic_output_file>", file=sys.stderr, flush=True)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    try:
        # ファイルからWMIC出力を読み込み
        with open(input_file, 'r', encoding='utf-8') as f:
            wmic_output = f.read()
        
        print(f"ファイル '{input_file}' を読み込みました", file=sys.stderr, flush=True)
        
        # 設定ファイルを読み込み
        settings = load_settings()
        
        # パース実行
        processes = parse_wmic_output(wmic_output)
        
        # JSON形式で出力
        json_output = generate_json_output(processes, settings)
        
        print(json_output, flush=True)
        
    except FileNotFoundError:
        print(f"エラー: ファイル '{input_file}' が見つかりません", file=sys.stderr, flush=True)
        sys.exit(1)
    except Exception as e:
        print(f"エラー: {repr(e)}", file=sys.stderr, flush=True)
        sys.exit(1)

if __name__ == "__main__":
    main()