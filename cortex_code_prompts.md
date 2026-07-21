# Snowflake CoCo プロンプト集

## このファイルの使い方

各ステップのプロンプトを **Cortex Code（CoCo）** にコピー＆ペーストして実行します。

**Cortex Code の開き方**:
1. Snowsight（Snowflake の Web UI）にログイン
2. 左サイドバーの **「Cortex Code」** をクリック
3. テキストボックスにプロンプトを貼り付けて Enter

ステップ 1〜7 を順番に実行することでデモ環境が完成します。

**前提条件**: `setup_hol.sql` を実行済みであること（HOL_DB / HOL_DB.LEASING スキーマ・CONTRACTS_PDF_STAGE 作成済み）。

**対応する SQL ファイルとの対応**:

| CoCo ステップ | SQL ファイル |
|---|---|
| Step 1 データ探索 | （参照のみ） |
| Step 2 PDF テキスト抽出 | `03_extract_pdf_text.sql` |
| Step 3 Cortex Search 作成 | `04_create_cortex_search.sql` |
| Step 4 Dynamic Tables 作成（Gold 層） | `05_create_dynamic_tables_gold.sql` |
| Step 5 Semantic View 作成（Gold 層） | `06_create_semantic_view.sql` |
| Step 6 Cortex Agent 作成 | `07_create_cortex_agent.sql` |
| Step 7 動作確認 | （確認のみ） |

---

## Step 1: データ探索

### 目的
Bronze 層の各テーブル件数・サンプルデータ確認およびデータ整合性チェック

### プロンプト

```
HOL_DB.LEASING スキーマにあるテーブルについて、
各テーブルの件数、主なカラム、サンプルデータを確認して教えて
```

---

## Step 2: PDF テキスト抽出（CONTRACT_DOCUMENTS データ投入）

### 目的
CONTRACTS_PDF_STAGE に格納されている PDF ファイルから Cortex AI でテキストを抽出し、CONTRACT_DOCUMENTS テーブルに投入する

### プロンプト

```
HOL_DB.LEASING スキーマで以下の処理を実装・実行してください。

目的: CONTRACTS_PDF_STAGE ステージの PDF ファイルからテキストを抽出して CONTRACT_DOCUMENTS テーブルに投入する

要件:
1. SNOWFLAKE.CORTEX.PARSE_DOCUMENT を使って @HOL_DB.LEASING.CONTRACTS_PDF_STAGE 内の全 PDF をテキスト抽出
2. ファイルのサブフォルダ名でドキュメント種別をマッピング
   - lease_contracts       → リース契約書
   - vehicle_delivery      → 車両引渡書
   - maintenance_contracts → メンテナンス契約書
   - insurance_certificates → 保険証券
   - amendment_agreements  → リース変更合意書
3. 抽出テキストから正規表現で CONTRACT_ID（契約番号）と CUSTOMER_NAME（賃借人/引渡先/契約者/被保険者）を取得
4. DOCUMENT_ID は 'DOC' + 7 桁連番（DOC0000001 〜）で採番
5. 結果を HOL_DB.LEASING.CONTRACT_DOCUMENTS テーブルに INSERT

まず処理計画を説明してから SQL を生成して実行し、最後に投入件数と DOCUMENT_TYPE 別の内訳を確認してください。
```

---

## Step 3: Cortex Search Service 作成

### 目的
CONTRACT_DOCUMENTS テーブルをもとに契約書全文検索サービスを作成する

### プロンプト

```
HOL_DB.LEASING.CONTRACT_DOCUMENTS テーブルを使って Cortex Search Service を作成してください。

名前: SEARCH_CONTRACT_DOCS
検索カラム: CONTENT
属性カラム: CUSTOMER_NAME, CONTRACT_ID, DOCUMENT_TYPE
ウェアハウス: HOL_AD_WH
TARGET_LAG: 1 day

作成後、動作確認として「メンテナンス費用」で検索する SQL も生成してください。
```

---

