import json

def patch_question_187():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
        
    for q in questions:
        if q['id'] == 187:
            q['explanation'] = "【結論】\nエネルギーハーベスティングとは、太陽光、振動、熱、電磁波など、周囲の環境に存在するごくわずかなエネルギー（微小エネルギー）を集めて、電力に変換する技術のことです。\n\n【理由】\n「ハーベスト（収穫する）」という言葉の通り、環境中のエネルギーを拾い集めてデバイスを動かします。これにより、電池交換の難しい場所にあるIoT機器やセンサーを、外部から電源を供給することなく長期間稼働させることが可能になります。\n\n【ポイント】\n- **PLC (Power Line Communications)**（ア）\n既存の電力線（コンセントなど）に通信用の信号を乗せてデータ通信を行う技術です。\n- **PoE (Power over Ethernet)**（イ）\nLANケーブル（イーサネット）を使って通信と同時に電力を供給する技術です。\n- **スマートグリッド**（エ）\nIT技術を使って電力の需要と供給を自動で調整し、最適化する次世代の電力網のことです。\n\nしたがって、正しい説明は「ウ」です。"
            print("Patched explanation text for ID 187.")
            break
            
    with open('assets/questions.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    patch_question_187()
