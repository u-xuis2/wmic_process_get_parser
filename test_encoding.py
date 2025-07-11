#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
改行コードとエンコーディングのテスト用スクリプト
"""

import sys
from wmic_process_parser import parse_wmic_output

def test_line_endings():
    """改行コードのテスト"""
    
    # テストデータ（LF）
    test_data_lf = """Caption=notepad.exe
CommandLine=C:\\Windows\\System32\\notepad.exe
Name=notepad.exe
ProcessId=1234

Caption=explorer.exe
CommandLine=C:\\Windows\\explorer.exe
Name=explorer.exe
ProcessId=5678"""
    
    # テストデータ（CRLF）
    test_data_crlf = test_data_lf.replace('\n', '\r\n')
    
    # テストデータ（CR）
    test_data_cr = test_data_lf.replace('\n', '\r')
    
    # テストデータ（混合）
    test_data_mixed = test_data_lf.replace('\n', '\r\n', 1).replace('\n', '\r', 1)
    
    print("改行コードテスト開始", file=sys.stderr, flush=True)
    
    test_cases = [
        ("LF (\\n)", test_data_lf),
        ("CRLF (\\r\\n)", test_data_crlf),
        ("CR (\\r)", test_data_cr),
        ("混合", test_data_mixed)
    ]
    
    for name, data in test_cases:
        print(f"\n{name}のテスト:", file=sys.stderr, flush=True)
        print(f"  データ長: {len(data)}", file=sys.stderr, flush=True)
        print(f"  改行文字: {repr(data[:50])}", file=sys.stderr, flush=True)
        
        try:
            processes = parse_wmic_output(data)
            print(f"  結果: {len(processes)} プロセス", file=sys.stderr, flush=True)
            
            for i, proc in enumerate(processes):
                print(f"    プロセス{i+1}: {proc.get('name', 'N/A')} (PID: {proc.get('process_id', 'N/A')})", 
                      file=sys.stderr, flush=True)
                      
        except Exception as e:
            print(f"  エラー: {repr(e)}", file=sys.stderr, flush=True)
    
    print("\n改行コードテスト完了", file=sys.stderr, flush=True)

if __name__ == "__main__":
    test_line_endings()