-- ================================================================================
-- リース契約分析基盤 — スキーマ・テーブル定義
-- ================================================================================
-- 実行順序:
--   01_create_schema_tables.sql    : スキーマ・テーブル作成
--   02_insert_sample_data.sql      : サンプルデータ投入
--   03_create_cortex_search.sql    : Cortex Search Service作成
--   04_create_semantic_view_agent.sql : Semantic View + Agent作成
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE DEMO_WH;

-- ============================================================
-- 1. スキーマ作成
-- ============================================================
CREATE SCHEMA IF NOT EXISTS DEMO_DB.LEASING
  COMMENT = 'リース事業分析ハンズオン用スキーマ';

USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- 2. 法人顧客マスタ
-- ============================================================
CREATE OR REPLACE TABLE DEMO_DB.LEASING.CUSTOMERS (
    CUSTOMER_ID         VARCHAR(20)     NOT NULL PRIMARY KEY,
    COMPANY_NAME        VARCHAR(200)    NOT NULL,
    INDUSTRY            VARCHAR(50)     COMMENT '業種',
    PREFECTURE          VARCHAR(20)     COMMENT '都道府県',
    CITY                VARCHAR(50)     COMMENT '市区町村',
    ESTABLISHED_YEAR    NUMBER(4,0)     COMMENT '設立年',
    EMPLOYEE_COUNT      NUMBER(10,0)    COMMENT '従業員数',
    ANNUAL_REVENUE_CLASS VARCHAR(20)    COMMENT '売上規模区分',
    CONTACT_NAME        VARCHAR(100)    COMMENT '担当者名',
    CONTACT_EMAIL       VARCHAR(200)    COMMENT '担当者メール',
    REGISTERED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'リース契約の法人顧客マスタ';

-- ============================================================
-- 3. 車両マスタ
-- ============================================================
CREATE OR REPLACE TABLE DEMO_DB.LEASING.VEHICLES (
    VEHICLE_ID          VARCHAR(20)     NOT NULL PRIMARY KEY,
    MANUFACTURER        VARCHAR(50)     COMMENT 'メーカー',
    MODEL_NAME          VARCHAR(100)    COMMENT 'モデル名',
    VEHICLE_TYPE        VARCHAR(30)     COMMENT '車種区分',
    ENGINE_DISPLACEMENT NUMBER(6,0)     COMMENT '排気量(cc)',
    VEHICLE_PRICE       NUMBER(12,0)    COMMENT '車両本体価格',
    FUEL_TYPE           VARCHAR(20)     COMMENT '燃料タイプ',
    YEAR_MODEL          NUMBER(4,0)     COMMENT '年式',
    REGISTERED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'リース対象の車両マスタ';

-- ============================================================
-- 4. リース契約テーブル
-- ============================================================
CREATE OR REPLACE TABLE DEMO_DB.LEASING.CONTRACTS (
    CONTRACT_ID         VARCHAR(20)     NOT NULL PRIMARY KEY,
    CUSTOMER_ID         VARCHAR(20)     NOT NULL,
    VEHICLE_ID          VARCHAR(20)     NOT NULL,
    CONTRACT_TYPE       VARCHAR(30)     COMMENT '契約タイプ（ファイナンスリース/オペレーティングリース/メンテナンスリース）',
    CONTRACT_START_DATE DATE            NOT NULL COMMENT '契約開始日',
    CONTRACT_END_DATE   DATE            NOT NULL COMMENT '契約終了日',
    LEASE_TERM_MONTHS   NUMBER(3,0)     COMMENT '契約期間（月）',
    MONTHLY_LEASE_AMOUNT NUMBER(12,0)   COMMENT '月額リース料',
    TOTAL_LEASE_AMOUNT  NUMBER(14,0)    COMMENT 'リース料総額',
    RESIDUAL_VALUE      NUMBER(12,0)    COMMENT '残存価額',
    STATUS              VARCHAR(20)     COMMENT '契約ステータス（active/completed/terminated/pending）',
    BRANCH_OFFICE       VARCHAR(50)     COMMENT '担当支店',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'リース契約テーブル';

-- ============================================================
-- 5. 支払い履歴テーブル
-- ============================================================
CREATE OR REPLACE TABLE DEMO_DB.LEASING.PAYMENTS (
    PAYMENT_ID          VARCHAR(30)     NOT NULL PRIMARY KEY,
    CONTRACT_ID         VARCHAR(20)     NOT NULL,
    PAYMENT_DATE        DATE            NOT NULL COMMENT '支払日',
    PAYMENT_AMOUNT      NUMBER(12,0)    COMMENT '支払金額',
    PAYMENT_STATUS      VARCHAR(20)     COMMENT '支払ステータス（paid/overdue/pending）',
    PAYMENT_METHOD      VARCHAR(20)     COMMENT '支払方法（口座振替/銀行振込/クレジット）',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'リース契約の月次支払い履歴';

-- ============================================================
-- 6. 契約書ドキュメント（Cortex Search用）
-- ============================================================
CREATE OR REPLACE TABLE DEMO_DB.LEASING.CONTRACT_DOCUMENTS (
    DOCUMENT_ID         VARCHAR(20)     NOT NULL PRIMARY KEY,
    CONTRACT_ID         VARCHAR(20)     COMMENT '関連契約番号',
    CUSTOMER_NAME       VARCHAR(200)    COMMENT '顧客名',
    DOCUMENT_TYPE       VARCHAR(50)     COMMENT 'ドキュメント種別',
    CONTENT             VARCHAR(16777216) COMMENT 'テキストコンテンツ',
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'リース契約関連ドキュメント（Cortex Search用）';
