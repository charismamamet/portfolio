-- 🧮 Final query: selects only users in q1 and q2 purchasing power groups
SELECT *
FROM (
  -- 🧮 Middle subquery: adds a `qgroup` column by splitting users into 4 quartiles based on `avg_sku_price`
  SELECT 
    *,
    CONCAT('q', NTILE(4) OVER (ORDER BY avg_sku_price)) AS qgroup  -- assigns quartile labels: 'q1' (lowest) to 'q4' (highest)
  FROM (
    -- Step 1: computes per-user aggregated purchase behavior metrics
    SELECT 
      x.user_id,
      COUNT(x.order_id) AS total_order,
      SUM(x.sku_qty) AS total_sku_purchased,
      SUM(x.sku_sell_price) AS total_gmv,
      ROUND(SUM(x.sku_sell_price)/SUM(x.sku_qty), 0) AS avg_sku_price,
      ROUND(SUM(x.sku_sell_price)/COUNT(x.order_id), 0) AS aov
    FROM mock_renos_db.mock_purchase AS x

    -- Cek suspicious seller list
    LEFT JOIN mock_renos_db.suspicious_seller AS xs ON xs.seller_name = x.seller_name

    -- Cek suspicious buyer list
    LEFT JOIN mock_renos_db.suspicious_buyer AS xb ON xb.user_id = x.user_id

    -- 📦 Filters: only get buyers who has transaction 21 July 2025 and never again after that
    WHERE 1
    AND x.user_id IN (
		-- tabel consist of user_id of ppl who make purchase before 21 July 2025
        SELECT o.user_id
        FROM mock_renos_db.mock_purchase AS o
        WHERE order_date < '2025-07-21'
          AND order_status IN ('menunggu pembayaran', 'selesai')  -- only valid orders
      )
    AND x.user_id NOT IN (
		-- tabel consit of user_id of ppl who make purchase on or after 21 July 2025
        SELECT q.user_id
        FROM mock_renos_db.mock_purchase AS q
        WHERE order_date >= '2025-07-21'
          AND order_status IN ('menunggu pembayaran', 'selesai')  -- exclude those who purchased again
      )
    AND order_status IN ('menunggu pembayaran', 'selesai')  -- include only relevant statuses
    AND xs.seller_name IS NULL  -- exclude suspicious sellers
    AND x.user_id NOT IN (
        -- ❌ Exclude buyers who meet price & behavior filters but are still suspicious
        SELECT DISTINCT(p.user_id)
        FROM mock_renos_db.mock_purchase AS p
        LEFT JOIN mock_renos_db.suspicious_seller AS ss ON ss.seller_name = p.seller_name
        LEFT JOIN mock_renos_db.suspicious_buyer AS sb ON sb.user_id = p.user_id
        WHERE p.user_id IN (
            SELECT r.user_id
            FROM mock_renos_db.mock_purchase AS r
            WHERE order_date < '2025-07-21'
              AND order_status IN ('menunggu pembayaran', 'selesai')
              AND sku_sell_price / sku_qty <= 500000  -- suspicious low-price transactions
        )
        AND p.user_id NOT IN (
            SELECT user_id
            FROM mock_renos_db.mock_purchase
            WHERE order_date >= '2025-07-21'
              AND order_status IN ('menunggu pembayaran', 'selesai')
          )
        AND ss.seller_name IS NULL
        AND sb.user_id IS NULL
      )
    AND xb.user_id IS NULL  -- exclude known suspicious buyers
    GROUP BY x.user_id
  ) AS user_stats  -- 🧾 Result: a row per user with purchase metrics
) AS stats_with_quartile  -- 📊 Result: adds qgroup label for quartile
WHERE qgroup IN ('q1', 'q2')  -- 📌 Only keep users in lowest two quartiles (less spending power)
ORDER BY avg_sku_price DESC;  -- 📈 Sort by average SKU price (descending)