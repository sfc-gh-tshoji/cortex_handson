# Cortex Handson — リース事業分析基盤

Snowflake Cortex の主要機能（Cortex Search・Dynamic Tables・Semantic View・Cortex Agent）を使って、リース事業分析基盤を構築するハンズオンです。

## アーキテクチャ

```
Bronze層（生テーブル）
  CUSTOMERS / VEHICLES / CONTRACTS / PAYMENTS
        ↓ Dynamic Tables
Gold層
  GOLD_CONTRACTS（契約・顧客・車両 結合済み）
  GOLD_PAYMENT_SUMMARY（契約別支払いサマリー）
        ↓
  LEASE_ANALYTICS（Semantic View）  +  SEARCH_CONTRACT_DOCS（Cortex Search）
        ↓
  LEASE_ANALYST（Cortex Agent）

別ライン: CONTRACTS_PDF_STAGE（PDF）→ PARSE_DOCUMENT → CONTRACT_DOCUMENTS → SEARCH_CONTRACT_DOCS
```

## 前提条件

- Snowflake アカウント（Enterprise 以上）
- SYSADMIN ロール
- ウェアハウス `HOL_AD_WH`（Adaptive Warehouse）
- データベース `HOL_DB` / スキーマ `HOL_DB.LEASING`

## セットアップ手順

`setup_hol.sql` を先に実行して環境を準備した後、`sql/` フォルダ内のスクリプトを番号順に実行します。

| ステップ | ファイル | 内容 |
|---|---|---|
| 0 | `setup_hol.sql` | DB・スキーマ・ステージ・Git連携・PDFコピー |
| 1 | `01_create_schema_tables.sql` | テーブル定義（5テーブル） |
| 2 | `02_insert_sample_data.sql` | サンプルデータ投入（顧客3万社・車両2万種・契約20万件・支払い約680万件） |
| 3 | `03_extract_pdf_text.sql` | PARSE_DOCUMENT で PDF テキスト抽出 → CONTRACT_DOCUMENTS 投入 |
| 4 | `04_create_cortex_search.sql` | Cortex Search Service（`SEARCH_CONTRACT_DOCS`）作成 |
| 5 | `05_create_dynamic_tables_gold.sql` | Gold層 Dynamic Tables（`GOLD_CONTRACTS` / `GOLD_PAYMENT_SUMMARY`）作成 |
| 6 | `06_create_semantic_view.sql` | Semantic View（`LEASE_ANALYTICS`）作成（Gold層参照） |
| 7 | `07_create_cortex_agent.sql` | Cortex Agent（`LEASE_ANALYST`）作成 |

> **ステップ3について**: `setup_hol.sql` の実行により `CONTRACTS_PDF_STAGE` にサンプル PDF がコピー・ディレクトリテーブルがリフレッシュ済みである必要があります。

## サンプル PDF

`CONTRACTS_PDF_STAGE` ステージに格納されるサンプル PDF の構成：

| フォルダ | 内容 | 件数 |
|---|---|---|
| `lease_contracts/` | リース契約書 | 26件 |
| `vehicle_delivery/` | 車両引渡確認書 | 21件 |
| `maintenance_contracts/` | メンテナンス契約書 | 21件 |
| `insurance_certificates/` | 保険証券 | 21件 |
| `amendment_agreements/` | リース変更合意書 | 21件 |

## 作成されるオブジェクト一覧

| オブジェクト | タイプ | 説明 |
|---|---|---|
| `HOL_DB.LEASING.CUSTOMERS` | テーブル | 法人顧客マスタ（30,000社） |
| `HOL_DB.LEASING.VEHICLES` | テーブル | 車両マスタ（20,000種） |
| `HOL_DB.LEASING.CONTRACTS` | テーブル | リース契約（200,000件） |
| `HOL_DB.LEASING.PAYMENTS` | テーブル | 月次支払い履歴（約680万件） |
| `HOL_DB.LEASING.CONTRACT_DOCUMENTS` | テーブル | PDF抽出テキスト |
| `HOL_DB.LEASING.SEARCH_CONTRACT_DOCS` | Cortex Search Service | 契約書全文検索 |
| `HOL_DB.LEASING.GOLD_CONTRACTS` | Dynamic Table | 契約×顧客×車両の非正規化テーブル（200,000件） |
| `HOL_DB.LEASING.GOLD_PAYMENT_SUMMARY` | Dynamic Table | 契約別支払いサマリー（200,000件） |
| `HOL_DB.LEASING.LEASE_ANALYTICS` | Semantic View | Gold層対象の自然言語分析ビュー |
| `HOL_DB.LEASING.LEASE_ANALYST` | Cortex Agent | 統合分析エージェント |

## Snowflake CoCo を使ったインタラクティブなハンズオン

`cortex_code_prompts.md` に各ステップの Cortex Code プロンプトが記載されています。
Snowsight の **CoCo** に貼り付けて実行することで、SQL を手書きせずに環境を構築できます。

### Snowflake CoCo の開き方
1. Snowsight にログイン
2. 左サイドバーの **「Cortex Code」** をクリック

## 動作確認クエリ例

Agent を CoWork（Snowflake Intelligence）から呼び出して以下の質問を試してみてください：

- 「業種別のアクティブな契約件数と月額リース料の合計を教えて」
- 「メーカー別の月額リース料を比較して」
- 「延滞率が高い顧客トップ10は？」
- 「トヨタ車のメンテナンス契約の内容を教えて」
- 「2025年の EV リース市場の動向は？」
- 「延滞率が高い顧客の契約書を確認して、リスク要因を分析してください」
