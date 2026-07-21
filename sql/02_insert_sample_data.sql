-- ================================================================================
-- リース契約分析基盤 — サンプルデータ投入
-- ================================================================================
-- データ件数:
--   CUSTOMERS:          30,000社
--   VEHICLES:           20,000種
--   CONTRACTS:         200,000件
--   PAYMENTS:        ~6,800,000件
-- ================================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE HOL_AD_WH;
USE SCHEMA HOL_DB.LEASING;

-- ============================================================
-- 1. 法人顧客マスタ（30,000社）
-- ============================================================
INSERT INTO HOL_DB.LEASING.CUSTOMERS
(CUSTOMER_ID, COMPANY_NAME, INDUSTRY, PREFECTURE, CITY, ESTABLISHED_YEAR, EMPLOYEE_COUNT, ANNUAL_REVENUE_CLASS, CONTACT_NAME, CONTACT_EMAIL)
SELECT
    'C' || LPAD(SEQ4()::VARCHAR, 6, '0') AS CUSTOMER_ID,
    -- 業種に応じた社名テンプレート
    CASE MOD(SEQ4(), 20)
        WHEN 0  THEN '東日本運送' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 1  THEN '大成建設工業' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 2  THEN '精密製作所' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 3  THEN '丸和商事' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 4  THEN 'フレッシュマート' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 5  THEN '三和不動産' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 6  THEN 'テクノシステムズ' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 7  THEN '仁愛メディカル' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 8  THEN 'グルメダイニング' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 9  THEN '豊穣ファーム' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 10 THEN '日本ロジスティクス' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 11 THEN 'アシストサービス' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 12 THEN '未来学園' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 13 THEN '信和ファイナンス' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 14 THEN '東都エナジー' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 15 THEN '市民サービス公社' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 16 THEN 'ジャパンレンタル' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 17 THEN 'クリーンプロ' || LPAD(SEQ4()::VARCHAR, 5, '0')
        WHEN 18 THEN 'ケアハート' || LPAD(SEQ4()::VARCHAR, 5, '0')
        ELSE '大和倉庫' || LPAD(SEQ4()::VARCHAR, 5, '0')
    END AS COMPANY_NAME,
    CASE MOD(SEQ4(), 20)
        WHEN 0  THEN '運送業'
        WHEN 1  THEN '建設業'
        WHEN 2  THEN '製造業'
        WHEN 3  THEN '卸売業'
        WHEN 4  THEN '小売業'
        WHEN 5  THEN '不動産業'
        WHEN 6  THEN 'IT・通信'
        WHEN 7  THEN '医療・福祉'
        WHEN 8  THEN '飲食業'
        WHEN 9  THEN '農林水産業'
        WHEN 10 THEN '物流業'
        WHEN 11 THEN 'サービス業'
        WHEN 12 THEN '教育'
        WHEN 13 THEN '金融・保険'
        WHEN 14 THEN '電気・ガス'
        WHEN 15 THEN '公務'
        WHEN 16 THEN 'レンタル業'
        WHEN 17 THEN '清掃業'
        WHEN 18 THEN '介護'
        ELSE '倉庫業'
    END AS INDUSTRY,
    CASE MOD(SEQ4(), 47)
        WHEN 0  THEN '北海道' WHEN 1  THEN '青森県' WHEN 2  THEN '岩手県'
        WHEN 3  THEN '宮城県' WHEN 4  THEN '秋田県' WHEN 5  THEN '山形県'
        WHEN 6  THEN '福島県' WHEN 7  THEN '茨城県' WHEN 8  THEN '栃木県'
        WHEN 9  THEN '群馬県' WHEN 10 THEN '埼玉県' WHEN 11 THEN '千葉県'
        WHEN 12 THEN '東京都' WHEN 13 THEN '神奈川県' WHEN 14 THEN '新潟県'
        WHEN 15 THEN '富山県' WHEN 16 THEN '石川県' WHEN 17 THEN '福井県'
        WHEN 18 THEN '山梨県' WHEN 19 THEN '長野県' WHEN 20 THEN '岐阜県'
        WHEN 21 THEN '静岡県' WHEN 22 THEN '愛知県' WHEN 23 THEN '三重県'
        WHEN 24 THEN '滋賀県' WHEN 25 THEN '京都府' WHEN 26 THEN '大阪府'
        WHEN 27 THEN '兵庫県' WHEN 28 THEN '奈良県' WHEN 29 THEN '和歌山県'
        WHEN 30 THEN '鳥取県' WHEN 31 THEN '島根県' WHEN 32 THEN '岡山県'
        WHEN 33 THEN '広島県' WHEN 34 THEN '山口県' WHEN 35 THEN '徳島県'
        WHEN 36 THEN '香川県' WHEN 37 THEN '愛媛県' WHEN 38 THEN '高知県'
        WHEN 39 THEN '福岡県' WHEN 40 THEN '佐賀県' WHEN 41 THEN '長崎県'
        WHEN 42 THEN '熊本県' WHEN 43 THEN '大分県' WHEN 44 THEN '宮崎県'
        WHEN 45 THEN '鹿児島県' ELSE '沖縄県'
    END AS PREFECTURE,
    CASE MOD(SEQ4(), 10)
        WHEN 0 THEN '中央区' WHEN 1 THEN '港区' WHEN 2 THEN '新宿区'
        WHEN 3 THEN '千代田区' WHEN 4 THEN '品川区' WHEN 5 THEN '渋谷区'
        WHEN 6 THEN '豊島区' WHEN 7 THEN '北区' WHEN 8 THEN '板橋区'
        ELSE '江東区'
    END AS CITY,
    UNIFORM(1950, 2020, RANDOM()) AS ESTABLISHED_YEAR,
    UNIFORM(10, 5000, RANDOM()) AS EMPLOYEE_COUNT,
    CASE MOD(UNIFORM(1, 100, RANDOM()), 5)
        WHEN 0 THEN '〜1億'
        WHEN 1 THEN '1〜10億'
        WHEN 2 THEN '10〜50億'
        WHEN 3 THEN '50〜100億'
        ELSE '100億〜'
    END AS ANNUAL_REVENUE_CLASS,
    CASE MOD(SEQ4(), 10)
        WHEN 0 THEN '佐藤 太郎' WHEN 1 THEN '鈴木 花子' WHEN 2 THEN '高橋 一郎'
        WHEN 3 THEN '田中 美咲' WHEN 4 THEN '伊藤 健太' WHEN 5 THEN '渡辺 陽子'
        WHEN 6 THEN '山本 翔太' WHEN 7 THEN '中村 愛' WHEN 8 THEN '小林 大輔'
        ELSE '加藤 真由美'
    END AS CONTACT_NAME,
    LOWER('user' || SEQ4()::VARCHAR || '@example.co.jp') AS CONTACT_EMAIL
