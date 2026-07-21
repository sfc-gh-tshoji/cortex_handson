-- ================================================================================
-- リース契約分析基盤 — Cortex Agent 作成
-- 実行順序: 07（06_create_semantic_view.sql の後に実行）
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE HOL_AD_WH;
USE SCHEMA HOL_DB.LEASING;

-- ============================================================
-- Cortex Agent 作成
-- ============================================================
CREATE OR REPLACE AGENT HOL_DB.LEASING.LEASE_ANALYST
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
    semantic_view: "HOL_DB.LEASING.LEASE_ANALYTICS"
    execution_environment:
      type: warehouse
      query_timeout: 299
  search_contracts:
    search_service: "HOL_DB.LEASING.SEARCH_CONTRACT_DOCS"
    max_results: 5
  web_search: {}
$$;
