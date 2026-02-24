import requests
from bs4 import BeautifulSoup
import re

def normalize_for_match(text):
    if not text: return ""
    return re.sub(r'[^\w\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]', '', text)

def check():
    url = "https://www.itpassportsiken.com/kakomon/06_haru/q24.html"
    response = requests.get(url)
    response.encoding = response.apparent_encoding
    soup = BeautifulSoup(response.text, 'html.parser')
    mondai_div = soup.find('div', id='mondai')
    
    scraped_text = mondai_div.get_text()
    scraped_norm = normalize_for_match(scraped_text)
    
    # Current text in questions.json
    current_text = "式は定期発注方式で原料の発注量を求める計算式である。 a～cに入れる字句の適切な組合せはどれか。 発注量＝(a＋調達期間)×毎日の使用予定量＋b－現在の在庫量－c"
    current_norm = normalize_for_match(current_text)
    
    print(f"Scraped Norm: {scraped_norm}")
    print(f"Current Norm: {current_norm}")
    print(f"Match? {scraped_norm == current_norm}")

if __name__ == "__main__":
    check()
