-- ================================================================================
-- 04_create_semantic_view_agent.sql の Semantic View部分を Gold層参照に更新
-- 実行順序: 07（06_create_dynamic_tables_gold.sql の後に実行）
-- 目的:     LEASE_ANALYTICS Semantic View を Bronze 4テーブル構成から
--           Gold 2テーブル構成（GOLD_CONTRACTS / GOLD_PAYMENT_SUMMARY）に変更する
-- 変更概要: CUSTOMERS / VEHICLES / CONTRACTS / PAYMENTS → GOLD_CONTRACTS / GOLD_PAYMENT_SUMMARY
--           クエリパフォーマンス向上・Horizon Catalog リネージ完全可視化
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;
USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- Semantic View 更新（Gold層参照）
-- ============================================================
CREATE OR REPLACE SEMANTIC VIEW DEMO_DB.LEASING.LEASE_ANALYTICS

  -- --------------------------------------------------------
  -- テーブル定義（Gold層 2テーブル）
  -- --------------------------------------------------------
  TABLES (
    gold_contracts AS DEMO_DB.LEASING.GOLD_CONTRACTS
      PRIMARY KEY (CONTRACT_ID)
      WITH SYNONYMS ('契約', 'リース契約', '契約データ', 'リース')
      COMMENT = 'Gold層: 契約・顧客・車両を結合したリース契約分析用テーブル',

    gold_payment_summary AS DEMO_DB.LEASING.GOLD_PAYMENT_SUMMARY
      PRIMARY KEY (CONTRACT_ID)
      WITH SYNONYMS ('支払い', '入金', '支払いサマリー', '月次支払い')
      COMMENT = 'Gold層: 契約別支払いサマリー'
  )

  -- --------------------------------------------------------
  -- リレーションシップ（1リレーション）
  -- --------------------------------------------------------
  RELATIONSHIPS (
    payment_summary_to_contracts AS
      gold_payment_summary (CONTRACT_ID) REFERENCES gold_contracts
  )

  -- --------------------------------------------------------
  -- ファクト（数値・計算対象カラム）
  -- --------------------------------------------------------
  FACTS (
    -- 車両（GOLD_CONTRACTS に含まれる）
    gold_contracts.VEHICLE_PRICE           AS VEHICLE_PRICE
      WITH SYNONYMS ('車両価格', '本体価格', '車両本体価格')
      COMMENT = '車両本体価格（円）',
    gold_contracts.ENGINE_DISPLACEMENT     AS ENGINE_DISPLACEMENT
      WITH SYNONYMS ('排気量')
      COMMENT = '排気量（cc）',

    -- 契約（GOLD_CONTRACTS に含まれる）
    gold_contracts.LEASE_TERM_MONTHS       AS LEASE_TERM_MONTHS
      WITH SYNONYMS ('契約期間', 'リース期間', '契約月数')
      COMMENT = '契約期間（月）',
    gold_contracts.MONTHLY_LEASE_AMOUNT    AS MONTHLY_LEASE_AMOUNT
      WITH SYNONYMS ('月額リース料', '月額', 'リース料')
      COMMENT = '月額リース料（円）',
    gold_contracts.TOTAL_LEASE_AMOUNT      AS TOTAL_LEASE_AMOUNT
      WITH SYNONYMS ('リース料総額', '契約総額', '総額')
      COMMENT = 'リース料総額（円）',
    gold_contracts.RESIDUAL_VALUE          AS RESIDUAL_VALUE
      WITH SYNONYMS ('残存価額', '残価')
      COMMENT = '残存価額（円）',

    -- 顧客（GOLD_CONTRACTS に含まれる）
    gold_contracts.EMPLOYEE_COUNT          AS EMPLOYEE_COUNT
      WITH SYNONYMS ('従業員数', '社員数')
      COMMENT = '従業員数',

    -- 支払いサマリー（GOLD_PAYMENT_SUMMARY）
    gold_payment_summary.TOTAL_PAID        AS TOTAL_PAID
      WITH SYNONYMS ('支払金額', '入金額', '支払額')
      COMMENT = '累計支払金額（円）',
    gold_payment_summary.TOTAL_PAYMENTS    AS TOTAL_PAYMENTS
      WITH SYNONYMS ('支払回数', '支払件数', '総支払回数')
      COMMENT = '総支払回数',
    gold_payment_summary.PAID_COUNT        AS PAID_COUNT
      WITH SYNONYMS ('支払済件数', '完了件数')
      COMMENT = '支払済み件数',
    gold_payment_summary.OVERDUE_COUNT     AS OVERDUE_COUNT
      WITH SYNONYMS ('延滞件数', '遅延件数')
      COMMENT = '延滞件数',
    gold_payment_summary.OVERDUE_AMOUNT    AS OVERDUE_AMOUNT
      WITH SYNONYMS ('延滞金額', '遅延金額')
      COMMENT = '延滞金額（円）'
  )

  -- --------------------------------------------------------
  -- ディメンション（分析軸・属性カラム）
  -- --------------------------------------------------------
  DIMENSIONS (
    -- 顧客（GOLD_CONTRACTS に含まれる）
    gold_contracts.CUSTOMER_ID             AS CUSTOMER_ID
      WITH SYNONYMS ('顧客ID', '顧客コード'),
    gold_contracts.COMPANY_NAME            AS COMPANY_NAME
      WITH SYNONYMS ('会社名', '法人名', '顧客名', '企業名'),
    gold_contracts.INDUSTRY                AS INDUSTRY
      WITH SYNONYMS ('業種', '業界'),
    gold_contracts.PREFECTURE              AS PREFECTURE
      WITH SYNONYMS ('都道府県', '所在地'),
    gold_contracts.CITY                    AS CITY
      WITH SYNONYMS ('市区町村'),
    gold_contracts.ESTABLISHED_YEAR        AS ESTABLISHED_YEAR
      WITH SYNONYMS ('設立年'),
    gold_contracts.ANNUAL_REVENUE_CLASS    AS ANNUAL_REVENUE_CLASS
      WITH SYNONYMS ('売上規模', '売上規模区分'),

    -- 車両（GOLD_CONTRACTS に含まれる）
    gold_contracts.VEHICLE_ID              AS VEHICLE_ID
      WITH SYNONYMS ('車両ID', '車両コード'),
    gold_contracts.MANUFACTURER            AS MANUFACTURER
      WITH SYNONYMS ('メーカー', '自動車メーカー', 'ブランド'),
    gold_contracts.MODEL_NAME              AS MODEL_NAME
      WITH SYNONYMS ('モデル名', '車名', '車種名'),
    gold_contracts.VEHICLE_TYPE            AS VEHICLE_TYPE
      WITH SYNONYMS ('車種区分', '車種', '車両タイプ'),
    gold_contracts.FUEL_TYPE               AS FUEL_TYPE
      WITH SYNONYMS ('燃料タイプ', '燃料', '燃料種別'),
    gold_contracts.YEAR_MODEL              AS YEAR_MODEL
      WITH SYNONYMS ('年式', 'モデルイヤー'),

    -- 契約（GOLD_CONTRACTS に含まれる）
    gold_contracts.CONTRACT_ID             AS CONTRACT_ID
      WITH SYNONYMS ('契約ID', '契約番号'),
    gold_contracts.CONTRACT_TYPE           AS CONTRACT_TYPE
      WITH SYNONYMS ('契約タイプ', '契約種別', 'リース種別'),
    gold_contracts.CONTRACT_START_DATE     AS CONTRACT_START_DATE
      WITH SYNONYMS ('契約開始日', '開始日', 'リース開始日'),
    gold_contracts.CONTRACT_END_DATE       AS CONTRACT_END_DATE
      WITH SYNONYMS ('契約終了日', '終了日', 'リース終了日', '満了日'),
    gold_contracts.STATUS                  AS STATUS
      WITH SYNONYMS ('契約ステータス', 'ステータス', '契約状態'),
    gold_contracts.BRANCH_OFFICE           AS BRANCH_OFFICE
      WITH SYNONYMS ('担当支店', '支店', '営業支店'),

    -- 支払いサマリー（GOLD_PAYMENT_SUMMARY）
    gold_payment_summary.LAST_PAYMENT_DATE AS LAST_PAYMENT_DATE
      WITH SYNONYMS ('最終支払日', '最終入金日', '直近支払日')
  )

  COMMENT = 'リース事業分析基盤（Gold層参照）。GOLD_CONTRACTS・GOLD_PAYMENT_SUMMARYの2テーブルから構成。'
;

-- ============================================================
-- 検証用クエリ
-- ============================================================
SELECT * FROM DEMO_DB.LEASING.LEASE_ANALYTICS LIMIT 3;
