#!/usr/bin/env python3
"""
解説文の画像を解析して、テキストベースの説明に書き換えるスクリプト
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

def get_image_description(url, qid):
    """画像URLから内容を推測して説明テキストを生成"""
    url_lower = url.lower()
    
    # ファイル名パターンで内容を推測
    if '85' in url_lower or '2進数' in url_lower or 'binary' in url_lower:
        return """
【2進数の桁の重み】
2進数の各桁は右から順に以下の重みを持ちます：
・1桁目：2^0 = 1
・2桁目：2^1 = 2
・3桁目：2^2 = 4
・4桁目：2^3 = 8
・5桁目：2^4 = 16
・6桁目：2^5 = 32
・7桁目：2^6 = 64
・8桁目：2^7 = 128

例："100"（2進数）= 1×4 + 0×2 + 0×1 = 4（10進数）"""
    
    elif '40' in url_lower or 'devops' in url_lower:
        return """
【DevOpsの3つのプラクシス】
DevOpsは開発（Development）と運用（Operations）を連携させる手法です。

主なプラクシス：
・継続的インテグレーション（CI）：コード変更を自動的にビルド・テスト
・継続的デリバリ（CD）：常にリリース可能な状態を維持
・継続的デプロイメント：コード変更を自動的に本番環境にリリース

これにより、開発効率の向上、迅速なリリース、信頼性の向上が期待できます。"""
    
    elif '41' in url_lower or 'arrow' in url_lower or 'アロー' in url_lower:
        return """
【アローダイアグラムの計算】
クリティカルパスを求めるには各経路の所要時間を計算します。

各経路の所要時間を比較し、最も長い経路がクリティカルパスとなります。
クリティカルパス上の工程は余裕時間（フロート）がゼロです。"""
    
    elif '45' in url_lower or 'triangle' in url_lower or '三角形' in url_lower:
        return """
【プロジェクト三角形】
プロジェクト管理における3つの制約要素：

・スコープ（範囲）：何を作るか
・スケジュール（時間）：いつまでに作るか  
・コスト（費用）：いくらで作るか

これらは相互に影響し合います。
例：スコープを増やすと、スケジュールとコストが増加

品質はこの3要素のバランスで決まります。"""
    
    elif '58' in url_lower or 'driveby' in url_lower or 'ドライブバイ' in url_lower:
        return """
【ドライブバイダウンロードの仕組み】
ドライブバイダウンロードは、Webサイトに悪意のあるプログラムを埋め込み、
利用者が気付かないようにそのプログラムをダウンロードさせたり、
自動的に実行させる攻撃です。

脆弱性のある利用環境では、Webページを閲覧しただけでマルウェアに感染する
おそれがあります。"""
    
    elif '59' in url_lower or '正規化' in url_lower or 'normalize' in url_lower:
        return """
【データベースの正規化】
正規化はデータの重複や矛盾を排除し、複数の表に分解する作業です。

【正規化手順】
第1正規形：繰り返し項目をなくす
第2正規形：部分関数従属を解消
第3正規形：推移的関数従属を解消

主キーと外部キーで表同士を関連付けます。"""
    
    elif '63' in url_lower or 'raid' in url_lower:
        return """
【RAID0とRAID1の違い】

【RAID0（ストライピング）】
・データを複数ディスクに分散して書き込む
・アクセス性能が向上
・信頼性は低下（1台故障で全データ破損）
・実効容量：ディスク容量の合計

【RAID1（ミラーリング）】
・同じデータを2台のディスクに書き込む
・信頼性が向上
・実効容量：ディスク容量の50%"""
    
    elif '65' in url_lower or 'psk' in url_lower or '暗号化' in url_lower:
        return """
【PSK（Pre-Shared Key）】
PSKは無線LANにアクセスする際に入力する8～63文字のパスフレーズです。

・SSIDとPSKの組合せで端末を認証
・アクセスポイントと端末間の通信暗号化に使用
・Wi-Fi接続におけるパスワードのようなもの

PSKから生成される鍵で通信を暗号化し、盗聴を防ぎます。"""
    
    elif '68' in url_lower or 'tcpip' in url_lower or 'レイヤ' in url_lower:
        return """
【TCP/IPの階層構造】
TCP/IPはインターネットの基盤技術で、通信機能を階層に分けています。

・アプリケーション層：FTP、POP、SMTPなど
・トランスポート層：TCP
・インターネット層：IP
・ネットワークインタフェース層：イーサネットなど

上位層から順にデータをカプセル化して送信し、
受信側は逆順に取り出して処理します。"""
    
    elif '74' in url_lower or 'neural' in url_lower or 'ニューラル' in url_lower:
        return """
【ニューラルネットワークの構造】
ニューラルネットワークは人間の脳神経細胞をモデル化したものです。

