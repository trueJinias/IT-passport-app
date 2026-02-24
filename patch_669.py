import json

def patch_question_669():
    with open('assets/questions.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
        
    for q in questions:
        if q['id'] == 669:
            q['explanation'] = "【結論】\nドライブバイダウンロードとは、Webサイトにアクセスしただけで、ユーザーが気づかないうちにマルウェア（ウイルスなど）をダウンロードさせられる攻撃のことです。\n\n【理由】\n「ドライブバイ（車で通りがかりの）」という名前の通り、利用者が自らダウンロードボタンを押したり承諾したりしなくても、背景でプログラムが実行されてしまうため、非常に危険な攻撃です。多くの場合、OSやブラウザなどの脆弱性（セキュリティホール）を悪用して感染させます。\n\n【ポイント】\n- **DoS攻撃**（ア）\nサーバーやネットワークに大量の処理負荷を与え、サービスを停止させる攻撃です。\n- **ソーシャルエンジニアリング**（イ）\n人の心理的な隙などを突いて、パスワードなどの秘密情報を盗み出す手法です。\n- **バックドア**（エ）\n一度侵入したコンピュータに、次回から簡単に再侵入できるように設けられた「裏口」のことです。\n\nしたがって、正しい説明は「ウ」です。\n\n![ドライブバイダウンロードの図式](https://www.itpassportsiken.com/img/0369.png)"
            print("Patched explanatory text for ID 669.")
            break
            
    with open('assets/questions.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    patch_question_669()
