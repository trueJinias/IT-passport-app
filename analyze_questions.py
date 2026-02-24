import json
import re

def analyze():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    empty_options = []
    merged_labels = []
    
    for q in questions:
        # Check empty options (some might be ["" ,"" ,"" ,""])
        if q.get('options') and all(opt.strip() == "" for opt in q['options']):
            empty_options.append(q['id'])
        
        # Check merged labels
        q_text = q.get('question', '')
        if 'a～' in q_text or 'a~' in q_text:
            # If it's one long block of text without markers like "a."
            if not re.search(r'[a-zA-Z]\.', q_text) and not re.search(r'[a-zA-Z]．', q_text):
                merged_labels.append(q['id'])

    report = {
        "empty_options": empty_options,
        "merged_labels": merged_labels,
        "total": len(set(empty_options + merged_labels))
    }
    
    with open('corruption_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"Report saved to corruption_report.json. Total problematic: {report['total']}")

if __name__ == "__main__":
    analyze()
