-- ============================================================================
-- Step 1: 環境設定
-- ============================================================================
-- 環境設定のため、特権管理者ロールを使用
USE ROLE ACCOUNTADMIN;

-- クロスリージョンコールのパラメータを有効化
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- GitHubからデータを取得するためのAPI統合を作成
CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;

-- 管理者ロールとコンピュートウェアハウスを使用
USE ROLE SYSADMIN;

-- ウェアハウスの用意
CREATE ADAPTIVE WAREHOUSE IF NOT EXISTS HOL_AD_WH;
USE WAREHOUSE HOL_AD_WH;


-- ============================================================================
-- Step 2: データベースとスキーマの作成
-- ============================================================================

CREATE OR REPLACE DATABASE HOL_DB;
CREATE OR REPLACE SCHEMA HOL_DB.LEASING;
USE SCHEMA HOL_DB.LEASING;


-- ============================================================================
-- Step 3: データステージの作成
-- ============================================================================
-- PDF ファイルを格納するためのステージを作成（暗号化有効）
CREATE OR REPLACE STAGE HOL_DB.LEASING.CONTRACTS_PDF_STAGE
  encryption = (type = 'snowflake_sse') 
  DIRECTORY = (ENABLE = TRUE);


-- ============================================================================
-- Step 4: GitHub連携の設定
-- ============================================================================
-- Gitリポジトリとの統合を作成
CREATE OR REPLACE GIT REPOSITORY GIT_INTEGRATION_FOR_HANDSON
  API_INTEGRATION = git_api_integration
  ORIGIN = 'https://github.com/sfc-gh-tshoji/cortex_handson.git';


-- ============================================================================
-- Step 5: GitHubからデータファイルの取得
-- ============================================================================
-- リポジトリの内容を確認
ls @GIT_INTEGRATION_FOR_HANDSON/branches/main;

-- GitHub の pdfs ディレクトリからすべての PDF ファイルをステージにコピー
COPY FILES 
  INTO @HOL_DB.LEASING.CONTRACTS_PDF_STAGE
  FROM @GIT_INTEGRATION_FOR_HANDSON/branches/main/pdfs/;

-- ディレクトリテーブルをリフレッシュ（DIRECTORY() 関数で参照できるようにする）
ALTER STAGE HOL_DB.LEASING.CONTRACTS_PDF_STAGE REFRESH;

-- ステージ内のファイルを確認
ls @HOL_DB.LEASING.CONTRACTS_PDF_STAGE;
