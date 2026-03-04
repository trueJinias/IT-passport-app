#!/usr/bin/env python3
"""
問題文と解説文の画像を区別して確認するスクリプト
"""

import json
import re

def main():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 解説文のみに画像を含む問題を検索
    pattern = r'!\[([^\]]*)\]\(([^)]+\.png[^)]*)\)'
    
    results = []
    for q in data:
        explanation = q.get('explanation', '')
        question = q.get('question', '')
        
        # 解説文内の画像を検索
        exp_matches = re.findall(pattern, explanation)
        # 問題文内の画像を検索
        q_matches = re.findall(pattern, question)
        
        if exp_matches:
            results.append({
                'id': q['id'],
                'url': q.get('url', ''),
                'explanation_images': [m[1] for m in exp_matches],
                'question_images': [m[1] for m in q_matches]
            })

    print(f'解説文に画像を含む問題数: {len(results)}')
    print()
    
    print('=== 問題文と解説文の両方に画像があるケース ===')
    both_count = 0
    for r in results:
        if r['question_images']:
            both_count += 1
            if both_count <= 10:
                print(f"ID {r['id']}: {r['url']}")
                print(f"  問題文の画像: {r['question_images']}")
                print(f"  解説文の画像: {r['explanation_images']}")
                print()
    
    print(f'\n両方に画像がある問題数: {both_count}')
    
    print('\n=== 解説文のみに画像があるケース ===')
    only_exp_count = 0
    for r in results:
        if not r['question_images']:
            only_exp_count += 1
            if only_exp_count <= 10:
                print(f"ID {r['id']}: {r['url']}")
                print(f"  解説文の画像: {r['explanation_images']}")
                print()
    
    print(f'\n解説文のみに画像がある問題数: {only_exp_count}')

if __name__ == '__main__':
    main()
