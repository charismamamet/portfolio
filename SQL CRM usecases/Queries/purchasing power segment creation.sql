-- Step 3: selects only users in q1 and q2 purchasing power groups
SELECT *
FROM (
  -- Step 2: adds a `qgroup` column by splitting users into 4 quartiles based on `avg_sku_price`
  SELECT 
    *,
    CONCAT('q', NTILE(4) OVER (ORDER BY avg_sku_price)) AS qgroup
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
    AND x.order_status IN ('menunggu pembayaran', 'selesai')
    AND xs.seller_name IS NULL
    AND xb.user_id is null
    GROUP BY x.user_id
  ) AS user_stats -- end of step 1
) AS stats_with_quartile -- end of step 2
WHERE qgroup IN ('q1', 'q2')
ORDER BY avg_sku_price DESC -- end of step 3
;