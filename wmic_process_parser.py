#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
WMIC PROCESS GET情報をパースしてJSON形式で出力するツール
"""

import argparse
import json
import os
import re
import subprocess
import sys
import traceback
from datetime import datetime
from pathlib import Path


def load_settings():
    """設定ファイルを読み込む"""
    settings_path = Path("settings.json")
    default_settings = {"indent": 2}
    
    if not settings_path.exists():
        # テンプレートファイルが存在する場合は警告
        template_path = Path("settings.json.template")
        if template_path.exists():
            print("警告: settings.jsonが見つかりません。settings.json.templateを参考に作成してください。", 
                  file=sys.stderr, flush=True)
        return default_settings
    
    try:
        with open(settings_path, 'r', encoding='utf-8') as f:
            settings = json.load(f)
        return {**default_settings, **settings}
    except Exception as e:
        print(f"エラー: settings.jsonの読み込みに失敗しました: {repr(e)}", 
              file=sys.stderr, flush=True)
        return default_settings


def execute_wmic():
    """WMIC PROCESS GETコマンドを実行する"""
    cmd = ["wmic", "process", "get", "Caption,Name,ProcessId,CommandLine", "/FORMAT:LIST"]
    
    try:
        # Windowsの場合、複数のエンコーディングを試す
        encodings = ['utf-8', 'cp932', 'shift_jis', 'utf-16']
        result = None
        
        for encoding in encodings:
            try:
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    encoding=encoding,
                    shell=False
                )
                
                if result.returncode == 0:
                    # 成功した場合、出力をチェック
                    if result.stdout and 'ProcessId=' in result.stdout:
                        print(f"デバッグ: エンコーディング '{encoding}' で成功", file=sys.stderr, flush=True)
                        break
                    else:
                        print(f"デバッグ: エンコーディング '{encoding}' で実行成功したが出力が不正", file=sys.stderr, flush=True)
                        continue
                else:
                    print(f"デバッグ: エンコーディング '{encoding}' で失敗 (戻り値: {result.returncode})", file=sys.stderr, flush=True)
                    continue
                    
            except UnicodeDecodeError:
                print(f"デバッグ: エンコーディング '{encoding}' でデコードエラー", file=sys.stderr, flush=True)
                continue
            except Exception as e:
                print(f"デバッグ: エンコーディング '{encoding}' で例外: {repr(e)}", file=sys.stderr, flush=True)
                continue
        
        if not result or result.returncode != 0:
            print(f"エラー: WMICコマンドの実行に失敗しました (戻り値: {result.returncode if result else 'N/A'})", 
                  file=sys.stderr, flush=True)
            if result and result.stderr:
                print(f"エラー出力: {result.stderr}", file=sys.stderr, flush=True)
            sys.exit(101)
        
        return result.stdout
    
    except FileNotFoundError:
        print("エラー: WMICコマンドが見つかりません。Windows環境で実行してください。", 
              file=sys.stderr, flush=True)
        sys.exit(102)
    except Exception as e:
        print(f"エラー: WMICコマンドの実行中にエラーが発生しました: {repr(e)}", 
              file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        sys.exit(103)


def parse_command_line(command_line):
    """コマンドラインから実行ファイルパスと名前を抽出する"""
    if not command_line:
        return None, None
    
    # 引用符で囲まれた実行ファイルパスを抽出
    quoted_match = re.match(r'^"([^"]+)"', command_line)
    if quoted_match:
        executable_path = quoted_match.group(1)
        # Windowsパスからファイル名を抽出
        executable_name = executable_path.split('\\')[-1] if '\\' in executable_path else executable_path
        return executable_path, executable_name
    
    # 空白で区切られた最初の部分を実行ファイルパスとして抽出
    parts = command_line.split()
    if parts:
        executable_path = parts[0]
        # Windowsパスからファイル名を抽出
        executable_name = executable_path.split('\\')[-1] if '\\' in executable_path else executable_path
        return executable_path, executable_name
    
    return None, None


def parse_wmic_output(output):
    """WMIC出力をパースしてプロセス情報リストを返す"""
    processes = []
    current_process = {}
    
    # 改行コードを正規化（Windows対応）
    output = output.replace('\r\n', '\n').replace('\r', '\n')
    
    for line in output.split('\n'):
        line = line.strip()
        if not line:
            # 空行はスキップ
            continue
        
        # キー=値の形式をパース
        if '=' in line:
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip()
            
            if key == 'Caption':
                current_process['caption'] = value
            elif key == 'CommandLine':
                current_process['command_line'] = value
                # コマンドラインから実行ファイル情報を抽出
                executable_path, executable_name = parse_command_line(value)
                current_process['executable_path'] = executable_path
                current_process['executable_name'] = executable_name
            elif key == 'Name':
                current_process['name'] = value
            elif key == 'ProcessId':
                # ProcessIdでプロセス情報を完成させる
                if value:
                    try:
                        current_process['process_id'] = int(value)
                    except ValueError:
                        current_process['process_id'] = None
                
                # プロセス情報を追加
                if current_process and 'process_id' in current_process:
                    processes.append(current_process.copy())
                
                # 次のプロセス用に初期化
                current_process = {}
    
    # ProcessIdで処理済みのため、最後の処理は不要
    
    return processes


def generate_json_output(processes, settings):
    """プロセス情報リストをJSON形式で出力する"""
    output_data = {
        "execution_time": datetime.now().isoformat() + "Z",
        "processes": processes
    }
    
    try:
        return json.dumps(
            output_data,
            ensure_ascii=False,
            indent=settings.get('indent', 2)
        )
    except Exception as e:
        print(f"エラー: JSON生成に失敗しました: {repr(e)}", 
              file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        sys.exit(104)


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(
        description="WMIC PROCESS GET情報をパースしてJSON形式で出力するツール"
    )
    parser.add_argument(
        "output_file",
        nargs="?",
        help="出力ファイル（省略時は標準出力）"
    )
    
    args = parser.parse_args()
    
    try:
        # 設定ファイルを読み込み
        settings = load_settings()
        
        # WMICコマンドを実行
        wmic_output = execute_wmic()
        
        # 出力をパース
        processes = parse_wmic_output(wmic_output)
        
        # JSON形式で出力
        json_output = generate_json_output(processes, settings)
        
        if args.output_file:
            # ファイルに出力
            with open(args.output_file, 'w', encoding='utf-8') as f:
                f.write(json_output)
            print(f"出力完了: {args.output_file}", file=sys.stderr, flush=True)
        else:
            # 標準出力に出力
            print(json_output, flush=True)
    
    except KeyboardInterrupt:
        print("\nユーザーによって中断されました", file=sys.stderr, flush=True)
        sys.exit(130)
    except Exception as e:
        print(f"エラー: 予期しないエラーが発生しました: {repr(e)}", 
              file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        sys.exit(105)


if __name__ == "__main__":
    main()