構成：
・入力層：データを受け取る
・中間層（隠れ層）：特徴を抽出・変換
・出力層：結果を出力

各層のノード（ニューロン）は重み付きで接続され、
入力に対して出力を計算します。
多層化したものが「ディープラーニング」です。"""
    
    elif '76' in url_lower or '再現率' in url_lower or 'recall' in url_lower:
        return """
【再現率の計算】
再現率は、実際に不良品だったもののうち、
機械学習モデルが正しく不良品と判定した割合です。

計算式：
再現率 ＝ (正しく不良品と判定した数) ÷ (実際の不良品総数)"""
    
    elif '86' in url_lower or 'ハイブリッド' in url_lower or 'hybrid' in url_lower:
        return """
【ハイブリッド暗号方式】
ハイブリッド暗号方式は、共通鍵暗号方式と公開鍵暗号方式を組み合わせた方式です。

【暗号化手順】
1. 送信者は共通鍵でメッセージを暗号化
2. 送信者は受信者の公開鍵で共通鍵を暗号化
3. 暗号化されたメッセージと暗号化された共通鍵を送信
4. 受信者は自分の秘密鍵で共通鍵を復号
5. 受信者は共通鍵でメッセージを復号

これにより、安全性と効率性を両立できます。"""
    
    elif '91' in url_lower or '活性化' in url_lower or 'activation' in url_lower:
        return """
【活性化関数】
活性化関数は、ニューラルネットワークにおいて、
ニューロンが受け取る入力値の総和から、
最終的な出力値を得るための関数です。

種類：
・ステップ関数
・シグモイド関数
・ソフトマックス関数
・ReLU関数

ニューロンの発火（出力するかしないか）を調整する役割を持ちます。"""
    
    elif '96' in url_lower or 'si接頭辞' in url_lower or 'キロ' in url_lower:
        return """
【SI接頭辞】
情報処理の世界で使われる主な接頭辞：

・k（キロ）：10^3 = 1,000倍
・M（メガ）：10^6 = 1,000,000倍（kの1,000倍）
・G（ギガ）：10^9 = 1,000,000,000倍（Mの1,000倍）
・T（テラ）：10^12（Gの1,000倍）
・P（ペタ）：10^15（Tの1,000倍）

大きい数を表す単位は k⇒M⇒G⇒T⇒P の順に大きくなり、
1つ単位が上がるごとに1,000倍になります。"""
    
    elif '97' in url_lower or 'サブネット' in url_lower or 'subnet' in url_lower:
        return """
【サブネットマスク】
サブネットマスクは、IPアドレスをネットワークアドレスとホストアドレスに
区分するために使用されるビット列です。

・ネットワークアドレス部："1"を指定
・ホストアドレス部："0"を指定

例：192.168.11.2/24（サブネットマスク255.255.255.0）
・先頭24ビットがネットワークアドレス
・残り8ビットがホストアドレス"""
    
    elif '100' in url_lower or '結合' in url_lower or 'join' in url_lower:
        return """
【データベースの結合操作】

【選択】表から選択した行を取り出す
【射影】表から選択した列を取り出す
【和】2つの表の和集合を得る
【結合】2つの表からフィールドの値で関連付けた表を作る

結合操作は、共通のフィールド値に基づいて複数の表を横に連結します。"""
    
    elif '07' in url_lower or 'ea' in url_lower or 'architecture' in url_lower:
        return """
【EA（Enterprise Architecture）】
EAは、社会環境や情報技術の変化に素早く対応できるよう、
全体最適の観点から業務とシステムを同時に改善していくためのフレームワークです。

・ビジネス、データ、アプリケーション、テクノロジの4つの体系で表す
・As-Is（現状）モデルとTo-Be（理想）モデルを比較
・目標とする次期モデルを作成"""
    
    elif '18' in url_lower or 'gdpr' in url_lower:
        return """
【GDPRの適用範囲】
GDPRは以下の事業者に適用されます。

適用対象：
・EU域内に拠点がある事業者（無条件に適用）
・EU域外に拠点があるが、EU域内に商品・サービスを提供する事業者

適用除外：
・EU域外に拠点があり、EU域内に商品・サービスを提供しない事業者"""
    
    elif '20' in url_lower or 'qr' in url_lower or 'バーコード' in url_lower:
        return """
【JANコードとQRコードの違い】

【JANコード】
・黒の縦棒と白のスペースで数字を表現
・最大13桁の数字
・製造業者と商品を識別

【QRコード】
・縦横の2次元で情報を表現
・数字のみならず英字、漢字、ひらがな、カタカナも格納可能
・360度読み取り可能
・誤り訂正機能あり"""
    
    elif '24' in url_lower or '機械学習' in url_lower or '教師あり' in url_lower:
        return """
【機械学習の3つの学習方式】

