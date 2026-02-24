import requests
from bs4 import BeautifulSoup
import json
import time
import re
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

# Target Exams (10 exams * 100 questions = 1000 questions)
EXAM_CODES = [
    '06_haru', '05_haru', '04_haru', '03_haru', 
    '02_aki', '01_aki', '31_haru', '30_aki', 
    '30_haru', '29_aki'
]

BASE_URL = "https://www.itpassportsiken.com/kakomon/{}/q{}.html"
OUTPUT_FILE = "assets/questions.json"

def clean_text(text):
    if not text:
        return ""
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def scrape_question(args):
    exam_code, q_num = args
    url = BASE_URL.format(exam_code, q_num)
    try:
        # Respectful delay
        time.sleep(0.1)
        
        response = requests.get(url, timeout=10)
        response.encoding = response.apparent_encoding
        
        if response.status_code != 200:
            return None
            
        soup = BeautifulSoup(response.text, 'html.parser')
        
        mondai_div = soup.find('div', id='mondai')
        if not mondai_div:
            return None
        question_text = clean_text(mondai_div.get_text())
        
        options = []
        option_ids = ['select_a', 'select_i', 'select_u', 'select_e']
        for opt_id in option_ids:
            span = soup.find('span', id=opt_id)
            if span:
                options.append(clean_text(span.get_text()))
            else:
                options.append("")
        
        ans_span = soup.find('span', id='answerChar')
        correct_char = ans_span.get_text().strip() if ans_span else ""
        correct_index = 0
        if correct_char == 'ア': correct_index = 0
        elif correct_char == 'イ': correct_index = 1
        elif correct_char == 'ウ': correct_index = 2
        elif correct_char == 'エ': correct_index = 3
        
        kaisetsu_div = soup.find('div', id='kaisetsu')
        explanation = ""
        if kaisetsu_div:
            for br in kaisetsu_div.find_all("br"):
                br.replace_with("\n")
            explanation = clean_text(kaisetsu_div.get_text(separator="\n"))
        
        return {
            "question": question_text,
            "options": options,
            "correctIndex": correct_index,
            "explanation": f"正解は「{correct_char}」です。\n\n{explanation}"
        }
    except Exception as e:
        print(f"Error scraping {url}: {e}")
        return None

def main():
    print("Starting concurrent scraping for ~1000 questions...", flush=True)
    all_tasks = []
    for code in EXAM_CODES:
        for i in range(1, 101):
            all_tasks.append((code, i))
            
    results = []
    # Max workers kept low to be polite but faster than serial
    with ThreadPoolExecutor(max_workers=8) as executor:
        future_to_args = {executor.submit(scrape_question, args): args for args in all_tasks}
        completed_count = 0
        for future in as_completed(future_to_args):
            res = future.result()
            if res:
                results.append(res)
            completed_count += 1
            if completed_count % 50 == 0:
                print(f"Processed {completed_count}/{len(all_tasks)} requests...", flush=True)
            
    # Assign IDs
    final_questions = []
    for idx, q in enumerate(results, start=1):
        q['id'] = idx
        final_questions.append(q)
        
    print(f"Total collected: {len(final_questions)}")
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_questions, f, indent=2, ensure_ascii=False)
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
