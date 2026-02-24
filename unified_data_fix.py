import json
import re
import requests
from bs4 import BeautifulSoup
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import difflib

# Configuration
EXAM_CODES = [
    '06_haru', '05_haru', '04_haru', '03_haru', 
    '02_aki', '01_aki', '31_haru', '30_aki', 
    '30_haru', '29_aki'
]
BASE_URL = "https://www.itpassportsiken.com/kakomon/{}/q{}.html"
ORIGINAL_DATA_FILE = "assets/questions.json"
REPORT_FILE = "corruption_report.json"

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def normalize_for_match(text):
    if not text: return ""
    return re.sub(r'[^\w\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]', '', text)

def scrape_question(args):
    exam_code, q_num = args
    url = BASE_URL.format(exam_code, q_num)
    try:
        response = requests.get(url, timeout=10)
        response.encoding = response.apparent_encoding
        if response.status_code != 200: return None
        soup = BeautifulSoup(response.text, 'html.parser')
        
        mondai_div = soup.find('div', id='mondai')
        if not mondai_div: return None
        
        # Robust question text extraction (including tables)
        question_text = ""
        for child in mondai_div.children:
            if child.name == 'table':
                rows = child.find_all('tr')
                for row in rows:
                    cells = row.find_all(['th', 'td'])
                    question_text += " [" + " | ".join([c.get_text(strip=True) for c in cells]) + "] "
            elif child.name == 'br':
                question_text += "\n"
            else:
                question_text += child.get_text()
        question_text = clean_text(question_text)
        
        options = []
        option_ids = ['select_a', 'select_i', 'select_u', 'select_e']
        for opt_id in option_ids:
            span = soup.find(id=opt_id)
            if span:
                text = span.get_text(strip=True)
                if not text:
                    # Try parent text if span is marker-only or empty
                    parent = span.parent
                    p_text = parent.get_text(strip=True)
                    # Remove common labels (ア. イ. ウ. エ. or ア イ ウ エ)
                    text = re.sub(r'^[アイウエ]\s*', '', p_text).strip()
                options.append(text)
            else:
                options.append("")
                
        return {
            "question": question_text,
            "options": options,
            "url": url,
            "norm": normalize_for_match(question_text)
        }
    except Exception as e:
        return None

def main():
    with open(ORIGINAL_DATA_FILE, 'r', encoding='utf-8') as f:
        current_qs = json.load(f)
    with open(REPORT_FILE, 'r', encoding='utf-8') as f:
        report = json.load(f)
    problematic_ids = set(report['empty_options'] + report['merged_labels'])

    print(f"Scraping...")
    tasks = [(code, i) for code in EXAM_CODES for i in range(1, 101)]
    scraped_data = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(scrape_question, t): t for t in tasks}
        for future in as_completed(futures):
            res = future.result()
            if res: scraped_data.append(res)
    
    fixed_count = 0
    for q in current_qs:
        if q['id'] in problematic_ids:
            current_norm = normalize_for_match(q['question'])
            # Priority 1: Exact norm match
            match = next((s for s in scraped_data if s['norm'] == current_norm), None)
            
            # Priority 2: Substring or high similarity
            if not match:
                for s in scraped_data:
                    if current_norm and (current_norm in s['norm'] or s['norm'] in current_norm):
                        match = s; break
            
            if match:
                q['question'] = match['question']
                q['options'] = match['options']
                fixed_count += 1
                
                # Special Symbol Fix: Web Server Availability (ID 72 or similar)
                if "2台のWebサーバ" in q['question'] and "稼働率" in q['question']:
                    if "【図の説明】" not in q['explanation']:
                        q['explanation'] = "【図の説明】Webサーバ2台が並列に接続され、その先にデータベースサーバ1台が直列に接続されている構成です。\n\n" + q['explanation']
            else:
                pass # Already logged in previous runs, usually very few

    with open(ORIGINAL_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(current_qs, f, indent=2, ensure_ascii=False)
    print(f"Finished. Fixed {fixed_count} questions.")

if __name__ == "__main__":
    main()