FROM TABLE(GENERATOR(ROWCOUNT => 30000));

-- ============================================================
-- 2. 車両マスタ（20,000種）
-- ============================================================
INSERT INTO HOL_DB.LEASING.VEHICLES
(VEHICLE_ID, MANUFACTURER, MODEL_NAME, VEHICLE_TYPE, ENGINE_DISPLACEMENT, VEHICLE_PRICE, FUEL_TYPE, YEAR_MODEL)
SELECT
    'V' || LPAD(SEQ4()::VARCHAR, 6, '0') AS VEHICLE_ID,
    CASE MOD(SEQ4(), 10)
        WHEN 0 THEN 'トヨタ'
        WHEN 1 THEN '日野'
        WHEN 2 THEN 'いすゞ'
        WHEN 3 THEN '三菱ふそう'
        WHEN 4 THEN '日産'
        WHEN 5 THEN 'マツダ'
        WHEN 6 THEN 'ホンダ'
        WHEN 7 THEN 'スバル'
        WHEN 8 THEN 'スズキ'
        ELSE 'ダイハツ'
    END AS MANUFACTURER,
    -- メーカー略称 + 車種 + 連番
    CASE MOD(SEQ4(), 10)
        WHEN 0 THEN 'TY-' WHEN 1 THEN 'HN-' WHEN 2 THEN 'IS-'
        WHEN 3 THEN 'MF-' WHEN 4 THEN 'NS-' WHEN 5 THEN 'MZ-'
        WHEN 6 THEN 'HD-' WHEN 7 THEN 'SB-' WHEN 8 THEN 'SZ-'
        ELSE 'DH-'
    END ||
    CASE MOD(SEQ4(), 8)
        WHEN 0 THEN 'LT' WHEN 1 THEN 'MT' WHEN 2 THEN 'HT'
        WHEN 3 THEN 'VN' WHEN 4 THEN 'SD' WHEN 5 THEN 'FL'
        WHEN 6 THEN 'BS' ELSE 'SP'
    END || '-' || LPAD(SEQ4()::VARCHAR, 5, '0') AS MODEL_NAME,
    CASE MOD(SEQ4(), 8)
        WHEN 0 THEN '小型トラック'
        WHEN 1 THEN '中型トラック'
        WHEN 2 THEN '大型トラック'
        WHEN 3 THEN 'バン・ライトバン'
        WHEN 4 THEN '乗用車'
        WHEN 5 THEN 'フォークリフト'
        WHEN 6 THEN 'バス・マイクロバス'
        ELSE '特殊車両'
    END AS VEHICLE_TYPE,
    -- 排気量は車種区分に応じた範囲
    CASE MOD(SEQ4(), 8)
        WHEN 0 THEN UNIFORM(2000, 3000, RANDOM())
        WHEN 1 THEN UNIFORM(4000, 6000, RANDOM())
        WHEN 2 THEN UNIFORM(8000, 13000, RANDOM())
        WHEN 3 THEN UNIFORM(1500, 2500, RANDOM())
        WHEN 4 THEN UNIFORM(1200, 3500, RANDOM())
        WHEN 5 THEN UNIFORM(1500, 3000, RANDOM())
        WHEN 6 THEN UNIFORM(4000, 9000, RANDOM())
        ELSE UNIFORM(3000, 8000, RANDOM())
    END AS ENGINE_DISPLACEMENT,
    -- 車両価格は車種区分に応じた範囲
    CASE MOD(SEQ4(), 8)
        WHEN 0 THEN UNIFORM(2000000, 5000000, RANDOM())
        WHEN 1 THEN UNIFORM(5000000, 12000000, RANDOM())
        WHEN 2 THEN UNIFORM(10000000, 25000000, RANDOM())
        WHEN 3 THEN UNIFORM(1500000, 4000000, RANDOM())
        WHEN 4 THEN UNIFORM(2000000, 6000000, RANDOM())
        WHEN 5 THEN UNIFORM(3000000, 8000000, RANDOM())
        WHEN 6 THEN UNIFORM(8000000, 20000000, RANDOM())
        ELSE UNIFORM(5000000, 15000000, RANDOM())
    END AS VEHICLE_PRICE,
    CASE MOD(SEQ4(), 4)
        WHEN 0 THEN 'ガソリン'
        WHEN 1 THEN 'ディーゼル'
        WHEN 2 THEN 'ハイブリッド'
        ELSE 'EV'
    END AS FUEL_TYPE,
    UNIFORM(2018, 2025, RANDOM()) AS YEAR_MODEL