## Step 4: Dynamic Tables 作成（Gold 層）

### 目的
Bronze 層テーブルを結合・集計して Gold 層 Dynamic Table を作成する

### プロンプト

```
HOL_DB.LEASING スキーマに以下の Gold 層 Dynamic Table を 2 つ作成してください。

1. GOLD_CONTRACTS
   - CONTRACTS + CUSTOMERS + VEHICLES を JOIN した分析用テーブル
   - TARGET_LAG: 1 hour
   - WAREHOUSE: HOL_AD_WH

2. GOLD_PAYMENT_SUMMARY
   - PAYMENTS を CONTRACT_ID でグループ集計
   - 集計カラム: 総支払回数・累計支払金額・支払済件数・延滞件数・保留件数・延滞金額・最終支払日
   - TARGET_LAG: 1 hour
   - WAREHOUSE: HOL_AD_WH

作成後、各 Dynamic Table の件数確認とサンプルデータを表示してください。
```

---

## Step 5: Semantic View 作成（Gold 層）

### 目的
Gold 層テーブルを参照する Semantic View を作成し、自然言語クエリを有効化する

### プロンプト

```
HOL_DB.LEASING スキーマに Semantic View を作成してください。

名前: LEASE_ANALYTICS

対象テーブル（Gold 層）:
- GOLD_CONTRACTS（主キー: CONTRACT_ID）: 契約・顧客・車両を結合済み
- GOLD_PAYMENT_SUMMARY（主キー: CONTRACT_ID）: 契約別支払いサマリー

リレーションシップ:
- GOLD_PAYMENT_SUMMARY.CONTRACT_ID → GOLD_CONTRACTS

各カラムには日本語のシノニムを付与してください（例: MANUFACTURER → 'メーカー', 'ブランド'）。
ビジネスユーザーが「業種別の月額リース料」「延滞率」「メーカー別契約件数」などの自然言語質問に答えられるよう設計してください。
```

---

## Step 6: Cortex Agent 作成

### 目的
Semantic View・Cortex Search・Web 検索を統合した分析エージェントを作成する

### プロンプト

```
HOL_DB.LEASING スキーマに Cortex Agent を作成してください。

名前: LEASE_ANALYST
エージェントの役割: リース事業データアナリスト

ツール構成:
1. query_lease_data
   - タイプ: cortex_analyst_text_to_sql
   - Semantic View: HOL_DB.LEASING.LEASE_ANALYTICS
   - 用途: 顧客・車両・契約・支払いの定量分析
2. search_contracts
   - タイプ: cortex_search
   - Search Service: HOL_DB.LEASING.SEARCH_CONTRACT_DOCS
   - 用途: 契約書・引渡書・保険証券などの全文検索
3. web_search
   - タイプ: web_search
   - 用途: 業界動向・法規制（IFRS16 等）の最新情報

回答ルール:
- すべての回答は日本語で行うこと
- データ分析にはかならず query_lease_data を使い、具体的な数値を含めること
- 複数ツールの組み合わせが有効な場合は積極的に併用すること
```

---

## Step 7: 動作確認

### 目的
作成した Cortex Agent（LEASE_ANALYST）が各ツールを正しく呼び出すか確認する

### プロンプト

```
Cortex Agent: HOL_DB.LEASING.LEASE_ANALYST の動作確認をします。

以下の質問を順番に試してください：

1. 「業種別のアクティブな契約件数と月額リース料の合計を教えて」
   → query_lease_data ツールが呼ばれることを確認

2. 「トヨタ車のメンテナンス契約の内容を教えて」
   → search_contracts ツールが呼ばれることを確認

3. 「IFRS16 のリース会計基準の最新動向は？」
   → web_search ツールが呼ばれることを確認

4. 「東京本社支店で延滞が多い業種はどこですか？対策を提案してください」
   → 複数ツールを組み合わせた回答になることを確認

各質問の後、どのツールが呼ばれたか確認し、回答の品質を評価してください。
```
