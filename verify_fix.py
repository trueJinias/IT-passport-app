#!/usr/bin/env python3
"""
修正結果を確認するスクリプト
"""

import json
import re

def main():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    pattern = r'!\[([^\]]*)\]\(([^)]+\.png[^)]*)\)'
    
    # 問題文に画像が残っているか確認
    question_with_images = 0
    explanation_with_images = 0
    
    for q in data:
        question = q.get('question', '')
        explanation = q.get('explanation', '')
        
        if re.findall(pattern, question):
            question_with_images += 1
        
        if re.findall(pattern, explanation):
            explanation_with_images += 1
    
    print(f'問題文に画像を含む問題数: {question_with_images}')
    print(f'解説文に画像を含む問題数: {explanation_with_images}')
    print()
    
    # サンプル表示
    print('=== 問題文に画像が残っているサンプル ===')
    shown = 0
    for q in data:
        question = q.get('question', '')
        matches = re.findall(pattern, question)
        if matches and shown < 5:
            print(f"ID {q['id']}: {q.get('url', '')}")
            print(f"  画像URL: {matches[0][1]}")
            shown += 1

if __name__ == '__main__':
    main()