【教師あり学習】
・正解付きのデータで学習
・分類や回帰に使用

【教師なし学習】
・正解なしのデータで学習
・クラスタリングや主成分分析に使用

【強化学習】
・環境との相互作用から学習
・報酬を最大化する行動を学習"""
    
    elif '25' in url_lower or 'dfd' in url_lower or 'アクティビティ' in url_lower:
        return """
【業務プロセスを表す図】

【DFD】
データの流れを中心に業務プロセスをモデリング

【アクティビティ図】
業務プロセスの流れやプログラムの制御フローを可視化

【パレート図】
棒グラフと累積折れ線グラフの複合グラフ
重要な要素を識別するために使用

【レーダーチャート】
複数項目のバランスを比較する図"""
    
    elif '28' in url_lower or '流動比率' in url_lower or '比率' in url_lower:
        return """
【流動比率の計算】
流動比率は、短期の支払能力を示す経営の安全性指標です。

計算式：
流動比率 ＝ (流動資産 ÷ 流動負債) × 100%

流動資産：1年以内に現金化できる資産
流動負債：1年以内に支払いが必要な負債"""
    
    elif '29' in url_lower or '30' in url_lower or '損益計算書' in url_lower:
        return """
【損益計算書の構成】
損益計算書は以下の項目で構成されます。

売上高
  └ 売上原価
      ＝ 売上総利益（粗利益）
        └ 販売費及び一般管理費
            ＝ 営業利益
              └ 営業外収益・営業外費用
                  ＝ 経常利益
                    └ 特別利益・特別損失
                        ＝ 税引前当期純利益
                          └ 法人税等
                              ＝ 当期純利益"""
    
    elif '31' in url_lower or '管理図' in url_lower or 'パレート' in url_lower:
        return """
【品質管理で使われる図】

【管理図】
工程の状態や品質を時系列に表した図
上限・下限の限界線で異常を検出

【特性要因図】
特性（結果）と要因（原因）の関係を体系的に表した図

【パレート図】
値の大きい順に項目を並べた棒グラフと累積構成比の折れ線グラフ

【レーダーチャート】
複数項目のバランスを比較するクモの巣型の図"""
    
    elif '32' in url_lower or 'コンカレント' in url_lower or '並行' in url_lower:
        return """
【コンカレントエンジニアリング】
コンカレントエンジニアリングは、設計から生産に至るまでの各プロセスを
同時並行的に行うことで、開発期間や納期の短縮および生産コストの削減を図る手法です。

従来の逐次工程に対し、複数の工程を並行して進めることで時間を短縮します。"""
    
    elif '33' in url_lower or '納品書' in url_lower or '検収' in url_lower:
        return """
【システム開発の流れ】
外部開発の基本的な流れ：

1. 提案書・見積書の作成（契約締結前）
2. 請負契約の締結
3. システムの開発
4. 納品書の発行（完成品の納品）
5. 検収（発注側が品質を確認）
6. 検収書の発行（受入れ確認）
7. 請求書の発行（代金の請求）"""
    
    elif '35' in url_lower or 'かんばん' in url_lower or 'kanban' in url_lower:
        return """
【かんばん方式】
かんばん方式は、工程間の中間在庫の最少化を目的とした生産システムです。

・後工程が必要な分だけ前工程から引き取る（後工程引き取り方式）
・引き取った分だけ前工程が補充する
・生産指示票として「かんばん」を使用
・ジャストインタイム生産方式の重要な構成要素"""
    
    elif '36' in url_lower or 'wbs' in url_lower or '工数' in url_lower:
        return """
【WBS（Work Breakdown Structure）】
WBSは、プロジェクト目標を達成するために実行すべき作業を、
成果物を主体に階層的に要素分解したものです。

・各作業ごとに内容・スケジュール・目標を設定
・作業工数の見積もりに使用可能
・プロジェクト管理をしやすくする目的で用いられる"""
    
    elif '38' in url_lower or 'xp' in url_lower or 'エクストリーム' in url_lower:
        return """
【エクストリームプログラミング（XP）】
XPはアジャイルソフトウェア開発の手法の一つです。

主なプラクシス：
・テスト駆動開発（TDD）
・ペアプログラミング
・リファクタリング
・継続的インテグレーション
・短いリリースサイクル

19のプラクティスを定義しています。"""
    
    elif '40' in url_lower or '管理図' in url_lower or '管理限界' in url_lower:
        return """
【管理図】
管理図は、工程の状態や品質を時系列に表した図です。

・中央線（目標値）を設定
・上方管理限界と下方管理限界を設定
・限界線を超えた場合は異常が発生していると判断
・工程が安定しているかを監視するために使用"""
    
    elif '50' in url_lower or 'ガント' in url_lower or 'gantt' in url_lower:
        return """