FROM TABLE(GENERATOR(ROWCOUNT => 20000));

-- ============================================================
-- 3. リース契約（200,000件）
-- ============================================================
INSERT INTO HOL_DB.LEASING.CONTRACTS
(CONTRACT_ID, CUSTOMER_ID, VEHICLE_ID, CONTRACT_TYPE, CONTRACT_START_DATE, CONTRACT_END_DATE,
 LEASE_TERM_MONTHS, MONTHLY_LEASE_AMOUNT, TOTAL_LEASE_AMOUNT, RESIDUAL_VALUE, STATUS, BRANCH_OFFICE)
WITH base AS (
    SELECT
        SEQ4() AS seq_num,
        -- 契約開始日: 2020-01-01〜2026-03-01（約2250日）
        DATEADD('day', UNIFORM(0, 2249, RANDOM()), '2020-01-01'::DATE) AS start_dt,
        -- 契約期間（月）: 36, 48, 60, 72, 84 からランダム
        CASE MOD(UNIFORM(1, 100, RANDOM()), 5)
            WHEN 0 THEN 36
            WHEN 1 THEN 48
            WHEN 2 THEN 60
            WHEN 3 THEN 72
            ELSE 84
        END AS term_months,
        -- 月額リース料: 30,000〜500,000円
        UNIFORM(30000, 500000, RANDOM()) AS monthly_amt,
        -- 残存価額率: 5〜20%
        UNIFORM(5, 20, RANDOM()) / 100.0 AS residual_rate
    FROM TABLE(GENERATOR(ROWCOUNT => 200000))
)
SELECT
    'LC' || LPAD(seq_num::VARCHAR, 8, '0') AS CONTRACT_ID,
    'C' || LPAD(UNIFORM(0, 29999, RANDOM())::VARCHAR, 6, '0') AS CUSTOMER_ID,
    'V' || LPAD(UNIFORM(0, 19999, RANDOM())::VARCHAR, 6, '0') AS VEHICLE_ID,
    CASE MOD(seq_num, 10)
        WHEN 0 THEN 'オペレーティングリース'
        WHEN 1 THEN 'オペレーティングリース'
        WHEN 2 THEN 'オペレーティングリース'
        WHEN 3 THEN 'メンテナンスリース'
        ELSE 'ファイナンスリース'
    END AS CONTRACT_TYPE,
    start_dt AS CONTRACT_START_DATE,
    DATEADD('month', term_months, start_dt) AS CONTRACT_END_DATE,
    term_months AS LEASE_TERM_MONTHS,
    monthly_amt AS MONTHLY_LEASE_AMOUNT,
    monthly_amt * term_months AS TOTAL_LEASE_AMOUNT,
    ROUND(monthly_amt * term_months * residual_rate) AS RESIDUAL_VALUE,
    CASE
        WHEN DATEADD('month', term_months, start_dt) < CURRENT_DATE() THEN 'completed'
        WHEN start_dt > CURRENT_DATE() THEN 'pending'
        WHEN MOD(seq_num, 20) = 0 THEN 'terminated'
        ELSE 'active'
    END AS STATUS,
    CASE MOD(seq_num, 8)
        WHEN 0 THEN '東京本社'
        WHEN 1 THEN '大阪支店'
        WHEN 2 THEN '名古屋支店'
        WHEN 3 THEN '福岡支店'
        WHEN 4 THEN '札幌支店'
        WHEN 5 THEN '仙台支店'
        WHEN 6 THEN '広島支店'
        ELSE '高松支店'
    END AS BRANCH_OFFICE
