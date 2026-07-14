-- ============================================================
-- 05_extract_pdf_text.sql
-- PDFからテキストを抽出し CONTRACT_DOCUMENTS テーブルに追加
-- 
-- 前提:
--   - CONTRACT_PDF_STAGE_UNENC（SNOWFLAKE_SSE暗号化）に110件のPDFが格納済
--   - PARSE_DOCUMENT はクライアントサイド暗号化ステージ非対応のため
--     SNOWFLAKE_SSE ステージを使用
--
-- 使用方法:
--   Snowsight または snow sql で実行
-- ============================================================

USE DATABASE DEMO_DB;
USE SCHEMA LEASING;
USE WAREHOUSE DEMO_WH;

-- ──────────────────────────────────────────────
-- 1. PDFテキスト抽出結果を格納する一時テーブル
-- ──────────────────────────────────────────────
CREATE OR REPLACE TEMPORARY TABLE _pdf_extracted AS
SELECT
    d.RELATIVE_PATH,
    -- ファイル名からIDプレフィックスを取得（DOC0000001 or IRR001）
    SPLIT_PART(SPLIT_PART(d.RELATIVE_PATH, '/', -1), '_', 1) AS FILE_ID,
    -- サブフォルダからドキュメント種別をマッピング
    SPLIT_PART(d.RELATIVE_PATH, '/', 1) AS SUBFOLDER,
    -- PARSE_DOCUMENTでテキスト抽出
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @CONTRACT_PDF_STAGE_UNENC,
        d.RELATIVE_PATH
    ):content::VARCHAR AS EXTRACTED_TEXT
FROM DIRECTORY(@CONTRACT_PDF_STAGE_UNENC) d
WHERE d.RELATIVE_PATH LIKE '%.pdf';

-- 抽出結果の確認
SELECT SUBFOLDER, COUNT(*) AS cnt
FROM _pdf_extracted
GROUP BY SUBFOLDER
ORDER BY SUBFOLDER;

-- ──────────────────────────────────────────────
-- 2. ドキュメント種別マッピング＋メタデータ付与
-- ──────────────────────────────────────────────
CREATE OR REPLACE TEMPORARY TABLE _pdf_with_metadata AS
SELECT
    -- DOCUMENT_ID: 既存データ(DOC0010000まで)の続番
    'DOC' || LPAD(
        (ROW_NUMBER() OVER (ORDER BY p.RELATIVE_PATH) + 10000)::INT::VARCHAR,
        7, '0'
    ) AS DOCUMENT_ID,
    -- 契約番号: テキストから「契約番号:」行を正規表現で抽出
    COALESCE(
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '契約番号:\\s*([A-Z0-9\\-]+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '契約番号: ([A-Z0-9\\-]+)', 1, 1, 'e'),
        NULL
    ) AS CONTRACT_ID,
    -- 顧客名: 賃借人/引渡先/契約者/被保険者 を順に検索
    COALESCE(
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '賃借人:\\s*(.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '賃借人: (.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '引渡先:\\s*(.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '引渡先: (.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '契約者:\\s*(.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '契約者: (.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '被保険者:\\s*(.+)', 1, 1, 'e'),
        REGEXP_SUBSTR(p.EXTRACTED_TEXT, '被保険者: (.+)', 1, 1, 'e'),
        NULL
    ) AS CUSTOMER_NAME,
    -- ドキュメント種別: サブフォルダ名からマッピング
    CASE p.SUBFOLDER
        WHEN 'lease_contracts'       THEN 'リース契約書'
        WHEN 'vehicle_delivery'      THEN '車両引渡書'
        WHEN 'maintenance_contracts' THEN 'メンテナンス契約書'
        WHEN 'insurance_certificates' THEN '保険証券'
        WHEN 'amendment_agreements'  THEN 'リース変更合意書'
        WHEN 'irregular'             THEN
            -- irregularはファイル名から種別を取得
            SPLIT_PART(
                REPLACE(SPLIT_PART(p.RELATIVE_PATH, '/', -1), '.pdf', ''),
                '_', 2
            )
        ELSE 'その他'
    END AS DOCUMENT_TYPE,
    -- テキスト本文
    p.EXTRACTED_TEXT AS CONTENT,
    CURRENT_TIMESTAMP() AS CREATED_AT,
    -- メタデータ（元ファイルパス・ソース種別）
    p.RELATIVE_PATH AS SOURCE_PATH,
    p.FILE_ID,
    CASE WHEN p.SUBFOLDER = 'irregular' THEN TRUE ELSE FALSE END AS IS_IRREGULAR
FROM _pdf_extracted p;

-- メタデータ確認
SELECT DOCUMENT_ID, CONTRACT_ID, CUSTOMER_NAME, DOCUMENT_TYPE, IS_IRREGULAR,
       LEFT(CONTENT, 100) AS CONTENT_PREVIEW
FROM _pdf_with_metadata
ORDER BY DOCUMENT_ID
LIMIT 20;

-- ──────────────────────────────────────────────
-- 3. CONTRACT_DOCUMENTS テーブルに追加
-- ──────────────────────────────────────────────
INSERT INTO CONTRACT_DOCUMENTS (DOCUMENT_ID, CONTRACT_ID, CUSTOMER_NAME, DOCUMENT_TYPE, CONTENT, CREATED_AT)
SELECT DOCUMENT_ID, CONTRACT_ID, CUSTOMER_NAME, DOCUMENT_TYPE, CONTENT, CREATED_AT
FROM _pdf_with_metadata;

-- 挿入結果の確認
SELECT 
    DOCUMENT_TYPE,
    COUNT(*) AS cnt,
    COUNT(CASE WHEN DOCUMENT_ID > 'DOC0010000' THEN 1 END) AS new_rows
FROM CONTRACT_DOCUMENTS
GROUP BY DOCUMENT_TYPE
ORDER BY DOCUMENT_TYPE;

-- 全体件数確認
SELECT COUNT(*) AS total_documents FROM CONTRACT_DOCUMENTS;

-- ──────────────────────────────────────────────
-- 4. Cortex Searchサービスのデータソース更新
--    （既にCHANGE_TRACKINGが有効なので自動反映される）
-- ──────────────────────────────────────────────
-- 手動で即時反映させたい場合は以下を実行:
-- ALTER CORTEX SEARCH SERVICE SEARCH_CONTRACT_DOCS REFRESH;

-- 後片付け
DROP TABLE IF EXISTS _pdf_extracted;
DROP TABLE IF EXISTS _pdf_with_metadata;
