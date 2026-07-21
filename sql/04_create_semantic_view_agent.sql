-- ================================================================================
-- リース契約分析基盤 — Semantic View + Cortex Agent 作成
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;
USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- 1. Semantic View 作成
-- ============================================================
CREATE OR REPLACE SEMANTIC VIEW DEMO_DB.LEASING.LEASE_ANALYTICS

  -- --------------------------------------------------------
  -- テーブル定義
  -- --------------------------------------------------------
  TABLES (
    customers AS DEMO_DB.LEASING.CUSTOMERS
      PRIMARY KEY (CUSTOMER_ID)
      WITH SYNONYMS ('顧客', '法人', '取引先', 'クライアント')
      COMMENT = '法人顧客マスタ',

    vehicles AS DEMO_DB.LEASING.VEHICLES
      PRIMARY KEY (VEHICLE_ID)
      WITH SYNONYMS ('車両', 'クルマ', '車', 'リース車両')
      COMMENT = '車両マスタ',

    contracts AS DEMO_DB.LEASING.CONTRACTS
      PRIMARY KEY (CONTRACT_ID)
      WITH SYNONYMS ('契約', 'リース契約', 'リース')
      COMMENT = 'リース契約テーブル',

    payments AS DEMO_DB.LEASING.PAYMENTS
      PRIMARY KEY (PAYMENT_ID)
      WITH SYNONYMS ('支払い', '入金', 'リース料支払い', '月次支払い')
      COMMENT = '月次支払い履歴'
  )

  -- --------------------------------------------------------
  -- リレーションシップ
  -- --------------------------------------------------------
  RELATIONSHIPS (
    contracts_to_customers AS
      contracts (CUSTOMER_ID) REFERENCES customers,
    contracts_to_vehicles AS
      contracts (VEHICLE_ID) REFERENCES vehicles,
    payments_to_contracts AS
      payments (CONTRACT_ID) REFERENCES contracts
  )

  -- --------------------------------------------------------
  -- ファクト（数値・計算対象カラム）
  -- --------------------------------------------------------
  FACTS (
    -- 車両
    vehicles.VEHICLE_PRICE           AS VEHICLE_PRICE
      WITH SYNONYMS ('車両価格', '本体価格', '車両本体価格')
      COMMENT = '車両本体価格（円）',
    vehicles.ENGINE_DISPLACEMENT     AS ENGINE_DISPLACEMENT
      WITH SYNONYMS ('排気量')
      COMMENT = '排気量（cc）',

    -- 契約
    contracts.LEASE_TERM_MONTHS      AS LEASE_TERM_MONTHS
      WITH SYNONYMS ('契約期間', 'リース期間', '契約月数')
      COMMENT = '契約期間（月）',
    contracts.MONTHLY_LEASE_AMOUNT   AS MONTHLY_LEASE_AMOUNT
      WITH SYNONYMS ('月額リース料', '月額', 'リース料')
      COMMENT = '月額リース料（円）',
    contracts.TOTAL_LEASE_AMOUNT     AS TOTAL_LEASE_AMOUNT
      WITH SYNONYMS ('リース料総額', '契約総額', '総額')
      COMMENT = 'リース料総額（円）',
    contracts.RESIDUAL_VALUE         AS RESIDUAL_VALUE
      WITH SYNONYMS ('残存価額', '残価')
      COMMENT = '残存価額（円）',

    -- 顧客
    customers.EMPLOYEE_COUNT         AS EMPLOYEE_COUNT
      WITH SYNONYMS ('従業員数', '社員数')
      COMMENT = '従業員数',

    -- 支払い
    payments.PAYMENT_AMOUNT          AS PAYMENT_AMOUNT
      WITH SYNONYMS ('支払金額', '入金額', '支払額')
      COMMENT = '支払金額（円）'
  )

  -- --------------------------------------------------------
  -- ディメンション（分析軸・属性カラム）
  -- --------------------------------------------------------
  DIMENSIONS (
    -- 顧客
    customers.CUSTOMER_ID            AS CUSTOMER_ID
      WITH SYNONYMS ('顧客ID', '顧客コード'),
    customers.COMPANY_NAME           AS COMPANY_NAME
      WITH SYNONYMS ('会社名', '法人名', '顧客名', '企業名'),
    customers.INDUSTRY               AS INDUSTRY
      WITH SYNONYMS ('業種', '業界'),
    customers.PREFECTURE             AS PREFECTURE
      WITH SYNONYMS ('都道府県', '所在地'),
    customers.CITY                   AS CITY
      WITH SYNONYMS ('市区町村'),
    customers.ESTABLISHED_YEAR       AS ESTABLISHED_YEAR
      WITH SYNONYMS ('設立年'),
    customers.ANNUAL_REVENUE_CLASS   AS ANNUAL_REVENUE_CLASS
      WITH SYNONYMS ('売上規模', '売上規模区分'),

    -- 車両
    vehicles.VEHICLE_ID              AS VEHICLE_ID
      WITH SYNONYMS ('車両ID', '車両コード'),
    vehicles.MANUFACTURER            AS MANUFACTURER
      WITH SYNONYMS ('メーカー', '自動車メーカー', 'ブランド'),
    vehicles.MODEL_NAME              AS MODEL_NAME
      WITH SYNONYMS ('モデル名', '車名', '車種名'),
    vehicles.VEHICLE_TYPE            AS VEHICLE_TYPE
      WITH SYNONYMS ('車種区分', '車種', '車両タイプ'),
    vehicles.FUEL_TYPE               AS FUEL_TYPE
      WITH SYNONYMS ('燃料タイプ', '燃料', '燃料種別'),
    vehicles.YEAR_MODEL              AS YEAR_MODEL
      WITH SYNONYMS ('年式', 'モデルイヤー'),

    -- 契約
    contracts.CONTRACT_ID            AS CONTRACT_ID
      WITH SYNONYMS ('契約ID', '契約番号'),
    contracts.CONTRACT_TYPE          AS CONTRACT_TYPE
      WITH SYNONYMS ('契約タイプ', '契約種別', 'リース種別'),
    contracts.CONTRACT_START_DATE    AS CONTRACT_START_DATE
      WITH SYNONYMS ('契約開始日', '開始日', 'リース開始日'),
    contracts.CONTRACT_END_DATE      AS CONTRACT_END_DATE
      WITH SYNONYMS ('契約終了日', '終了日', 'リース終了日', '満了日'),
    contracts.STATUS                 AS STATUS
      WITH SYNONYMS ('契約ステータス', 'ステータス', '契約状態'),
    contracts.BRANCH_OFFICE          AS BRANCH_OFFICE
      WITH SYNONYMS ('担当支店', '支店', '営業支店'),

    -- 支払い
    payments.PAYMENT_ID              AS PAYMENT_ID
      WITH SYNONYMS ('支払ID'),
    payments.PAYMENT_DATE            AS PAYMENT_DATE
      WITH SYNONYMS ('支払日', '入金日', '支払年月'),
    payments.PAYMENT_STATUS          AS PAYMENT_STATUS
      WITH SYNONYMS ('支払ステータス', '入金ステータス', '支払状態'),
    payments.PAYMENT_METHOD          AS PAYMENT_METHOD
      WITH SYNONYMS ('支払方法', '入金方法', '決済方法')
  )

  COMMENT = 'リース事業分析基盤。顧客・車両・契約・支払いの4テーブルから構成されるリース契約データを分析可能。'
