-- ================================================================================
-- リース契約分析基盤 — Cortex Search Service作成
-- 実行順序: 04（03_extract_pdf_text.sql の後に実行）
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE HOL_AD_WH;
USE SCHEMA HOL_DB.LEASING;

-- ============================================================
-- 契約書ドキュメント検索サービス
-- ============================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE HOL_DB.LEASING.SEARCH_CONTRACT_DOCS
  ON CONTENT
  ATTRIBUTES CUSTOMER_NAME, CONTRACT_ID, DOCUMENT_TYPE
  WAREHOUSE = HOL_AD_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'リース契約書ドキュメント検索サービス'
  AS (
    SELECT
        DOCUMENT_ID,
        CONTRACT_ID,
        CUSTOMER_NAME,
        DOCUMENT_TYPE,
        CONTENT
    FROM HOL_DB.LEASING.CONTRACT_DOCUMENTS
    WHERE CONTENT IS NOT NULL
      AND LENGTH(TRIM(CONTENT)) > 0
  );
