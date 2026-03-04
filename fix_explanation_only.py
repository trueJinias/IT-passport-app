#!/usr/bin/env python3
"""
解説文に含まれる画像のみを削除するスクリプト
問題文の画像は残す
"""

import json
import re

def load_questions():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def save_questions(questions):
    with open('assets/questions.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)

def fix_explanations():
    questions = load_questions()
    
    pattern = r'!\[([^\]]*)\]\(([^)]+\.png[^)]*)\)'
    modified_count = 0
    
    for q in questions:
        explanation = q.get('explanation', '')
        question = q.get('question', '')
        
        # 解説文内の画像を検索
        exp_matches = re.findall(pattern, explanation)
        
        if exp_matches:
            # 解説文から画像タグを削除
            cleaned_explanation = re.sub(pattern, '', explanation)
            # 連続する空行を整理
            cleaned_explanation = re.sub(r'\n\n\n+', '\n\n', cleaned_explanation)
            
            q['explanation'] = cleaned_explanation
            modified_count += 1
            print(f"Fixed ID {q['id']}: Removed {len(exp_matches)} image(s) from explanation")
    
    save_questions(questions)
    print(f"\n合計 {modified_count} 件の解説文から画像を削除しました。")
    print("問題文の画像は残っています。")

if __name__ == '__main__':
    fix_explanations()
