-- ================================================================================
-- 実行順序: 06（05_extract_pdf_text.sql の後に実行）
-- 目的:     Gold層 Dynamic Table の作成
--           - GOLD_CONTRACTS: 契約・顧客・車両を結合したリース契約分析用テーブル
--           - GOLD_PAYMENT_SUMMARY: 契約別支払いサマリー
-- 前提:     以下のテーブルが存在すること
--           DEMO_DB.LEASING.CONTRACTS / CUSTOMERS / VEHICLES / PAYMENTS
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE DEMO_WH;
USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- 1. GOLD_CONTRACTS
--    契約・顧客・車両を結合したリース契約分析用テーブル
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE DEMO_DB.LEASING.GOLD_CONTRACTS
  TARGET_LAG = '1 hour'
  WAREHOUSE = DEMO_WH
  COMMENT = 'Gold層: 契約・顧客・車両を結合したリース契約分析用テーブル'
AS
SELECT
    -- 契約情報
    c.CONTRACT_ID,
    c.CONTRACT_TYPE,
    c.CONTRACT_START_DATE,
    c.CONTRACT_END_DATE,
    c.LEASE_TERM_MONTHS,
    c.MONTHLY_LEASE_AMOUNT,
    c.TOTAL_LEASE_AMOUNT,
    c.RESIDUAL_VALUE,
    c.STATUS,
    c.BRANCH_OFFICE,
    c.CREATED_AT AS CONTRACT_CREATED_AT,
    -- 顧客情報
    cu.CUSTOMER_ID,
    cu.COMPANY_NAME,
    cu.INDUSTRY,
    cu.PREFECTURE,
    cu.CITY,
    cu.ESTABLISHED_YEAR,
    cu.EMPLOYEE_COUNT,
    cu.ANNUAL_REVENUE_CLASS,
    -- 車両情報
    v.VEHICLE_ID,
    v.MANUFACTURER,
    v.MODEL_NAME,
    v.VEHICLE_TYPE,
    v.FUEL_TYPE,
    v.VEHICLE_PRICE,
    v.YEAR_MODEL,
    v.ENGINE_DISPLACEMENT
FROM DEMO_DB.LEASING.CONTRACTS c
JOIN DEMO_DB.LEASING.CUSTOMERS cu ON c.CUSTOMER_ID = cu.CUSTOMER_ID
JOIN DEMO_DB.LEASING.VEHICLES v ON c.VEHICLE_ID = v.VEHICLE_ID;

-- ============================================================
-- 2. GOLD_PAYMENT_SUMMARY
--    契約別支払いサマリー（PAYMENTS を CONTRACT_ID で集計）
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE DEMO_DB.LEASING.GOLD_PAYMENT_SUMMARY
  TARGET_LAG = '1 hour'
  WAREHOUSE = DEMO_WH
  COMMENT = 'Gold層: 契約別支払いサマリー'
AS
SELECT
    CONTRACT_ID,
    COUNT(*)                                                        AS TOTAL_PAYMENTS,
    SUM(PAYMENT_AMOUNT)                                             AS TOTAL_PAID,
    SUM(CASE WHEN PAYMENT_STATUS = 'paid'    THEN 1 ELSE 0 END)    AS PAID_COUNT,
    SUM(CASE WHEN PAYMENT_STATUS = 'overdue' THEN 1 ELSE 0 END)    AS OVERDUE_COUNT,
    SUM(CASE WHEN PAYMENT_STATUS = 'pending' THEN 1 ELSE 0 END)    AS PENDING_COUNT,
    MAX(PAYMENT_DATE)                                               AS LAST_PAYMENT_DATE,
    SUM(CASE WHEN PAYMENT_STATUS = 'overdue' THEN PAYMENT_AMOUNT ELSE 0 END) AS OVERDUE_AMOUNT
FROM DEMO_DB.LEASING.PAYMENTS
GROUP BY CONTRACT_ID;

-- ============================================================
-- 3. 確認用クエリ
-- ============================================================

-- Dynamic Table の一覧確認
SHOW DYNAMIC TABLES LIKE 'GOLD_%' IN SCHEMA DEMO_DB.LEASING;

-- GOLD_CONTRACTS の件数確認
SELECT COUNT(*) AS contract_count FROM DEMO_DB.LEASING.GOLD_CONTRACTS;

-- GOLD_PAYMENT_SUMMARY の件数確認
SELECT COUNT(*) AS payment_summary_count FROM DEMO_DB.LEASING.GOLD_PAYMENT_SUMMARY;

-- サンプルデータ確認
SELECT * FROM DEMO_DB.LEASING.GOLD_CONTRACTS        LIMIT 5;
SELECT * FROM DEMO_DB.LEASING.GOLD_PAYMENT_SUMMARY  LIMIT 5;
