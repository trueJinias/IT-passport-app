const fs = require('fs');
const path = require('path');

// Real Data Pool
// Format: { term: "Term", desc: "Description", category: "Category" }
const termPool = [
    // Strategy (ストラテジ系)
    { term: "CRM (Customer Relationship Management)", desc: "顧客満足度を向上させ、売上拡大と収益性向上を目指す経営手法。", category: "Strategy" },
    { term: "SFA (Sales Force Automation)", desc: "営業活動を効率化するため、顧客情報や商談状況を管理するシステム。", category: "Strategy" },
    { term: "SWOT分析", desc: "企業の強み・弱み・機会・脅威を分析し、戦略決定に役立てる手法。", category: "Strategy" },
    { term: "PDCAサイクル", desc: "Plan(計画)・Do(実行)・Check(評価)・Act(改善)を繰り返すことで業務を継続的に改善する手法。", category: "Strategy" },
    { term: "KPI (Key Performance Indicator)", desc: "目標達成に向けた活動の実行状況を計測するための重要業績評価指標。", category: "Strategy" },
    { term: "BCP (Business Continuity Plan)", desc: "災害やシステム障害などの緊急事態において、事業を継続するための計画。", category: "Strategy" },
    { term: "ERP (Enterprise Resource Planning)", desc: "企業の経営資源（ヒト・モノ・カネ・情報）を統合的に管理し、有効活用する手法。", category: "Strategy" },
    { term: "PPM (Product Portfolio Management)", desc: "事業や製品を「花形・金のなる木・問題児・負け犬」に分類し、資源配分を最適化する手法。", category: "Strategy" },
    { term: "BPO (Business Process Outsourcing)", desc: "自社の業務プロセスの一部を、外部の専門業者に委託すること。", category: "Strategy" },
    { term: "CSR (Corporate Social Responsibility)", desc: "企業が利益を追求するだけでなく、社会的な責任を果たすべきという考え方。", category: "Strategy" },
    { term: "M&A (Mergers and Acquisitions)", desc: "企業の合併や買収のこと。", category: "Strategy" },
    { term: "アライアンス", desc: "複数の企業が互いの利益のために提携し、協力体制を築くこと。", category: "Strategy" },

    // Management (マネジメント系)
    { term: "RPA (Robotic Process Automation)", desc: "定型的なパソコン操作などをソフトウェアロボットによって自動化する技術。", category: "Management" },
    { term: "SaaS (Software as a Service)", desc: "インターネット経由でソフトウェアの機能を利用するサービス提供形態。", category: "Management" },
    { term: "IaaS (Infrastructure as a Service)", desc: "インターネット経由でサーバーやネットワークなどのインフラ機能を利用するサービス提供形態。", category: "Management" },
    { term: "BYOD (Bring Your Own Device)", desc: "従業員が私物の端末（スマホやPC）を業務に利用すること。", category: "Management" },
    { term: "SLA (Service Level Agreement)", desc: "サービス提供者と利用者の間で合意したサービスレベル（品質基準）の契約。", category: "Management" },
    { term: "ITガバナンス", desc: "企業がITを適切に活用し、競争力を高めるための統治・管理の仕組み。", category: "Management" },
    { term: "プロジェクトマネジメント", desc: "プロジェクトを成功させるために、計画・実行・監視・制御を行う活動。", category: "Management" },

    // Technology (テクノロジ系)
    { term: "IoT (Internet of Things)", desc: "あらゆるモノがインターネットにつながり、情報をやり取りする仕組み。", category: "Technology" },
    { term: "AI (Artificial Intelligence)", desc: "人間の知的な振る舞いをコンピュータで模倣する技術。", category: "Technology" },
    { term: "ブロックチェーン", desc: "複数のコンピュータで取引記録を分散管理し、改ざんを困難にする技術。", category: "Technology" },
    { term: "フィッシング詐欺", desc: "実在する企業を装ったメールなどで偽サイトに誘導し、個人情報を盗み取る手口。", category: "Technology" },
    { term: "ランサムウェア", desc: "PC内のデータを暗号化して使用不能にし、復元のために身代金を要求するウイルス。", category: "Technology" },
    { term: "二要素認証", desc: "「記憶」「所持」「生体」のうち、2つの要素を組み合わせて行う本人確認方式。", category: "Technology" },
    { term: "バイオメトリクス認証", desc: "指紋や顔などの身体的特徴を利用して本人確認を行う方式。", category: "Technology" },
    { term: "ドローン", desc: "遠隔操作や自動操縦によって飛行する無人航空機。", category: "Technology" },
    { term: "ビッグデータ", desc: "従来のシステムでは扱いきれないほどの巨大で複雑なデータの集合。", category: "Technology" },
    { term: "VR (Virtual Reality)", desc: "コンピュータで作られた仮想空間を、あたかも現実であるかのように体験させる技術。", category: "Technology" },
    { term: "AR (Augmented Reality)", desc: "現実の風景にデジタルの情報を重ね合わせて表示する技術（拡張現実）。", category: "Technology" },
    { term: "プロトコル", desc: "コンピュータ同士が通信を行うための規約や手順。", category: "Technology" },
    { term: "オープンソースソフトウェア (OSS)", desc: "ソースコードが公開され、誰でも自由に利用・改変・再配布ができるソフトウェア。", category: "Technology" }
];

