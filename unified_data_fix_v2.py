import json
import re
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
import difflib

# Configuration
EXAM_CODES = ['06_haru', '05_haru', '04_haru', '03_haru', '02_aki', '01_aki', '31_haru', '30_aki', '30_haru', '29_aki']
BASE_URL = "https://www.itpassportsiken.com/kakomon/{}/q{}.html"
ORIGINAL_DATA_FILE = "assets/questions.json"
REPORT_FILE = "corruption_report.json"

MANUAL_FIXES = {
    24: {
        "question": "式は定期発注方式で原料の発注量を求める計算式である。a～cに入れる字句の適切な組合せはどれか。 発注量＝(a＋調達期間)×毎日の使用予定量＋b－現在の在庫量－c",
        "options": [
            "a:営業日数, b:安全在庫量, c:現在の発注残",
            "a:営業日数, b:現在の発注残, c:安全在庫量",
            "a:発注間隔, b:安全在庫量, c:現在の発注残",
            "a:発注間隔, b:現在の発注残, c:安全在庫量"
        ]
    }
}

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def normalize_for_match(text):
    if not text: return ""
    # Remove markers like a. b. c. 1. 2. 3. and Japanese symbols
    text = re.sub(r'[a-dA-D1-4]\.', '', text)
    # Remove all non-Japanese-characters and non-alphabet for broad matching
    return re.sub(r'[^\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fafA-Z]', '', text)

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
        
        question_text = ""
        for child in mondai_div.children:
            if child.name == 'table':
                rows = child.find_all('tr')
                for row in rows:
                    cells = row.find_all(['th', 'td'])
                    question_text += " [" + " | ".join([c.get_text(strip=True) for c in cells]) + "] "
            elif child.name == 'br': question_text += "\n"
            else: question_text += child.get_text()
        question_text = clean_text(question_text)
        
        options = []
        for opt_id in ['select_a', 'select_i', 'select_u', 'select_e']:
            span = soup.find(id=opt_id)
            if span:
                text = span.get_text(strip=True)
                if not text:
                    parent = span.parent
                    p_text = parent.get_text(strip=True)
                    text = re.sub(r'^[アイウエ]\s*', '', p_text).strip()
                options.append(text)
            else: options.append("")
        return {"question": question_text, "options": options, "norm": normalize_for_match(question_text)}
    except: return None

def main():
    with open(ORIGINAL_DATA_FILE, 'r', encoding='utf-8') as f:
        current_qs = json.load(f)
    with open(REPORT_FILE, 'r', encoding='utf-8') as f:
        report = json.load(f)
    problematic_ids = set(report['empty_options'] + report['merged_labels'])

    print("Scraping...")
    tasks = [(code, i) for code in EXAM_CODES for i in range(1, 101)]
    scraped_data = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(scrape_question, t): t for t in tasks}
        for future in as_completed(futures):
            res = future.result(); 
            if res: scraped_data.append(res)
    
    fixed_count = 0
    for q in current_qs:
        qid = q['id']
        if qid in MANUAL_FIXES:
            q.update(MANUAL_FIXES[qid])
            fixed_count += 1
            print(f"Applied manual fix for ID {qid}")
            continue

        if qid in problematic_ids:
            current_norm = normalize_for_match(q['question'])
            # Match logic
            match = next((s for s in scraped_data if s['norm'] == current_norm), None)
            if not match:
                # Try partial or fuzzy
                for s in scraped_data:
                    if current_norm and (current_norm in s['norm'] or s['norm'] in current_norm):
                        match = s; break
            
            if match:
                q['question'] = match['question']
                q['options'] = match['options']
                fixed_count += 1
                if "2台のWebサーバ" in q['question'] and "稼働率" in q['question']:
                    if "【図の説明】" not in q.get('explanation', ''):
                        q['explanation'] = "【図の説明】Webサーバ2台が並列に接続され、その先にデータベースサーバ1台が直列に接続されている構成です。\n\n" + q.get('explanation', '')

    with open(ORIGINAL_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(current_qs, f, indent=2, ensure_ascii=False)
    print(f"Finished. Fixed {fixed_count} questions.")

if __name__ == "__main__":
    main()