;

-- ============================================================
-- 2. Cortex Agent 作成
-- ============================================================
CREATE OR REPLACE AGENT DEMO_DB.LEASING.LEASE_ANALYST
  COMMENT = 'リース事業データ分析エージェント（Semantic View + 契約書検索 + Web検索）'
  FROM SPECIFICATION
$$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 900
    tokens: 400000

instructions:
  orchestration: |
    あなたはリース事業のデータアナリストです。ユーザーからの質問に対して、以下のツールを適切に選択して回答してください。

    ## ツール選択ガイド
    - **query_lease_data**: リース契約データに関する定量的な質問に使用します。
      - 顧客分析（業種別、地域別の契約件数・金額）
      - 車両分析（メーカー別、車種別のリース状況）
      - 契約分析（契約タイプ別、支店別の実績）
      - 支払い分析（延滞率、支払方法別の推移）
      - 売上・KPI分析（月額リース料の推移、契約期間の分布）
    - **search_contracts**: 契約書の内容に関する質問に使用します。
      - 特定の契約書の条項や内容
      - 特定顧客の契約ドキュメント検索
      - メンテナンス契約や保険証券の詳細
      - 契約書テンプレートの確認
    - **web_search**: リース業界やモビリティ業界の外部情報が必要な質問に使用します。
      - 市場動向、業界トレンド
      - 競合他社の情報
      - 法規制、会計基準（IFRS16等）の最新情報

    ## 回答ルール
    - 日本語で回答してください
    - データに基づく質問には必ずquery_lease_dataを使用し、具体的な数値を含めて回答してください
    - 契約内容の質問にはsearch_contractsで関連ドキュメントを検索してください
    - 複数ツールの組み合わせが有効な場合は積極的に併用してください
  response: |
    日本語で簡潔かつ分かりやすく回答してください。
    - データを含む回答では重要な数値をハイライトしてください
    - 金額は「万円」「億円」など読みやすい単位を適宜使用してください
    - 必要に応じてインサイトや推奨アクションを添えてください

tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: query_lease_data
      description: >
        リース事業のデータ分析基盤にクエリを実行します。
        顧客マスタ（業種、都道府県、売上規模、従業員数）、
        車両マスタ（メーカー、モデル、車種区分、燃料タイプ、車両価格）、
        リース契約（契約タイプ、契約期間、月額リース料、リース料総額、残存価額、ステータス、担当支店）、
        支払い履歴（支払日、支払金額、支払ステータス、支払方法）のデータを取得・分析できます。
  - tool_spec:
      type: cortex_search
      name: search_contracts
      description: >
        リース契約関連ドキュメントを全文検索します。
        リース契約書、車両引渡書、メンテナンス契約書、保険証券、リース変更合意書の
        内容を検索し、契約条項の詳細や特定顧客の契約情報を取得できます。
  - tool_spec:
      type: web_search
      name: web_search
      description: >
        Web検索を実行して、リース業界・モビリティ業界の市場動向、
        業界ニュース、法規制、会計基準（IFRS16等）、競合情報、
        最新トレンドなどの外部情報を取得します。

tool_resources:
  query_lease_data:
    semantic_view: "DEMO_DB.LEASING.LEASE_ANALYTICS"
    execution_environment:
      type: warehouse
      query_timeout: 299
  search_contracts:
    search_service: "DEMO_DB.LEASING.SEARCH_CONTRACT_DOCS"
    max_results: 5
  web_search: {}
$$;
