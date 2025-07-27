SELECT 
  a.cat_name AS pair_a,
  ta.total_a,

  b.cat_name AS pair_b,
  tb.total_b,  
  
  COUNT(*) AS pair_count,
  tod.total_order_count,

  ROUND(COUNT(*) * 1.0 / tod.total_order_count, 3) AS support,
  ROUND(COUNT(*) * 1.0 / ta.total_a, 3) AS confidence_A_to_B,
  ROUND(COUNT(*) * 1.0 / tb.total_b, 3) AS confidence_B_to_A,
  ROUND((COUNT(*) * 1.0 * tod.total_order_count) / (ta.total_a * tb.total_b), 3) AS lift

FROM mock_renos_db.mock_purchase AS a
JOIN mock_renos_db.mock_purchase AS b ON a.order_id = b.order_id AND a.cat_name <> b.cat_name

-- 🧮 total_a: how many times pair_a appears
inner JOIN (
  SELECT cat_name, COUNT(*) AS total_a
  FROM mock_renos_db.mock_purchase
  WHERE order_status IN ('menunggu pembayaran', 'selesai')
    AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
  GROUP BY cat_name
) AS ta ON a.cat_name = ta.cat_name

-- 🧮 total_b: how many times pair_b appears
inner JOIN (
  SELECT cat_name, COUNT(*) AS total_b
  FROM mock_renos_db.mock_purchase
  WHERE order_status IN ('menunggu pembayaran', 'selesai')
    AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
  GROUP BY cat_name
) AS tb ON b.cat_name = tb.cat_name

-- 🧮 total orders
CROSS JOIN (
  SELECT COUNT(DISTINCT order_id) AS total_order_count
  FROM mock_renos_db.mock_purchase
  WHERE order_status IN ('menunggu pembayaran', 'selesai')
    AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
) AS tod

WHERE a.order_status IN ('menunggu pembayaran', 'selesai')
  AND a.order_date BETWEEN '2025-07-01' AND '2025-07-23'

GROUP BY pair_a, pair_b
ORDER BY total_a desc, lift DESC;
