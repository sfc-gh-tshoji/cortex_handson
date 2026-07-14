-- ================================================================================
-- リース契約分析基盤 — Cortex Search Service作成
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE DEMO_WH;
USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- 契約書ドキュメント検索サービス
-- ============================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE DEMO_DB.LEASING.SEARCH_CONTRACT_DOCS
  ON CONTENT
  ATTRIBUTES CUSTOMER_NAME, CONTRACT_ID, DOCUMENT_TYPE
  WAREHOUSE = DEMO_WH
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
    FROM DEMO_DB.LEASING.CONTRACT_DOCUMENTS
    WHERE CONTENT IS NOT NULL
      AND LENGTH(TRIM(CONTENT)) > 0
  );
