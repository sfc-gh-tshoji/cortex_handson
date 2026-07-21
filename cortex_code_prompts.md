# Snowflake CoCo プロンプト集

## このファイルの使い方

各ステップのプロンプトを Snowsight の **Snowflake CoCo** にコピー＆ペーストして実行します。

**Cortex Code の開き方**:
1. Snowsight（Snowflake の Web UI）にログイン
2. 左サイドバーの **「Snowflake CoCo」** をクリック
3. テキストボックスにプロンプトを貼り付けて Enter

ステップ1〜6を順番に実行することで、デモ環境が完成します。

---

## Step 1: データ探索

### 目的
Bronze層の各テーブル件数・サンプルデータ確認およびデータ整合性チェック

### プロンプト

```
DEMO_DB.LEASING スキーマにあるテーブルについて、
各テーブルの件数、主なカラム、サンプルデータを確認して教えて
```

---

## Step 2: Dynamic Tables（Gold層）作成

### 目的
Bronze層テーブルを結合・集計してGold層 Dynamic Table を作成する

### プロンプト

```
DEMO_DB.LEASING スキーマに以下のGold層 Dynamic Table を作成したい。まずは作成計画を立てて。

1. GOLD_CONTRACTS: CONTRACTS + CUSTOMERS + VEHICLES を結合したテーブル

2. GOLD_PAYMENT_SUMMARY: PAYMENTS を CONTRACT_ID でグループ集計
```

---

## Step 3: Semantic View 作成

### 目的
Gold層テーブルを参照する Semantic View を作成し、自然言語クエリを有効化する

### プロンプト

```
DEMO_DB.LEASING スキーマに Semantic View を作成してください。

名前: LEASE_ANALYTICS
対象テーブル:
- GOLD_CONTRACTS
- GOLD_PAYMENT_SUMMARY

各カラムには日本語のシノニムを付与してください（例: MANUFACTURER → 'メーカー', 'ブランド'）。
ビジネスユーザーが「業種別の月額リース料」「延滞率」「メーカー別契約件数」などの自然言語質問に答えられるよう設計してください。
```

---

## Step 4: Cortex Search Service 作成

### 目的
CONTRACT_DOCUMENTS テーブルをもとに契約書全文検索サービスを作成する

### プロンプト

```
DEMO_DB.LEASING.CONTRACT_DOCUMENTS テーブルを使って Cortex Search Service を作成してください。

名前: SEARCH_CONTRACT_DOCS

作成後、動作確認として「メンテナンス費用」で検索するSQLも生成してください。
```

---

## Step 5: Cortex Agent 作成

### 目的
Semantic View・Cortex Search・Web 検索を統合した分析エージェントを作成する

### プロンプト

```
DEMO_DB.LEASING スキーマに Cortex Agent を作成してください。

名前: LEASE_ANALYST

エージェントの役割: リース事業データアナリスト
- データ分析（業種別・地域別・車種別の集計）
- 契約書内容の検索
- 業界動向・法規制に関するウェブ検索
すべての回答は日本語で行うこと。
```

---

## Step 6: Snowflake CoWork 動作確認

### 目的
作成した Cortex Agent（LEASE_ANALYST）が各ツールを正しく呼び出すか確認する

### プロンプト

```
Cortex Agent: LEASE_ANALYST に関して動作確認します。

以下の質問を順番に試してください：

1. 「業種別のアクティブな契約件数と月額リース料の合計を教えて」
   → query_lease_data ツールが呼ばれることを確認

2. 「トヨタ車のメンテナンス契約の内容を教えて」
   → search_contracts ツールが呼ばれることを確認

3. 「IFRS16のリース会計基準の最新動向は？」
   → web_search ツールが呼ばれることを確認

4. 「東京本社支店で延滞が多い業種はどこですか？対策を提案してください」
   → 複数ツールを組み合わせた回答になることを確認

各質問の後、どのツールが呼ばれたか確認し、回答の品質を評価してください。
```