const generatedQuestions = [];
const TOTAL_QUESTIONS = 1000;

// Helper to get random items excluding one
function getRandomDistractors(targetTerm, count) {
    const distractors = [];
    const pool = termPool.filter(t => t.term !== targetTerm.term); // Exclude self

    while (distractors.length < count) {
        const d = pool[Math.floor(Math.random() * pool.length)];
        if (!distractors.includes(d)) {
            distractors.push(d);
        }
    }
    return distractors;
}

// Generate Questions
for (let i = 1; i <= TOTAL_QUESTIONS; i++) {
    // 1. Pick a Correct Answer Term
    const correctTerm = termPool[Math.floor(Math.random() * termPool.length)];

    // 2. Pick 3 Distractors
    const distractors = getRandomDistractors(correctTerm, 3);

    // 3. Formulate Question Options
    // Shuffle descriptions
    const optionTerms = [correctTerm, ...distractors];
    // Fisher-Yates Shuffle
    for (let k = optionTerms.length - 1; k > 0; k--) {
        const j = Math.floor(Math.random() * (k + 1));
        [optionTerms[k], optionTerms[j]] = [optionTerms[j], optionTerms[k]];
    }

    const correctIndex = optionTerms.indexOf(correctTerm);

    // Create Question Object
    // We vary the question format slightly to avoid complete monotony
    const qType = Math.random() > 0.5 ? "desc_to_term" : "term_to_desc";

    let qText = "";
    let options = [];

    if (qType === "term_to_desc") {
        qText = `「${correctTerm.term}」の説明として、適切なものはどれか。`;
        options = optionTerms.map(t => t.desc);
    } else {
        qText = `「${correctTerm.desc}」を指す用語として、適切なものはどれか。`;
        options = optionTerms.map(t => t.term);
    }

    generatedQuestions.push({
        "id": i,
        "question": qText,
        "options": options,
        "correctIndex": correctIndex,
        "explanation": `正解は「${correctTerm.term}」です。\n\n${correctTerm.desc}\n\n他の選択肢:\n${distractors.map(d => "・" + d.term + ": " + d.desc).join("\n")}`
    });
}

// Save to file
const outputPath = path.join(__dirname, 'assets', 'questions.json');
fs.writeFileSync(outputPath, JSON.stringify(generatedQuestions, null, 2), 'utf8');

console.log(`Successfully generated ${TOTAL_QUESTIONS} high-quality questions to ${outputPath}`);