FROM base;

-- ============================================================
-- 4. 支払い履歴（〜6,800,000件）
-- 月次カレンダーとJOINして各契約の支払い期間分のレコードを生成
-- ============================================================
INSERT INTO HOL_DB.LEASING.PAYMENTS
(PAYMENT_ID, CONTRACT_ID, PAYMENT_DATE, PAYMENT_AMOUNT, PAYMENT_STATUS, PAYMENT_METHOD)
WITH months AS (
    -- 2020-01 〜 2026-03 の月次カレンダー（75ヶ月分）
    SELECT DATEADD('month', SEQ4(), '2020-01-01'::DATE) AS month_date
    FROM TABLE(GENERATOR(ROWCOUNT => 75))
)
SELECT
    c.CONTRACT_ID || '-' || LPAD(ROW_NUMBER() OVER (PARTITION BY c.CONTRACT_ID ORDER BY m.month_date)::VARCHAR, 3, '0') AS PAYMENT_ID,
    c.CONTRACT_ID,
    m.month_date AS PAYMENT_DATE,
    c.MONTHLY_LEASE_AMOUNT AS PAYMENT_AMOUNT,
    CASE
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'paid'
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 'overdue'
        ELSE 'pending'
    END AS PAYMENT_STATUS,
    CASE MOD(UNIFORM(1, 100, RANDOM()), 20)
        WHEN 0 THEN '銀行振込'
        WHEN 1 THEN '銀行振込'
        WHEN 2 THEN '銀行振込'
        WHEN 3 THEN '銀行振込'
        WHEN 4 THEN '銀行振込'
        WHEN 5 THEN 'クレジット'
        ELSE '口座振替'
    END AS PAYMENT_METHOD
FROM HOL_DB.LEASING.CONTRACTS c
JOIN months m
    ON m.month_date >= c.CONTRACT_START_DATE
    AND m.month_date <= LEAST(CURRENT_DATE(), c.CONTRACT_END_DATE)
WHERE c.STATUS IN ('active', 'completed', 'terminated');
