# Cortex Handson — リース事業分析基盤

Snowflake Cortex の主要機能（Dynamic Tables・Semantic View・Cortex Search・Cortex Agent）を使って、リース事業分析基盤を構築するハンズオンです。

## アーキテクチャ

```
Bronze層（生テーブル）
  CUSTOMERS / VEHICLES / CONTRACTS / PAYMENTS / CONTRACT_DOCUMENTS
        ↓ Dynamic Tables
Gold層
  GOLD_CONTRACTS / GOLD_PAYMENT_SUMMARY
        ↓
  LEASE_ANALYTICS（Semantic View）  +  SEARCH_CONTRACT_DOCS（Cortex Search）
        ↓
  LEASE_ANALYST（Cortex Agent）
```

## 前提条件

- Snowflake アカウント（Enterprise 以上）
- SYSADMIN ロール
- ウェアハウス `DEMO_WH`（任意の名前で作成可。スクリプト内の `DEMO_WH` を置き換えてください）
- データベース `DEMO_DB`（事前に作成しておくか、スクリプト冒頭に `CREATE DATABASE IF NOT EXISTS DEMO_DB;` を追加してください）

## セットアップ手順

`sql/` フォルダ内のスクリプトを番号順に Snowsight または SnowSQL で実行します。

| ステップ | ファイル | 内容 |
|---|---|---|
| 1 | `01_create_schema_tables.sql` | スキーマ・テーブル（5テーブル）作成 |
| 2 | `02_insert_sample_data.sql` | サンプルデータ投入（顧客3万社・車両2万種・契約20万件ほか） |
| 3 | `03_create_cortex_search.sql` | Cortex Search Service（`SEARCH_CONTRACT_DOCS`）作成 |
| 4 | `04_create_semantic_view_agent.sql` | Semantic View（`LEASE_ANALYTICS`）＋ Cortex Agent（`LEASE_ANALYST`）作成 |
| 5 ※オプション | `05_extract_pdf_text.sql` | ステージ上の PDF から AI_PARSE_DOCUMENT でテキスト抽出 |
| 6 | `06_create_dynamic_tables_gold.sql` | Dynamic Tables（`GOLD_CONTRACTS` / `GOLD_PAYMENT_SUMMARY`）作成 |
| 7 | `07_update_semantic_view.sql` | Semantic View を Gold 層参照に更新（パフォーマンス向上） |
| 8 ※上級 | `08_register_external_lineage.sql` | 外部システム（PostgreSQL / SharePoint）のリネージ手動登録（要 ACCOUNTADMIN） |

> **ステップ5について**: PDF ファイルをステージ `CONTRACT_PDF_STAGE_UNENC` にアップロードした後に実行してください。PDF なしの場合はスキップできます。
>
> **ステップ8について**: Horizon Catalog に外部システムのリネージを登録するデモ用スクリプトです。ACCOUNTADMIN ロールが必要です。

## Cortex Code を使ったインタラクティブなハンズオン

`cortex_code_prompts.md` に各ステップの Cortex Code プロンプトが記載されています。  
Snowsight の **Cortex Code** に貼り付けて実行することで、SQL を手書きせずに環境を構築できます。

### Cortex Code の開き方
1. Snowsight にログイン
2. 左サイドバーの **「Cortex Code」** をクリック

## 動作確認クエリ例

Agent を Snowflake Intelligence（または REST API）から呼び出して以下の質問を試してみてください：

- 「業種別のアクティブな契約件数と月額リース料の合計を教えて」
- 「トヨタ車のメンテナンス契約の内容を教えて」
- 「IFRS16のリース会計基準の最新動向は？」
- 「東京本社支店で延滞が多い業種はどこですか？対策を提案してください」
