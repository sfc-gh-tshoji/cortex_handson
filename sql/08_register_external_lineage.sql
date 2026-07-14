-- ================================================================================
-- 目的:     Horizon Catalog に外部リネージを手動登録し、
--           Snowsight Lineage Graph で外部ソース（PostgreSQL / SharePoint）を可視化する
-- 前提:     このSQLはデモ用の手動リネージ登録。
--           実際の本番環境では Openflow が自動登録するため、このスクリプトは不要。
-- 注意:     SYSTEM$SET_LINEAGE の実行には ACCOUNTADMIN 権限が必要。
--           実行後は SYSADMIN に戻すこと。
-- ================================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_WH;
USE SCHEMA DEMO_DB.LEASING;

-- ============================================================
-- PostgreSQL（基幹リースシステム）からの流入を登録
-- ============================================================

-- CUSTOMERS テーブルへの外部リネージ登録
CALL SYSTEM$SET_LINEAGE(
  'TABLE',
  'DEMO_DB.LEASING.CUSTOMERS',
  PARSE_JSON('[{
    "objectDomain": "External Table",
    "objectName": "postgresql://leasing-db.tokyocentury.internal/leasing_system/public/customers",
    "externalSystem": {
      "systemType": "POSTGRESQL",
      "systemName": "PostgreSQL (基幹リースシステム)"
    }
  }]')
);

-- VEHICLES テーブルへの外部リネージ登録
CALL SYSTEM$SET_LINEAGE(
  'TABLE',
  'DEMO_DB.LEASING.VEHICLES',
  PARSE_JSON('[{
    "objectDomain": "External Table",
    "objectName": "postgresql://leasing-db.tokyocentury.internal/leasing_system/public/vehicles",
    "externalSystem": {
      "systemType": "POSTGRESQL",
      "systemName": "PostgreSQL (基幹リースシステム)"
    }
  }]')
);

-- CONTRACTS テーブルへの外部リネージ登録
CALL SYSTEM$SET_LINEAGE(
  'TABLE',
  'DEMO_DB.LEASING.CONTRACTS',
  PARSE_JSON('[{
    "objectDomain": "External Table",
    "objectName": "postgresql://leasing-db.tokyocentury.internal/leasing_system/public/contracts",
    "externalSystem": {
      "systemType": "POSTGRESQL",
      "systemName": "PostgreSQL (基幹リースシステム)"
    }
  }]')
);

-- PAYMENTS テーブルへの外部リネージ登録
CALL SYSTEM$SET_LINEAGE(
  'TABLE',
  'DEMO_DB.LEASING.PAYMENTS',
  PARSE_JSON('[{
    "objectDomain": "External Table",
    "objectName": "postgresql://leasing-db.tokyocentury.internal/leasing_system/public/payments",
    "externalSystem": {
      "systemType": "POSTGRESQL",
      "systemName": "PostgreSQL (基幹リースシステム)"
    }
  }]')
);

-- ============================================================
-- SharePoint（社内ドキュメント管理）からの流入を登録
-- ============================================================

-- CONTRACT_DOCUMENTS テーブルへの外部リネージ登録
CALL SYSTEM$SET_LINEAGE(
  'TABLE',
  'DEMO_DB.LEASING.CONTRACT_DOCUMENTS',
  PARSE_JSON('[{
    "objectDomain": "External Table",
    "objectName": "sharepoint://tokyocentury.sharepoint.com/sites/contracts/documents",
    "externalSystem": {
      "systemType": "SHAREPOINT",
      "systemName": "SharePoint (社内ドキュメント管理)"
    }
  }]')
);

-- ============================================================
-- 権限を SYSADMIN に戻す
-- ============================================================
USE ROLE SYSADMIN;

-- ============================================================
-- リネージ確認用クエリ（参考例 — 必要に応じてコメント解除）
-- ============================================================

-- CUSTOMERS テーブルの上流リネージを確認
-- SELECT SYSTEM$GET_LINEAGE('TABLE', 'DEMO_DB.LEASING.CUSTOMERS', 'upstream', 3);

-- GOLD_CONTRACTS テーブルのリネージを確認（Bronze → Gold の流れ）
-- SELECT SYSTEM$GET_LINEAGE('TABLE', 'DEMO_DB.LEASING.GOLD_CONTRACTS', 'upstream', 5);

-- LEASE_ANALYST Agent のリネージを確認（エンドツーエンドの流れ）
-- SELECT SYSTEM$GET_LINEAGE('AGENT', 'DEMO_DB.LEASING.LEASE_ANALYST', 'upstream', 10);