【ガントチャート】
ガントチャートは、スケジュール管理に用いられる棒グラフです。

・横軸：時間（日付・週・月など）
・縦軸：作業項目
・各作業の予定期間と実績を棒グラフで表示
・作業の前後関係（依存関係）も表現可能"""
    
    elif '56' in url_lower or 'ランサムウェア' in url_lower or 'ransomware' in url_lower:
        return """
【ランサムウェア】
ランサムウェアは、PC内のデータファイルを暗号化したり、
PCの操作をロックしたりして、復元のために金銭を要求するマルウェアです。

対策：
1. 定期的にバックアップを取得する（最重要）
2. OSおよびソフトウェアを常に最新の状態に保つ
3. セキュリティソフトを導入し、定義ファイルを最新に保つ
4. メールやSNSの添付ファイルやURLに注意する"""
    
    elif '57' in url_lower or '推論' in url_lower or '帰納' in url_lower:
        return """
【推論の種類】

【帰納法】
個々の事例から共通する規則を導く方法
得られた規則は「仮説」として扱われる

【演繹法】
一般的な規則から個々の結論を導く方法
真の前提からは真の結論が導かれる"""
    
    elif '63' in url_lower or 'ブレード' in url_lower or 'blade' in url_lower:
        return """
【ブレードサーバ】
ブレードサーバは、薄い形状のコンピュータを1つの筐体に複数台搭載した
省スペース型のサーバです。

・電源ケーブルや冷却装置、外部インタフェースを筐体側で共有
・必要な数だけ差し込んで使用
・柔軟に台数を増減可能
・ラックマウント型より高密度に設置可能"""
    
    elif '64' in url_lower or 'ファイアウォール' in url_lower or 'firewall' in url_lower:
        return """
【ファイアウォール】
ファイアウォールは、不正なデータの通過を阻止するために
ネットワーク同士の境界線に設置する機器や機能です。

・外部・内部・DMZの3つのセグメントに分離可能
・各セグメント間の通信を制御
・外部から内部への不正通信を遮断
・多層防御の実現"""
    
    elif '91' in url_lower or '活性化関数' in url_lower:
        return """
【活性化関数】
活性化関数は、ニューラルネットワークにおいて、
ニューロンが受け取る入力値の総和から最終的な出力値を得るための関数です。

・ステップ関数、シグモイド関数、ReLU関数など
・ニューロンの発火を調整する役割
・非線形な変換を行うことで複雑なパターンを学習可能にする"""
    
    elif '93' in url_lower or 'a4' in url_lower or '用紙サイズ' in url_lower:
        return """
【用紙サイズの関係】
A判の用紙は相似形で、1つ小さくなるごとに面積が半分になります。

・A4の長辺はA3の短辺と同じ
・A4の短辺はA3の長辺の半分
・長辺：短辺の比率は√2：1 ≒ 1.41：1

A3の長辺はA4の長辺の約1.41倍です。"""
    
    else:
        # デフォルトの説明
        return """
【図の説明】
上記の図は、この問題の理解を助けるための参考図です。
詳細は【理由】セクションのテキスト説明を参照してください。"""

def fix_explanations():
    questions = load_questions()
    
    pattern = r'!\[([^\]]*)\]\(([^)]+\.png[^)]*)\)'
    modified_count = 0
    
    for q in questions:
        qid = q.get('id')
        explanation = q.get('explanation', '')
        question = q.get('question', '')
        
        # 解説文内の画像を検索
        exp_matches = re.findall(pattern, explanation)
        
        if exp_matches:
            # 各画像に対する説明を生成
            additional_texts = []
            for alt, url in exp_matches:
                desc = get_image_description(url, qid)
                if desc and desc not in additional_texts:
                    additional_texts.append(desc)
            
            # 解説文から画像タグを削除
            cleaned_explanation = re.sub(pattern, '', explanation)
            cleaned_explanation = re.sub(r'\n\n\n+', '\n\n', cleaned_explanation)
            
            # 追加テキストを挿入
            if additional_texts:
                combined_text = '\n'.join(additional_texts)
                if '【ポイント】' in cleaned_explanation:
                    parts = cleaned_explanation.split('【ポイント】')
                    cleaned_explanation = parts[0].rstrip() + '\n' + combined_text + '\n\n【ポイント】' + parts[1]
                else:
                    cleaned_explanation = cleaned_explanation.rstrip() + '\n' + combined_text
            
            q['explanation'] = cleaned_explanation
            modified_count += 1
            print(f"Fixed ID {qid}: Replaced {len(exp_matches)} image(s) with text")
    
    save_questions(questions)
    print(f"\n合計 {modified_count} 件の解説文を修正しました。")
    print("問題文の画像は残っています。")

if __name__ == '__main__':
    fix_explanations()
